{ lib, outOfStore, forceLinks, pkgs, ... }:

let
  # Keep repo-managed Pi settings authoritative without making settings.json
  # read-only: Pi may continue writing runtime-only keys such as the selected
  # model, thinking level, and changelog state.
  syncPiSettings = pkgs.writeShellApplication {
    name = "sync-pi-settings";
    runtimeInputs = [ pkgs.coreutils pkgs.jq ];
    text = ''
      set -euo pipefail

      defaults="''${1:?defaults path required}"
      settings="''${2:?settings path required}"
      [ -e "$defaults" ] || exit 0

      mkdir -p "$(dirname "$settings")"
      tmp="$(mktemp "$settings.tmp.XXXXXX")"
      trap 'rm -f "$tmp"' EXIT

      if [ -e "$settings" ]; then
        # Existing-only keys are Pi-owned runtime state. For keys present in
        # both files, the tracked defaults win; arrays are replaced rather
        # than accumulated, so removed packages/resources stay removed.
        jq --slurp '.[0] * .[1]' "$settings" "$defaults" > "$tmp"
      else
        cp "$defaults" "$tmp"
      fi
      chmod 600 "$tmp"

      if [ -e "$settings" ] && cmp -s "$tmp" "$settings"; then
        chmod 600 "$settings"
        exit 0
      fi

      printf 'Synchronizing Pi settings from %s\n' "$defaults"
      mv "$tmp" "$settings"
      trap - EXIT
    '';
  };

  # Agent skills shared across harnesses. Linked per-skill into each harness's
  # skill dir so the Linux-only Omarchy skill (see linux.nix) can be layered
  # into the same dirs. Each skill stays live-editable from the checkout.
  # herdr is the release-matched output of `herdr --skill` from v0.8.2
  # (Apache-2.0), matching the packaged Herdr binary release.
  # open-prose is vendored third-party content (MIT): skills/open-prose from
  # github.com/openprose/prose, v0.15.0 at aad1b43fd373d3cce3fea2109b413c4cd0673f51.
  # shadcn is vendored third-party content (MIT): skills/shadcn from
  # github.com/shadcn-ui/ui at 683a5a9b370acdb7785a0529434e6a3b8c7e0441.
  # Keep the trees pristine so refreshes are a clean re-extract + diff.
  sharedAgentSkills = [
    "defuddle"
    "herdr"
    "json-canvas"
    "obsidian-bases"
    "obsidian-cli"
    "obsidian-markdown"
    "open-prose"
    "shadcn"
  ];
  agentSkillLinks = dir: lib.listToAttrs (map (skill: {
    name = "${dir}/${skill}";
    value = {
      source = outOfStore "nix/files/agents/skills/${skill}";
      force = true;
    };
  }) sharedAgentSkills);
in
{
  home.file = {
    # Claude Code user settings (static).
    ".claude/settings.json" = {
      source = ../../files/claude/settings.json;
      force = true;
    };

    # Codex `chatgpt` profile layer (`codex --profile chatgpt`) keeps ChatGPT
    # auth for interactive use. Codex never writes profile files: store-backed.
    ".codex/chatgpt.config.toml" = {
      source = ../../files/codex/chatgpt.config.toml;
      force = true;
    };

    # pi: static config (store-backed).
    ".pi/agent/AGENTS.md" = {
      text = ''
        # Global agent instructions

        ## Workflow proportionality

        - Do not automatically invoke Compound Engineering skills (`ce-*` or `lfg`)
          from an ordinary request to add, change, fix, debug, review, or implement
          something. Such a request does not count as an invocation of `ce-work`,
          regardless of how broadly that skill's description is written.
        - Use a Compound Engineering skill only when I explicitly name or invoke that
          skill, or explicitly say to use Compound Engineering.
        - For small, well-scoped tasks, work inline: inspect, edit, run focused
          verification, and stop. Do not spawn subagents or reviewers.
        - When unsure, default to the smallest proportional workflow; do not escalate
          to Compound Engineering.
      '';
      force = true;
    };
    ".pi/agent/keybindings.json" = {
      source = ../../files/pi/agent/keybindings.json;
      force = true;
    };
    ".pi/agent/models.json" = {
      source = ../../files/pi/agent/models.json;
      force = true;
    };
    ".pi/agent/openai-server-compaction.json" = {
      source = ../../files/pi/agent/openai-server-compaction.json;
      force = true;
    };
    ".pi/agent/pi-auto-permissions/config.json" = {
      source = ../../files/pi/agent/pi-auto-permissions/config.json;
      force = true;
    };
    ".pi/agent/presets.json" = {
      source = ../../files/pi/agent/presets.json;
      force = true;
    };
    ".pi/agent/settings.default.json" = {
      source = ../../files/pi/agent/settings.default.json;
      force = true;
    };
    # Repo themes are store-backed, but link them per-file (recursive) so the
    # directory itself stays a real, writable dir: on Omarchy, `omarchy theme
    # set` runs omarchy-theme-set-pi, which writes the generated
    # omarchy-system.json (a pi theme tracking the system theme) into this
    # dir. With the whole dir store-linked, that write failed with EACCES.
    # omarchy-system.json is regenerated per theme change; runtime state, not
    # repo content.
    ".pi/agent/themes" = {
      source = ../../files/pi/agent/themes;
      recursive = true;
      force = true;
    };

    # pi: mutable/app-written resources (live-editable bridge links).
    # settings.json remains a real writable file. The activation hook below
    # overlays settings.default.json onto it while preserving Pi's live-only
    # model, thinking-level, changelog, and other runtime keys.
    # Herdr installs its Pi lifecycle integration into this linked directory as
    # herdr-agent-state.ts, so upgrades update the repo-managed source directly.
    ".pi/agent/extensions" = {
      source = outOfStore "nix/files/pi/agent/extensions";
      force = forceLinks;
    };
    ".pi/agent/skills" = {
      source = outOfStore "nix/files/pi/agent/skills";
      force = forceLinks;
    };
  }
  # Codex CLI (non-macOS only): the default model_provider is the same
  # Cloudflare AI Gateway Pi uses (token exported by
  # fish/conf.d/cloudflare-ai-gateway.fish), so non-interactive shell-outs —
  # e.g. Compound Engineering cross-model review — need no ChatGPT login.
  # Codex rewrites config.toml (project trust, TUI state), so keep it a
  # writable out-of-store link; runtime writes surface as git drift in the
  # checkout. On macOS the ChatGPT desktop app owns ~/.codex/config.toml
  # (plugins, MCP servers, desktop prefs, trusted projects), and none of that
  # machine-local state belongs in this public repo: leave it unmanaged there.
  // lib.optionalAttrs (!pkgs.stdenv.hostPlatform.isDarwin) {
    ".codex/config.toml" = {
      source = outOfStore "nix/files/codex/config.toml";
      force = forceLinks;
    };
  }
  # Shared agent skills, layered into pi, Codex, and Claude Code skill dirs.
  // agentSkillLinks ".agents/skills"
  // agentSkillLinks ".codex/skills"
  // agentSkillLinks ".claude/skills";

  home.activation.syncPiSettings = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    $DRY_RUN_CMD ${syncPiSettings}/bin/sync-pi-settings \
      "$HOME/.pi/agent/settings.default.json" \
      "$HOME/.pi/agent/settings.json"
  '';

}
