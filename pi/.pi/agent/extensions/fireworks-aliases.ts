import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const FIREWORKS_MODEL_ALIASES: Record<string, string> = {
  "kimi k2.7": "accounts/fireworks/models/kimi-k2p7-code",
  "minimax m3": "accounts/fireworks/models/minimax-m3",
  "glm 5.1": "accounts/fireworks/models/glm-5p1",
  "deepseek v4 pro": "accounts/fireworks/models/deepseek-v4-pro",
};

export default function fireworksAliases(pi: ExtensionAPI) {
  pi.on("before_provider_request", (event, ctx) => {
    if (ctx.model?.provider !== "fireworks") return;

    const payload = event.payload;
    if (!payload || typeof payload !== "object" || Array.isArray(payload)) return;

    const body = payload as { model?: unknown };
    if (typeof body.model !== "string") return;

    const upstreamModel = FIREWORKS_MODEL_ALIASES[body.model];
    if (!upstreamModel) return;

    return {
      ...body,
      model: upstreamModel,
    };
  });
}
