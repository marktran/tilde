/** OpenAI Responses model detection and payload helpers. */
import type { ResponsesReasoningConfig, ResponsesTextConfig } from "./remote-compaction.ts";
import { isRecord } from "./config.ts";

export type ModelLike = {
  api?: unknown;
  provider?: unknown;
  id?: unknown;
  baseUrl?: unknown;
  reasoning?: unknown;
  input?: readonly unknown[];
};

type AssistantMessageLike = {
  role?: unknown;
  provider?: unknown;
  model?: unknown;
};

const CLOUDFLARE_AI_GATEWAY_PROVIDER = "cloudflare-ai-gateway";
const CLOUDFLARE_AI_GATEWAY_HOST = "gateway.ai.cloudflare.com";
const ENV_PLACEHOLDER_RE = /\{([A-Za-z_][A-Za-z0-9_]*)\}/;
const ALL_ENV_PLACEHOLDERS_RE = new RegExp(ENV_PLACEHOLDER_RE.source, "g");

function urlFromBaseUrl(baseUrl: unknown): URL | undefined {
  if (typeof baseUrl !== "string" || !baseUrl.trim()) return undefined;
  try {
    return new URL(baseUrl);
  } catch {
    return undefined;
  }
}

export function hostnameFromBaseUrl(baseUrl: unknown): string | undefined {
  return urlFromBaseUrl(baseUrl)?.hostname.toLowerCase();
}

export function isOpenAIResponsesModel(model: unknown): model is ModelLike {
  return (
    isRecord(model) &&
    (model.api === "openai-responses" || model.api === "openai-codex-responses")
  );
}

export function isDirectOpenAIResponsesModel(model: ModelLike): boolean {
  if (model.api !== "openai-responses" || model.provider !== "openai") return false;
  const host = hostnameFromBaseUrl(model.baseUrl);
  return host === undefined || host === "api.openai.com";
}

/** OpenAI Responses routed through Pi's dedicated Cloudflare OpenAI endpoint. */
export function isCloudflareOpenAIResponsesModel(model: ModelLike): boolean {
  if (model.api !== "openai-responses" || model.provider !== CLOUDFLARE_AI_GATEWAY_PROVIDER) {
    return false;
  }
  const url = urlFromBaseUrl(model.baseUrl);
  const pathname = url?.pathname.replace(/\/+$/, "");
  return url?.hostname.toLowerCase() === CLOUDFLARE_AI_GATEWAY_HOST && pathname?.endsWith("/openai") === true;
}

export function isOpenAICodexResponsesModel(model: ModelLike): boolean {
  if (model.api !== "openai-codex-responses") return false;
  if (model.provider === "openai-codex") return true;
  return hostnameFromBaseUrl(model.baseUrl) === "chatgpt.com";
}

/** Responses route family used to pick remote-compaction endpoints and headers. */
export type ResponsesRoute = "openai" | "openai-codex" | "cloudflare";

export function responsesRouteForModel(model: unknown): ResponsesRoute | undefined {
  if (!isOpenAIResponsesModel(model)) return undefined;
  if (isDirectOpenAIResponsesModel(model)) return "openai";
  if (isOpenAICodexResponsesModel(model)) return "openai-codex";
  if (isCloudflareOpenAIResponsesModel(model)) return "cloudflare";
  return undefined;
}

export function supportsRemoteCompactionModel(model: unknown): model is ModelLike {
  return responsesRouteForModel(model) !== undefined;
}

/** Resolve provider-scoped placeholders such as Cloudflare account/gateway ids. */
export function resolveModelEnvironment<T extends ModelLike>(
  model: T,
  env?: Record<string, string>,
): T {
  if (typeof model.baseUrl !== "string") return model;
  const baseUrl = model.baseUrl.replace(
    ALL_ENV_PLACEHOLDERS_RE,
    (placeholder, name: string) => env?.[name] ?? process.env[name] ?? placeholder,
  );
  return baseUrl === model.baseUrl ? model : { ...model, baseUrl };
}

export function hasUnresolvedBaseUrl(model: ModelLike): boolean {
  return typeof model.baseUrl === "string" && ENV_PLACEHOLDER_RE.test(model.baseUrl);
}

export function looksLikeResponsesPayload(payload: Record<string, unknown>): boolean {
  return "input" in payload || "model" in payload || "messages" in payload;
}

export function modelKey(model: ModelLike): string {
  return `${String(model.provider)}:${String(model.api)}:${String(model.id)}`;
}

/** Thinking levels that map onto Responses reasoning efforts ("off" stays unmapped). */
const REASONING_EFFORT_LEVELS = ["minimal", "low", "medium", "high", "xhigh", "max"] as const;

export function thinkingLevelToResponsesReasoning(
  thinkingLevel: unknown,
): ResponsesReasoningConfig | undefined {
  const effort = REASONING_EFFORT_LEVELS.find((level) => level === thinkingLevel);
  return effort ? { effort, summary: "auto" } : undefined;
}

export function applyRemoteHistoryPayloadPatch(params: {
  payload: Record<string, unknown>;
  explicitHistory: unknown[];
}): Record<string, unknown> {
  const nextPayload: Record<string, unknown> = {
    ...params.payload,
    input: params.explicitHistory,
  };
  delete nextPayload.messages;
  delete nextPayload.previous_response_id;
  return nextPayload;
}

export function extractResponsesReasoningConfig(payload: unknown): ResponsesReasoningConfig | undefined {
  if (!isRecord(payload) || !isRecord(payload.reasoning)) return undefined;
  const effort = payload.reasoning.effort;
  const summary = payload.reasoning.summary;
  const normalized: ResponsesReasoningConfig = {
    ...(typeof effort === "string" ? { effort: effort as ResponsesReasoningConfig["effort"] } : {}),
    ...(
      summary === null || typeof summary === "string"
        ? { summary: summary as ResponsesReasoningConfig["summary"] }
        : {}
    ),
  };
  return Object.keys(normalized).length > 0 ? normalized : undefined;
}

export function extractResponsesTextConfig(payload: unknown): ResponsesTextConfig | undefined {
  return isRecord(payload) && isRecord(payload.text) ? payload.text : undefined;
}

export function messageMatchesModel(message: unknown, model: ModelLike): boolean {
  if (!isRecord(message)) return false;
  const candidate = message as AssistantMessageLike;
  return candidate.provider === model.provider && candidate.model === model.id;
}
