/**
 * Minimal footer: model name + token usage
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";

function formatTokens(tokens: number): string {
  if (tokens >= 1000000) {
    return `${(tokens / 1000000).toFixed(2)}m`;
  } else if (tokens >= 1000) {
    return `${Math.round(tokens / 1000)}k`;
  }
  return `${tokens}`;
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => {
    ctx.ui.setFooter((_tui, theme, _footerData) => ({
      dispose: () => {},
      invalidate() {},
      render(width: number): string[] {
        const model = ctx.model?.id ?? "no-model";
        const contextUsage = ctx.getContextUsage();
        const tokens = contextUsage?.tokens ?? 0;
        const percent = Math.max(0, Math.min(100, Math.round(contextUsage?.percent ?? 0)));

        const left = theme.fg("dim", ` ${model}`);
        const right = tokens === 0 && percent === 0
          ? ""
          : theme.fg("dim", ` ${formatTokens(tokens)} ${percent}% `);
        const spacer = " ".repeat(Math.max(1, width - visibleWidth(left) - visibleWidth(right)));

        return [truncateToWidth(left + spacer + right, width)];
      },
    }));
  });
}
