/**
 * Minimal footer: model name + context usage bar
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";

export default function (pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => {
    ctx.ui.setFooter((_tui, theme, _footerData) => ({
      dispose: () => {},
      invalidate() {},
      render(width: number): string[] {
        const model = ctx.model?.id ?? "no-model";
        const percent = Math.max(0, Math.min(100, Math.round(ctx.getContextUsage()?.percent ?? 0)));

        const totalBlocks = 10;
        const filledBlocks = Math.round((percent / 100) * totalBlocks);
        const bar = "█".repeat(filledBlocks) + "░".repeat(totalBlocks - filledBlocks);

        const left = theme.fg("dim", ` ${model}`);
        const right = theme.fg("dim", `[${bar}] ${percent}% `);
        const spacer = " ".repeat(Math.max(1, width - visibleWidth(left) - visibleWidth(right)));

        return [truncateToWidth(left + spacer + right, width)];
      },
    }));
  });
}
