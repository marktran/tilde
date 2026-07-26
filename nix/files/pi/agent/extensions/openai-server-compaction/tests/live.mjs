#!/usr/bin/env node
/** Paid, opt-in live checks against the configured Cloudflare AI Gateway. */
import assert from "node:assert/strict";
import { execSync, spawn } from "node:child_process";
import { randomBytes, randomUUID } from "node:crypto";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { homedir, tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { StringDecoder } from "node:string_decoder";
import { setTimeout as delay } from "node:timers/promises";
import { fileURLToPath } from "node:url";

const extensionRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const extensionPath = join(extensionRoot, "index.ts");
const modelRef = process.env.PI_OPENAI_SERVER_COMPACTION_TEST_MODEL ??
  "cloudflare-ai-gateway/gpt-5.6-sol";
const slash = modelRef.indexOf("/");
const provider = slash > 0 ? modelRef.slice(0, slash) : "";
const modelId = slash > 0 ? modelRef.slice(slash + 1) : "";
const THINKING_LEVELS = ["low", "medium", "high", "xhigh", "max"];
const REQUEST_TIMEOUT_MS = 240_000;

assert.equal(
  process.env.PI_OPENAI_SERVER_COMPACTION_LIVE,
  "1",
  "Set PI_OPENAI_SERVER_COMPACTION_LIVE=1 to acknowledge that this test makes paid API calls",
);
assert.equal(provider, "cloudflare-ai-gateway", "The live test requires a Cloudflare AI Gateway model");
assert.match(modelId, /^gpt-/, "The live test requires an OpenAI GPT model routed through Cloudflare");

function isRecord(value) {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function resolveTemplate(value, scopedEnv) {
  let out = "";
  let index = 0;
  while (index < value.length) {
    const dollar = value.indexOf("$", index);
    if (dollar < 0) return out + value.slice(index);
    out += value.slice(index, dollar);
    const next = value[dollar + 1];
    if (next === "$" || next === "!") {
      out += next;
      index = dollar + 2;
      continue;
    }
    if (next === "{") {
      const end = value.indexOf("}", dollar + 2);
      if (end < 0) {
        out += "$";
        index = dollar + 1;
        continue;
      }
      const name = value.slice(dollar + 2, end);
      const resolved = scopedEnv[name] ?? process.env[name];
      if (resolved === undefined) return undefined;
      out += resolved;
      index = end + 1;
      continue;
    }
    const match = value.slice(dollar + 1).match(/^[A-Za-z_][A-Za-z0-9_]*/);
    if (!match) {
      out += "$";
      index = dollar + 1;
      continue;
    }
    const resolved = scopedEnv[match[0]] ?? process.env[match[0]];
    if (resolved === undefined) return undefined;
    out += resolved;
    index = dollar + 1 + match[0].length;
  }
  return out;
}

function resolveCredentialKey(value, scopedEnv) {
  assert.equal(typeof value, "string", "Cloudflare credential key is missing");
  if (value.startsWith("!")) {
    const output = execSync(value.slice(1), {
      encoding: "utf8",
      timeout: 15_000,
      stdio: ["ignore", "pipe", "pipe"],
      shell: process.env.SHELL || "/bin/sh",
    }).trim();
    assert.ok(output, "Cloudflare credential command returned no key");
    return output;
  }
  const resolved = resolveTemplate(value, scopedEnv);
  assert.ok(resolved, "Cloudflare credential key could not be resolved");
  return resolved;
}

function parseSse(text) {
  return text
    .replace(/\r\n/g, "\n")
    .split("\n\n")
    .flatMap((block) => {
      const data = block
        .split("\n")
        .filter((line) => line.startsWith("data:"))
        .map((line) => line.slice(5).trimStart())
        .join("\n")
        .trim();
      if (!data || data === "[DONE]") return [];
      return [JSON.parse(data)];
    });
}

async function responsesRequest(endpoint, headers, body) {
  const response = await fetch(endpoint, {
    method: "POST",
    headers,
    body: JSON.stringify(body),
    signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
  });
  const text = await response.text();
  assert.equal(response.ok, true, `Responses request failed (${response.status}): ${text.slice(0, 2000)}`);
  const events = parseSse(text);
  const failure = events.find((event) => event?.type === "error" || event?.type === "response.failed");
  assert.equal(failure, undefined, `Responses stream failed: ${JSON.stringify(failure)}`);
  return events;
}

async function resolveCloudflareConnection() {
  const auth = JSON.parse(await readFile(join(homedir(), ".pi", "agent", "auth.json"), "utf8"));
  const credential = auth["cloudflare-ai-gateway"];
  assert.ok(isRecord(credential) && credential.type === "api_key", "Cloudflare AI Gateway credential not found");
  const scopedEnv = isRecord(credential.env) ? credential.env : {};
  const token = resolveCredentialKey(credential.key, scopedEnv);
  const account = scopedEnv.CLOUDFLARE_ACCOUNT_ID ?? process.env.CLOUDFLARE_ACCOUNT_ID;
  const gateway = scopedEnv.CLOUDFLARE_GATEWAY_ID ?? process.env.CLOUDFLARE_GATEWAY_ID;
  assert.equal(typeof account, "string", "CLOUDFLARE_ACCOUNT_ID is missing");
  assert.equal(typeof gateway, "string", "CLOUDFLARE_GATEWAY_ID is missing");
  return {
    endpoint: `https://gateway.ai.cloudflare.com/v1/${encodeURIComponent(account)}/${encodeURIComponent(gateway)}/openai/responses`,
    token,
  };
}

async function runProtocolMatrix() {
  console.log("== Cloudflare Responses compaction protocol matrix ==");
  const { endpoint, token } = await resolveCloudflareConnection();
  const sessionId = randomUUID();
  const headers = {
    "cf-aig-authorization": `Bearer ${token}`,
    "content-type": "application/json",
    accept: "text/event-stream",
    "x-codex-beta-features": "remote_compaction_v2",
    "x-codex-installation-id": randomUUID(),
    "x-codex-window-id": `${sessionId}:0`,
    session_id: sessionId,
  };
  const marker = `CF-COMPACT-${randomBytes(8).toString("hex").toUpperCase()}`;
  let replayArtifact;

  for (const effort of THINKING_LEVELS) {
    const prompt = effort === "low"
      ? `Preserve this exact marker for later recall: ${marker}`
      : `Compaction protocol compatibility probe for reasoning effort ${effort}.`;
    const events = await responsesRequest(endpoint, headers, {
      model: modelId,
      input: [
        { type: "message", role: "user", content: [{ type: "input_text", text: prompt }] },
        { type: "compaction_trigger" },
      ],
      instructions: "Preserve exact user state while compacting this protocol test.",
      tools: [],
      parallel_tool_calls: true,
      tool_choice: "auto",
      stream: true,
      store: false,
      include: ["reasoning.encrypted_content"],
      reasoning: { effort, summary: "auto" },
      prompt_cache_key: `${sessionId}-${effort}`,
    });
    const items = events
      .filter((event) => event?.type === "response.output_item.done" && event?.item?.type === "compaction")
      .map((event) => event.item);
    assert.equal(items.length, 1, `${effort}: expected exactly one compaction item`);
    assert.ok(items[0].encrypted_content, `${effort}: encrypted content is empty`);
    if (effort === "low") replayArtifact = items[0];
    console.log(`  ${effort}: ok`);
  }

  assert.ok(replayArtifact, "Missing artifact for replay test");
  const replayEvents = await responsesRequest(endpoint, headers, {
    model: modelId,
    input: [
      replayArtifact,
      {
        type: "message",
        role: "user",
        content: [{ type: "input_text", text: "Return only the exact marker from the compacted state." }],
      },
    ],
    instructions: "Answer from compacted state and return only the requested marker.",
    stream: true,
    store: false,
    include: ["reasoning.encrypted_content"],
    reasoning: { effort: "max", summary: "auto" },
  });
  const reply = replayEvents
    .filter((event) => event?.type === "response.output_text.delta" && typeof event.delta === "string")
    .map((event) => event.delta)
    .join("")
    .trim();
  assert.ok(reply.includes(marker), `Opaque artifact replay failed: ${reply}`);
  console.log("  opaque replay: ok");
}

function attachJsonlReader(stream, onLine) {
  const decoder = new StringDecoder("utf8");
  let buffer = "";
  stream.on("data", (chunk) => {
    buffer += typeof chunk === "string" ? chunk : decoder.write(chunk);
    while (true) {
      const newline = buffer.indexOf("\n");
      if (newline < 0) break;
      let line = buffer.slice(0, newline);
      buffer = buffer.slice(newline + 1);
      if (line.endsWith("\r")) line = line.slice(0, -1);
      if (line) onLine(line);
    }
  });
  stream.on("end", () => {
    buffer += decoder.end();
    if (buffer) onLine(buffer.endsWith("\r") ? buffer.slice(0, -1) : buffer);
  });
}

class PiRpcClient {
  constructor({ sessionDir, cwd, sessionFile }) {
    this.pending = new Map();
    this.counter = 0;
    this.closed = false;
    const args = [
      "--mode", "rpc",
      "--model", modelRef,
      "--session-dir", sessionDir,
      "--no-extensions",
      "--approve",
      "-e", extensionPath,
      "--no-tools",
    ];
    if (sessionFile) args.push("--session", sessionFile);
    this.child = spawn("pi", args, {
      cwd,
      env: { ...process.env, PI_OPENAI_SERVER_COMPACTION_NOTIFY: "0" },
      stdio: ["pipe", "pipe", "pipe"],
    });
    this.exit = new Promise((resolveExit) => {
      this.resolveExit = resolveExit;
    });
    attachJsonlReader(this.child.stdout, (line) => this.handleLine(line));
    attachJsonlReader(this.child.stderr, (line) => process.stderr.write(`${line}\n`));
    this.child.on("error", (error) => this.failPending(error));
    this.child.on("close", () => {
      this.closed = true;
      this.resolveExit();
      this.failPending(new Error("Pi RPC process exited"));
    });
  }

  handleLine(line) {
    let value;
    try {
      value = JSON.parse(line);
    } catch {
      process.stderr.write(`Unparseable Pi RPC output: ${line}\n`);
      return;
    }
    if (value?.type !== "response" || typeof value.id !== "string") return;
    const pending = this.pending.get(value.id);
    if (!pending) return;
    clearTimeout(pending.timer);
    this.pending.delete(value.id);
    pending.resolve(value);
  }

  failPending(error) {
    for (const pending of this.pending.values()) {
      clearTimeout(pending.timer);
      pending.reject(error);
    }
    this.pending.clear();
  }

  async send(command, timeoutMs = REQUEST_TIMEOUT_MS) {
    assert.equal(this.closed, false, "Pi RPC process is closed");
    const id = `request-${++this.counter}`;
    const response = await new Promise((resolveResponse, reject) => {
      const timer = setTimeout(() => {
        this.pending.delete(id);
        reject(new Error(`Pi RPC ${command.type} timed out`));
      }, timeoutMs);
      this.pending.set(id, { resolve: resolveResponse, reject, timer });
      this.child.stdin.write(`${JSON.stringify({ id, ...command })}\n`);
    });
    assert.equal(response.success, true, `Pi RPC ${command.type} failed: ${String(response.error)}`);
    return response.data;
  }

  async waitIdle() {
    const deadline = Date.now() + REQUEST_TIMEOUT_MS;
    while (Date.now() < deadline) {
      const state = await this.send({ type: "get_state" }, 30_000);
      if (state?.isStreaming !== true && state?.isCompacting !== true) return state;
      await delay(250);
    }
    throw new Error("Timed out waiting for Pi to become idle");
  }

  async lastAssistantText() {
    const data = await this.send({ type: "get_last_assistant_text" }, 30_000);
    return typeof data?.text === "string" ? data.text : "";
  }

  async close() {
    if (this.closed) return;
    try {
      await this.send({ type: "shutdown" }, 10_000);
    } catch {
      // Best effort; terminate below.
    }
    if (!this.closed) this.child.kill("SIGTERM");
    await Promise.race([this.exit, delay(10_000)]);
    if (!this.closed) this.child.kill("SIGKILL");
  }
}

function redactEncryptedContent(value) {
  if (Array.isArray(value)) return value.map(redactEncryptedContent);
  if (!isRecord(value)) return value;
  return Object.fromEntries(
    Object.entries(value).map(([key, entry]) => [
      key,
      key === "encrypted_content" ? "<encrypted>" : redactEncryptedContent(entry),
    ]),
  );
}

async function runPiIntegration(root) {
  console.log("== Pi RPC opaque replay and resume ==");
  const sessionDir = join(root, "sessions");
  const workspace = join(root, "workspace");
  await Promise.all([mkdir(sessionDir, { recursive: true }), mkdir(join(workspace, ".pi"), { recursive: true })]);
  await writeFile(
    join(workspace, ".pi", "settings.json"),
    `${JSON.stringify({ compaction: { keepRecentTokens: 1 } }, null, 2)}\n`,
  );

  let secret;
  let sessionFile;
  const client = new PiRpcClient({ sessionDir, cwd: workspace });
  try {
    await client.waitIdle();
    const levels = await client.send({ type: "get_available_thinking_levels" }, 30_000);
    assert.deepEqual(levels?.levels, THINKING_LEVELS);
    await client.send({ type: "set_thinking_level", level: "max" }, 30_000);
    await client.send({
      type: "prompt",
      message:
        "Invent a codename in the exact format COLOR-NUMBER-WORD using uppercase ASCII letters, digits, and hyphens only. Remember it and reply with only the codename.",
    });
    await client.waitIdle();
    secret = (await client.lastAssistantText()).trim();
    assert.match(secret, /^[A-Z]+-[0-9]+-[A-Z]+$/, `Unexpected generated codename: ${secret}`);

    await client.send({
      type: "prompt",
      message: `${"context-padding ".repeat(2_000)}\nReply only with PADDING-OK.`,
    });
    await client.waitIdle();
    const compact = await client.send({
      type: "compact",
      customInstructions: "Create a useful summary, but redact every exact identifier and codeword.",
    });
    const remote = compact?.details?.remoteCompaction;
    assert.equal(remote?.implementation, "responses_compaction_v2");
    assert.equal(remote?.replacementHistory?.at(-1)?.type, "compaction");
    assert.doesNotMatch(JSON.stringify(redactEncryptedContent(remote.replacementHistory)), new RegExp(secret));

    await client.send({
      type: "prompt",
      message: "What was the project codename? Reply with only the codeword.",
    });
    await client.waitIdle();
    assert.match(await client.lastAssistantText(), new RegExp(secret));
    const state = await client.send({ type: "get_state" }, 30_000);
    sessionFile = state?.sessionFile;
    assert.equal(typeof sessionFile, "string");
    console.log("  same-process opaque replay: ok");
  } finally {
    await client.close();
  }

  const resumed = new PiRpcClient({ sessionDir, cwd: workspace, sessionFile });
  try {
    await resumed.waitIdle();
    await resumed.send({
      type: "prompt",
      message: "After resuming, what was the project codename? Reply with only the codeword.",
    });
    await resumed.waitIdle();
    assert.match(await resumed.lastAssistantText(), new RegExp(secret));
    console.log("  persisted-session replay: ok");
  } finally {
    await resumed.close();
  }
}

const artifacts = await mkdtemp(join(tmpdir(), "pi-openai-compaction-live-"));
try {
  await runProtocolMatrix();
  await runPiIntegration(artifacts);
  await rm(artifacts, { recursive: true, force: true });
  console.log("All paid live compaction tests passed");
} catch (error) {
  process.stderr.write(`Live test failed; artifacts retained at ${artifacts}\n`);
  throw error;
}
