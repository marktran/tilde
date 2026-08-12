import assert from "node:assert/strict";
import test from "node:test";

import extensionFactory from "../index.ts";
import {
  applyRemoteHistoryPayloadPatch,
  hasUnresolvedBaseUrl,
  isCloudflareOpenAIResponsesModel,
  modelKey,
  resolveModelEnvironment,
  supportsRemoteCompactionModel,
  thinkingLevelToResponsesReasoning,
} from "../openai.ts";
import {
  buildRemoteCompactionDetails,
  buildRemoteCompactionHeaders,
  buildRemoteCompactionRequestBody,
  buildRemoteCompactionV2History,
  callRemoteCompactionEndpoint,
  extractRemoteCompactionDetails,
  parseRemoteCompactionV2Events,
  reconstructRemoteCompactionStateFromBranch,
  remoteCompactionV2EndpointUrl,
} from "../remote-compaction.ts";

const CF_BASE =
  "https://gateway.ai.cloudflare.com/v1/{CLOUDFLARE_ACCOUNT_ID}/{CLOUDFLARE_GATEWAY_ID}";

function cloudflareModel({
  id = "gpt-5.6-sol",
  api = "openai-responses",
  route = "openai",
} = {}) {
  return {
    id,
    name: id,
    api,
    provider: "cloudflare-ai-gateway",
    baseUrl: `${CF_BASE}/${route}`,
    reasoning: true,
    input: ["text", "image"],
    contextWindow: 1_050_000,
    maxTokens: 128_000,
    cost: { input: 5, output: 30, cacheRead: 0.5, cacheWrite: 0 },
  };
}

function resolvedCloudflareModel(options) {
  return resolveModelEnvironment(cloudflareModel(options), {
    CLOUDFLARE_ACCOUNT_ID: "account-id",
    CLOUDFLARE_GATEWAY_ID: "gateway-id",
  });
}

function message(role, text, overrides = {}) {
  return {
    role,
    content: [{ type: "text", text }],
    timestamp: Date.now(),
    ...overrides,
  };
}

test("extension entrypoint loads", () => {
  assert.equal(typeof extensionFactory, "function");
});

test("targets only Cloudflare's dedicated OpenAI Responses route", () => {
  for (const id of ["gpt-5.6-sol", "gpt-5.6-terra", "gpt-5.6-luna"]) {
    const model = cloudflareModel({ id });
    assert.equal(isCloudflareOpenAIResponsesModel(model), true, `${id} should be supported`);
    assert.equal(supportsRemoteCompactionModel(model), true, `${id} should support remote compaction`);
  }

  const rejected = [
    cloudflareModel({ id: "grok-4.6", route: "grok" }),
    cloudflareModel({
      id: "accounts/fireworks/models/glm-5p2",
      api: "openai-completions",
      route: "custom-fireworks-ai/v1",
    }),
    cloudflareModel({
      id: "accounts/fireworks/models/hypothetical-responses-model",
      route: "custom-fireworks-ai",
    }),
    cloudflareModel({
      id: "accounts/fireworks/models/kimi-k3",
      api: "openai-completions",
      route: "custom-fireworks-ai/v1",
    }),
    {
      ...cloudflareModel(),
      provider: "some-openai-compatible-provider",
      baseUrl: "https://example.com/v1",
    },
  ];

  for (const model of rejected) {
    assert.equal(isCloudflareOpenAIResponsesModel(model), false, `${model.id} should be rejected`);
    assert.equal(supportsRemoteCompactionModel(model), false, `${model.id} should not use remote compaction`);
  }
});

test("resolves Cloudflare placeholders and builds the correct Responses endpoint", () => {
  const unresolved = cloudflareModel();
  assert.equal(hasUnresolvedBaseUrl(unresolved), true);

  const resolved = resolvedCloudflareModel();
  assert.equal(hasUnresolvedBaseUrl(resolved), false);
  assert.equal(
    resolved.baseUrl,
    "https://gateway.ai.cloudflare.com/v1/account-id/gateway-id/openai",
  );
  assert.equal(
    remoteCompactionV2EndpointUrl(resolved),
    "https://gateway.ai.cloudflare.com/v1/account-id/gateway-id/openai/responses",
  );
});

test("uses header-only Cloudflare auth and merges the compaction feature", () => {
  const headers = buildRemoteCompactionHeaders({
    model: resolvedCloudflareModel(),
    sessionId: "session-123",
    headers: {
      "cf-aig-authorization": "Bearer redacted",
      "X-Codex-Beta-Features": "existing_feature,remote_compaction_v2",
    },
  });

  assert.equal(headers["cf-aig-authorization"], "Bearer redacted");
  assert.equal(headers.authorization, undefined);
  assert.equal(headers.accept, "text/event-stream");
  assert.equal(headers["content-type"], "application/json");
  assert.deepEqual(
    new Set(headers["x-codex-beta-features"].split(",")),
    new Set(["existing_feature", "remote_compaction_v2"]),
  );
});

test("maps every selectable GPT-5.6 thinking level", () => {
  for (const level of ["low", "medium", "high", "xhigh", "max"]) {
    assert.deepEqual(thinkingLevelToResponsesReasoning(level), {
      effort: level,
      summary: "auto",
    });
  }
  assert.equal(thinkingLevelToResponsesReasoning("off"), undefined);
});

test("remote-history replacement preserves the current request shape", () => {
  const replacement = [{ type: "compaction", encrypted_content: "opaque" }];
  const payload = applyRemoteHistoryPayloadPatch({
    payload: {
      model: "gpt-5.6-sol",
      input: [{ type: "message", role: "user", content: [] }],
      messages: [{ role: "user", content: "legacy" }],
      previous_response_id: "resp_old",
      tools: [{ type: "function", name: "read" }],
      reasoning: { effort: "max", summary: "auto" },
      text: { verbosity: "medium" },
      stream: true,
      store: false,
    },
    explicitHistory: replacement,
  });

  assert.deepEqual(payload.input, replacement);
  assert.equal("messages" in payload, false);
  assert.equal("previous_response_id" in payload, false);
  assert.deepEqual(payload.reasoning, { effort: "max", summary: "auto" });
  assert.deepEqual(payload.text, { verbosity: "medium" });
  assert.deepEqual(payload.tools, [{ type: "function", name: "read" }]);
  assert.equal(payload.stream, true);
  assert.equal(payload.store, false);
});

test("builds and validates Responses compaction v2 payloads", () => {
  const model = resolvedCloudflareModel();
  const body = buildRemoteCompactionRequestBody({
    model,
    input: [{ type: "message", role: "user", content: [{ type: "input_text", text: "state" }] }],
    instructions: "system",
    tools: [{ type: "function", name: "read" }],
    parallelToolCalls: true,
    reasoning: { effort: "max", summary: "auto" },
    text: { verbosity: "medium" },
  });

  assert.equal(body.model, "gpt-5.6-sol");
  assert.equal(body.stream, true);
  assert.equal(body.store, false);
  assert.deepEqual(body.input.at(-1), { type: "compaction_trigger" });
  assert.deepEqual(body.reasoning, { effort: "max", summary: "auto" });
  assert.deepEqual(body.text, { verbosity: "medium" });

  const parsed = parseRemoteCompactionV2Events([
    {
      type: "response.output_item.done",
      item: { type: "compaction", encrypted_content: "opaque" },
    },
    {
      type: "response.completed",
      response: { usage: { input_tokens: 10, output_tokens: 2, total_tokens: 12 } },
    },
  ]);
  assert.equal(parsed.compactionItem.type, "compaction");

  assert.throws(() => parseRemoteCompactionV2Events([]), /before response\.completed/);
  assert.throws(
    () => parseRemoteCompactionV2Events([{ type: "response.completed", response: {} }]),
    /exactly one compaction item, got 0/,
  );
  assert.throws(
    () =>
      parseRemoteCompactionV2Events([
        { type: "response.output_item.done", item: { type: "compaction", encrypted_content: "a" } },
        { type: "response.output_item.done", item: { type: "compaction", encrypted_content: "b" } },
        { type: "response.completed", response: {} },
      ]),
    /exactly one compaction item, got 2/,
  );
  assert.throws(
    () =>
      parseRemoteCompactionV2Events([
        { type: "response.failed", response: { error: { message: "upstream failure" } } },
      ]),
    /upstream failure/,
  );
});

test("retains user context with the opaque artifact", () => {
  const history = buildRemoteCompactionV2History(
    [
      { type: "message", role: "user", content: [{ type: "input_text", text: "retain me" }] },
      { type: "message", role: "assistant", content: [{ type: "output_text", text: "compact me" }] },
    ],
    { type: "compaction", encrypted_content: "opaque" },
  );
  assert.deepEqual(history.map((item) => item.type), ["message", "compaction"]);
  assert.equal(history[0].role, "user");
});

test("reconstructs only turns completed by the compaction model", () => {
  const sol = resolvedCloudflareModel({ id: "gpt-5.6-sol" });
  const terra = resolvedCloudflareModel({ id: "gpt-5.6-terra" });
  const details = buildRemoteCompactionDetails(
    sol,
    [{ type: "compaction", encrypted_content: "opaque" }],
  );

  const reconstructed = reconstructRemoteCompactionStateFromBranch({
    branchEntries: [
      { type: "compaction", id: "cmp", details: { remoteCompaction: details } },
      { type: "message", id: "sol-user-1", message: message("user", "KEEP_SOL_ONE") },
      {
        type: "message",
        id: "sol-assistant-1",
        message: message("assistant", "KEEP_SOL_REPLY_ONE", {
          provider: sol.provider,
          api: sol.api,
          model: sol.id,
        }),
      },
      { type: "message", id: "terra-user", message: message("user", "DROP_TERRA") },
      {
        type: "message",
        id: "terra-assistant",
        message: message("assistant", "DROP_TERRA_REPLY", {
          provider: terra.provider,
          api: terra.api,
          model: terra.id,
        }),
      },
      { type: "message", id: "sol-user-2", message: message("user", "KEEP_SOL_TWO") },
      {
        type: "message",
        id: "sol-assistant-2",
        message: message("assistant", "KEEP_SOL_REPLY_TWO", {
          provider: sol.provider,
          api: sol.api,
          model: sol.id,
        }),
      },
    ],
  });

  assert.ok(reconstructed);
  assert.equal(reconstructed.modelKey, modelKey(sol));
  assert.notEqual(reconstructed.modelKey, modelKey(terra));
  const serialized = JSON.stringify(reconstructed.explicitHistory);
  assert.match(serialized, /KEEP_SOL_ONE/);
  assert.match(serialized, /KEEP_SOL_REPLY_ONE/);
  assert.match(serialized, /KEEP_SOL_TWO/);
  assert.match(serialized, /KEEP_SOL_REPLY_TWO/);
  assert.doesNotMatch(serialized, /DROP_TERRA/);
});

test("round-trips persisted compaction usage", () => {
  const details = extractRemoteCompactionDetails({
    remoteCompaction: buildRemoteCompactionDetails(
      resolvedCloudflareModel(),
      [{ type: "compaction", encrypted_content: "opaque" }],
      {
        input: 10,
        output: 20,
        cacheRead: 30,
        cacheWrite: 40,
        totalTokens: 100,
        cost: { input: 1, output: 2, cacheRead: 3, cacheWrite: 4, total: 10 },
      },
    ),
  });
  assert.ok(details);
  assert.equal(details.usage?.cacheWrite, 40);
  assert.equal(details.usage?.cost.total, 10);
});

test("performs the Cloudflare fetch contract without touching the network", async () => {
  const originalFetch = globalThis.fetch;
  let capturedUrl;
  let capturedInit;
  globalThis.fetch = async (url, init) => {
    capturedUrl = String(url);
    capturedInit = init;
    const events = [
      {
        type: "response.output_item.done",
        item: { type: "compaction", encrypted_content: "opaque" },
      },
      {
        type: "response.completed",
        response: {
          usage: {
            input_tokens: 10,
            output_tokens: 2,
            total_tokens: 12,
            input_tokens_details: { cached_tokens: 0, cache_write_tokens: 0 },
          },
        },
      },
    ];
    const sse = `${events.map((event) => `data: ${JSON.stringify(event)}\n\n`).join("")}data: [DONE]\n\n`;
    return new Response(sse, {
      status: 200,
      headers: { "content-type": "text/event-stream" },
    });
  };

  try {
    const result = await callRemoteCompactionEndpoint({
      model: resolvedCloudflareModel(),
      headers: { "cf-aig-authorization": "Bearer redacted" },
      sessionId: "session-123",
      input: [
        { type: "message", role: "user", content: [{ type: "input_text", text: "retain me" }] },
      ],
      instructions: "system",
      tools: [],
      parallelToolCalls: true,
      reasoning: { effort: "max", summary: "auto" },
    });

    assert.equal(
      capturedUrl,
      "https://gateway.ai.cloudflare.com/v1/account-id/gateway-id/openai/responses",
    );
    const headers = new Headers(capturedInit.headers);
    assert.equal(headers.get("cf-aig-authorization"), "Bearer redacted");
    assert.equal(headers.has("authorization"), false);
    assert.equal(headers.get("x-codex-beta-features"), "remote_compaction_v2");
    const body = JSON.parse(capturedInit.body);
    assert.deepEqual(body.input.at(-1), { type: "compaction_trigger" });
    assert.deepEqual(body.reasoning, { effort: "max", summary: "auto" });
    assert.deepEqual(result.output.map((item) => item.type), ["message", "compaction"]);
    assert.equal(result.usage?.totalTokens, 12);
  } finally {
    globalThis.fetch = originalFetch;
  }
});
