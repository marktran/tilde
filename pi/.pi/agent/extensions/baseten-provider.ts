import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const BINARY_THINKING_LEVEL_MAP = {
  minimal: null,
  low: null,
  medium: null,
  high: "high",
  xhigh: null,
} as const;

const BASETEN_KIMI = {
  id: "moonshotai/Kimi-K2.6",
  name: "kimi k2.6",
  reasoning: true,
  thinkingLevelMap: BINARY_THINKING_LEVEL_MAP,
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
    thinkingFormat: "qwen-chat-template" as const,
  },
};

const BASETEN_GLM_5 = {
  id: "zai-org/GLM-5",
  name: "glm 5",
  reasoning: true,
  thinkingLevelMap: BINARY_THINKING_LEVEL_MAP,
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
    thinkingFormat: "qwen-chat-template" as const,
  },
};

const BASETEN_DEEPSEEK_4_PRO = {
  id: "deepseek-ai/DeepSeek-V4-Pro",
  name: "deepseek 4 pro",
  reasoning: true,
  thinkingLevelMap: {
    off: null,
    minimal: null,
    low: "low",
    medium: "medium",
    high: "high",
    xhigh: "xhigh",
  },
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
    supportsReasoningEffort: true,
    requiresReasoningContentOnAssistantMessages: true,
  },
};

export default function basetenProvider(pi: ExtensionAPI) {
  pi.registerProvider("baseten", {
    baseUrl: "https://inference.baseten.co/v1",
    apiKey: "$BASETEN_API_KEY",
    api: "openai-completions",
    models: [BASETEN_KIMI, BASETEN_GLM_5, BASETEN_DEEPSEEK_4_PRO],
  });

  pi.on("before_provider_request", (event) => {
    const payload = event.payload;
    if (!payload || typeof payload !== "object") return;

    const body = payload as {
      model?: unknown;
      chat_template_kwargs?: unknown;
      chat_template_args?: unknown;
    };

    if (
      (body.model === BASETEN_KIMI.id || body.model === BASETEN_GLM_5.id) &&
      body.chat_template_kwargs &&
      !body.chat_template_args
    ) {
      const { chat_template_kwargs, ...rest } = body;
      return {
        ...rest,
        chat_template_args: chat_template_kwargs,
      };
    }
  });
}
