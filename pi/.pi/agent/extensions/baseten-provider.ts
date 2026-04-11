import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const BASETEN_KIMI = {
  id: "moonshotai/Kimi-K2.5",
  name: "kimi k2.5",
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

export default function basetenProvider(pi: ExtensionAPI) {
  pi.registerProvider("baseten", {
    baseUrl: "https://inference.baseten.co/v1",
    apiKey: "BASETEN_API_KEY",
    api: "openai-completions",
    models: [BASETEN_KIMI],
  });
}
