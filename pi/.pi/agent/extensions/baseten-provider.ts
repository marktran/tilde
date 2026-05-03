import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const BASETEN_KIMI = {
  id: "moonshotai/Kimi-K2.6",
  name: "kimi k2.6",
  reasoning: true,
  input: ["text", "image"] as const,
  cost: {
    input: 0,
    output: 0,
    cacheRead: 0,
    cacheWrite: 0,
  },
  contextWindow: 262144,
  maxTokens: 32768,
  compat: {
    maxTokensField: "max_tokens" as const,
    supportsStore: false,
    supportsDeveloperRole: false,
    supportsReasoningEffort: false,
  },
};

const BASETEN_GLM_5 = {
  id: "zai-org/GLM-5",
  name: "glm 5",
  reasoning: true,
  input: ["text"] as const,
  cost: {
    input: 0,
    output: 0,
    cacheRead: 0,
    cacheWrite: 0,
  },
  contextWindow: 200000,
  maxTokens: 128000,
  compat: {
    maxTokensField: "max_tokens" as const,
    supportsStore: false,
    supportsDeveloperRole: false,
    supportsReasoningEffort: false,
  },
};

const BASETEN_DEEPSEEK_4_PRO = {
  id: "deepseek-ai/DeepSeek-V4-Pro",
  name: "deepseek 4 pro",
  reasoning: true,
  input: ["text"] as const,
  cost: {
    input: 0,
    output: 0,
    cacheRead: 0,
    cacheWrite: 0,
  },
  contextWindow: 1000000,
  maxTokens: 384000,
  compat: {
    maxTokensField: "max_tokens" as const,
    supportsStore: false,
    supportsDeveloperRole: false,
    thinkingFormat: "deepseek" as const,
    requiresReasoningContentOnAssistantMessages: true,
    reasoningEffortMap: {
      minimal: "high",
      low: "high",
      medium: "high",
      high: "high",
      xhigh: "max",
    },
  },
};

export default function basetenProvider(pi: ExtensionAPI) {
  pi.registerProvider("baseten", {
    baseUrl: "https://inference.baseten.co/v1",
    apiKey: "BASETEN_API_KEY",
    api: "openai-completions",
    models: [BASETEN_KIMI, BASETEN_GLM_5, BASETEN_DEEPSEEK_4_PRO],
  });
}
