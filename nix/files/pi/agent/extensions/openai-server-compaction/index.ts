/**
 * Codex-style remote compaction for OpenAI Responses models, including Pi's
 * Cloudflare AI Gateway provider. Normal turns retain Pi's built-in transport;
 * only compaction and post-compaction history replay are customized.
 */
import type {
  ExtensionAPI,
  ExtensionContext,
  SessionEntry,
} from "@earendil-works/pi-coding-agent";
import type { AgentMessage } from "@earendil-works/pi-agent-core";
import type { Usage } from "@earendil-works/pi-ai";
import { isRecord, loadConfig } from "./config.ts";
import {
  applyRemoteHistoryPayloadPatch,
  extractResponsesReasoningConfig,
  extractResponsesTextConfig,
  hasUnresolvedBaseUrl,
  looksLikeResponsesPayload,
  messageMatchesModel,
  type ModelLike,
  modelKey,
  resolveModelEnvironment,
  supportsRemoteCompactionModel,
  thinkingLevelToResponsesReasoning,
} from "./openai.ts";
import {
  buildCompactionSummaryText,
  buildRemoteCompactionDetails,
  buildToolsPayload,
  callRemoteCompactionEndpoint,
  generateBestEffortLocalSummary,
  messageToResponseItems,
  messagesToResponseItems,
  normalizeResponseItemsForPrompt,
  reconstructRemoteCompactionStateFromBranch,
  type RemoteCompactionSessionState,
} from "./remote-compaction.ts";
import {
  clearAllRuntimeState,
  remoteCompactionState,
  responsesRequestShapeState,
} from "./state.ts";

function getSessionId(ctx: ExtensionContext): string {
  return ctx.sessionManager.getSessionId();
}

function getBranchMessages(branchEntries: SessionEntry[]): AgentMessage[] {
  return branchEntries.flatMap((entry) =>
    entry.type === "message" && entry.message ? [entry.message] : [],
  );
}

function getBranchThinkingLevel(branchEntries: SessionEntry[]): string | undefined {
  for (let index = branchEntries.length - 1; index >= 0; index--) {
    const entry = branchEntries[index];
    if (entry?.type !== "thinking_level_change") continue;
    return typeof entry.thinkingLevel === "string" ? entry.thinkingLevel : undefined;
  }
  return undefined;
}

function clearSessionRuntimeState(sessionId: string | undefined): void {
  remoteCompactionState.clear(sessionId);
  responsesRequestShapeState.clear(sessionId);
}

function syncRemoteState(ctx: ExtensionContext): void {
  const sessionId = getSessionId(ctx);
  const state = reconstructRemoteCompactionStateFromBranch({
    branchEntries: ctx.sessionManager.getBranch(),
  });
  if (state) {
    remoteCompactionState.set(sessionId, state);
  } else {
    remoteCompactionState.clear(sessionId);
  }
}

function getMatchingRemoteState(
  sessionId: string,
  model: ModelLike | undefined,
): RemoteCompactionSessionState | undefined {
  if (!model) return undefined;
  const remoteState = remoteCompactionState.get(sessionId);
  return remoteState && remoteState.modelKey === modelKey(model) ? remoteState : undefined;
}

function extendRemoteHistoryIfCompatible(params: {
  sessionId: string;
  model: ModelLike | undefined;
  message: AgentMessage;
}): void {
  const remoteState = getMatchingRemoteState(params.sessionId, params.model);
  if (!remoteState || !params.model) return;
  if (params.message.role === "assistant" && !messageMatchesModel(params.message, params.model)) {
    return;
  }

  const items = messageToResponseItems(params.message);
  if (items.length === 0) return;

  remoteCompactionState.set(params.sessionId, {
    ...remoteState,
    explicitHistory: [...remoteState.explicitHistory, ...items],
  });
}

function combineUsage(...values: Array<Usage | undefined>): Usage | undefined {
  const usages = values.filter((value): value is Usage => value !== undefined);
  if (usages.length === 0) return undefined;
  const sum = (pick: (usage: Usage) => number | undefined): number =>
    usages.reduce((total, usage) => total + (pick(usage) ?? 0), 0);
  const hasReasoning = usages.some((usage) => usage.reasoning !== undefined);
  const hasCacheWrite1h = usages.some((usage) => usage.cacheWrite1h !== undefined);
  return {
    input: sum((usage) => usage.input),
    output: sum((usage) => usage.output),
    cacheRead: sum((usage) => usage.cacheRead),
    cacheWrite: sum((usage) => usage.cacheWrite),
    ...(hasCacheWrite1h ? { cacheWrite1h: sum((usage) => usage.cacheWrite1h) } : {}),
    ...(hasReasoning ? { reasoning: sum((usage) => usage.reasoning) } : {}),
    totalTokens: sum((usage) => usage.totalTokens),
    cost: {
      input: sum((usage) => usage.cost.input),
      output: sum((usage) => usage.cost.output),
      cacheRead: sum((usage) => usage.cost.cacheRead),
      cacheWrite: sum((usage) => usage.cost.cacheWrite),
      total: sum((usage) => usage.cost.total),
    },
  };
}

function maybeNotifyRequestFeatures(params: {
  notifiedModels: Set<string>;
  hasUI: boolean;
  notify: boolean;
  ui: { notify(message: string, level: "info" | "warning"): void };
  model: ModelLike;
  features: string[];
}): void {
  if (!params.notify || !params.hasUI || params.features.length === 0) return;

  const key = `${String(params.model.provider)}/${String(params.model.id)}`;
  const noticeKey = `${key}:${params.features.join(",")}`;
  if (params.notifiedModels.has(noticeKey)) return;

  params.notifiedModels.add(noticeKey);
  params.ui.notify(`OpenAI compaction active for ${key} (${params.features.join(", ")})`, "info");
}

export default function openaiServerCompactionExtension(pi: ExtensionAPI) {
  const notifiedModels = new Set<string>();

  pi.on("session_start", (_event, ctx) => {
    responsesRequestShapeState.clear(getSessionId(ctx));
    syncRemoteState(ctx);
  });

  const clearBeforeSessionChange = (_event: unknown, ctx: ExtensionContext): void => {
    clearSessionRuntimeState(getSessionId(ctx));
  };
  pi.on("session_before_switch", clearBeforeSessionChange);
  pi.on("session_before_fork", clearBeforeSessionChange);
  pi.on("session_before_tree", clearBeforeSessionChange);

  const syncAfterSessionChange = (_event: unknown, ctx: ExtensionContext): void => {
    syncRemoteState(ctx);
  };
  pi.on("session_tree", syncAfterSessionChange);
  pi.on("session_compact", syncAfterSessionChange);

  pi.on("session_shutdown", () => {
    clearAllRuntimeState();
  });

  pi.on("session_before_compact", async (event, ctx) => {
    const cfg = loadConfig(ctx.cwd);
    const model = ctx.model;
    if (!cfg.enabled || !model || !supportsRemoteCompactionModel(model)) return undefined;

    const auth = await ctx.modelRegistry.getApiKeyAndHeaders(model);
    if (!auth.ok) return undefined;
    const hasHeaders = auth.headers !== undefined && Object.keys(auth.headers).length > 0;
    if (!auth.apiKey && !hasHeaders) return undefined;

    const resolvedModel = resolveModelEnvironment(model, auth.env);
    if (hasUnresolvedBaseUrl(resolvedModel)) {
      if (!event.signal.aborted && ctx.hasUI) {
        ctx.ui.notify(
          `OpenAI remote compaction skipped: unresolved provider placeholders in ${String(resolvedModel.baseUrl)}`,
          "warning",
        );
      }
      return undefined;
    }

    const tools = buildToolsPayload(pi.getAllTools(), pi.getActiveTools());
    const sessionId = getSessionId(ctx);
    const branchEntries = event.branchEntries;
    const remoteState = getMatchingRemoteState(sessionId, model);
    const observedRequestShape = responsesRequestShapeState.get(sessionId);
    const fullBranchMessages = getBranchMessages(branchEntries);
    const responseItems = remoteState
      ? remoteState.explicitHistory
      : messagesToResponseItems(fullBranchMessages);
    const promptResponseItems = normalizeResponseItemsForPrompt(responseItems, model);
    const thinkingLevel = pi.getThinkingLevel();
    const fallbackReasoning = resolvedModel.reasoning
      ? thinkingLevelToResponsesReasoning(thinkingLevel ?? getBranchThinkingLevel(branchEntries))
      : undefined;
    const reasoning = observedRequestShape?.reasoning ?? fallbackReasoning;
    const text = observedRequestShape?.text;

    const [localResult, remoteResult] = await Promise.allSettled([
      generateBestEffortLocalSummary({
        preparation: event.preparation,
        messages: fullBranchMessages,
        model: resolvedModel,
        apiKey: auth.apiKey,
        headers: auth.headers,
        env: auth.env,
        customInstructions: event.customInstructions,
        signal: event.signal,
        thinkingLevel,
        firstKeptEntryId: event.preparation.firstKeptEntryId,
        tokensBefore: event.preparation.tokensBefore,
      }),
      callRemoteCompactionEndpoint({
        model: resolvedModel,
        apiKey: auth.apiKey,
        headers: auth.headers,
        sessionId,
        input: promptResponseItems,
        instructions: ctx.getSystemPrompt(),
        tools,
        parallelToolCalls: true,
        reasoning,
        text,
        signal: event.signal,
      }),
    ]);

    if (remoteResult.status !== "fulfilled") {
      if (!event.signal.aborted && ctx.hasUI) {
        const message = remoteResult.reason instanceof Error ? remoteResult.reason.message : String(remoteResult.reason);
        ctx.ui.notify(`OpenAI remote compaction failed; using text compaction. ${message}`, "warning");
      }
      return localResult.status === "fulfilled" ? { compaction: localResult.value } : undefined;
    }

    const remoteDetails = buildRemoteCompactionDetails(
      resolvedModel,
      remoteResult.value.output,
      remoteResult.value.usage,
    );
    const localSummary =
      localResult.status === "fulfilled"
        ? localResult.value
        : {
            summary: buildCompactionSummaryText(resolvedModel),
            firstKeptEntryId: event.preparation.firstKeptEntryId,
            tokensBefore: event.preparation.tokensBefore,
          };

    return {
      compaction: {
        summary: localSummary.summary,
        firstKeptEntryId: localSummary.firstKeptEntryId,
        tokensBefore: localSummary.tokensBefore,
        usage: combineUsage(localSummary.usage, remoteResult.value.usage),
        details: {
          ...(localSummary.details !== undefined ? { localSummaryDetails: localSummary.details } : {}),
          remoteCompaction: remoteDetails,
        },
      },
    };
  });

  pi.on("message_end", (event, ctx) => {
    extendRemoteHistoryIfCompatible({
      sessionId: getSessionId(ctx),
      model: ctx.model,
      message: event.message,
    });
  });

  pi.on("before_provider_request", (event, ctx) => {
    const cfg = loadConfig(ctx.cwd);
    if (!cfg.enabled) return undefined;

    const model = ctx.model;
    if (
      !model ||
      !supportsRemoteCompactionModel(model) ||
      !isRecord(event.payload) ||
      !looksLikeResponsesPayload(event.payload)
    ) return undefined;

    const sessionId = getSessionId(ctx);
    responsesRequestShapeState.set(sessionId, {
      reasoning: extractResponsesReasoningConfig(event.payload),
      text: extractResponsesTextConfig(event.payload),
    });
    const remoteState = getMatchingRemoteState(sessionId, model);
    if (!remoteState) return undefined;

    const payload = applyRemoteHistoryPayloadPatch({
      payload: event.payload,
      explicitHistory: normalizeResponseItemsForPrompt(remoteState.explicitHistory, model) as unknown[],
    });
    maybeNotifyRequestFeatures({
      notifiedModels,
      hasUI: ctx.hasUI,
      notify: cfg.notify,
      ui: ctx.ui,
      model,
      features: ["remote_compaction_history"],
    });
    return payload;
  });
}
