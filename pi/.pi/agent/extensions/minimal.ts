/**
 * Minimal footer: model name + token usage (session total + context %)
 */

import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import type { AgentMessage, AssistantMessage } from "@mariozechner/pi-agent-core";
import { truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";

function formatTokens(tokens: number): string {
  if (tokens >= 1000000) {
    return `${(tokens / 1000000).toFixed(2)}m`;
  } else if (tokens >= 1000) {
    return `${Math.round(tokens / 1000)}k`;
  }
  return `${tokens}`;
}

/**
 * Calculate total session tokens from all assistant messages in the session.
 * This sums up the usage.totalTokens from each assistant message.
 */
function calculateSessionTokens(ctx: ExtensionContext): number {
  const entries = ctx.sessionManager.getEntries();
  let totalTokens = 0;

  for (const entry of entries) {
    if (entry.type === "message") {
      const msg = entry.message as AgentMessage;
      if (msg.role === "assistant") {
        const assistantMsg = msg as AssistantMessage;
        // Sum input + output + cache tokens
        if (assistantMsg.usage) {
          totalTokens += assistantMsg.usage.totalTokens ?? 0;
        }
      }
    }
  }

  return totalTokens;
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => {
    ctx.ui.setFooter((_tui, theme, _footerData) => ({
      dispose: () => {},
      invalidate() {},
      render(width: number): string[] {
        const model = ctx.model?.name ?? ctx.model?.id ?? "no-model";
        const contextUsage = ctx.getContextUsage();
        const contextTokens = contextUsage?.tokens ?? 0;
        const contextPercent = Math.max(0, Math.min(100, Math.round(contextUsage?.percent ?? 0)));

        // Calculate total session tokens from all assistant messages
        const sessionTokens = calculateSessionTokens(ctx);

        const left = theme.fg("dim", ` ${model}`);

        // Show both session total and context percentage
        // Format: "172k (45%)" or just "172k" if no context percent
        const rightParts: string[] = [];
        if (sessionTokens > 0) {
          rightParts.push(formatTokens(sessionTokens));
        }
        if (contextPercent > 0) {
          rightParts.push(`${contextPercent}%`);
        }

        const right = rightParts.length > 0
          ? theme.fg("dim", ` ${rightParts.join(" ")} `)
          : "";
        const spacer = " ".repeat(Math.max(1, width - visibleWidth(left) - visibleWidth(right)));

        return [truncateToWidth(left + spacer + right, width)];
      },
    }));
  });
}
