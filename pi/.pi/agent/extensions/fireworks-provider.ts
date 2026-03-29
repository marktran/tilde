import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const FIREWORKS_KIMI_TURBO = {
  id: "accounts/fireworks/routers/kimi-k2p5-turbo",
  name: "kimi k2.5 turbo",
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

export default function fireworksProvider(pi: ExtensionAPI) {
  pi.registerProvider("fireworks", {
    baseUrl: "https://api.fireworks.ai/inference/v1",
    apiKey: "FIREWORKS_API_KEY",
    api: "openai-completions",
    models: [FIREWORKS_KIMI_TURBO],
  });
}
