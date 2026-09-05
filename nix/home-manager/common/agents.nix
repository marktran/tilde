{ lib, outOfStore, forceLinks, pkgs, ... }:

let
  agentPreferences = builtins.readFile ../../files/agents/preferences.md;
  globalAgentPreferences = "# Global agent instructions\n\n" + agentPreferences;

  codexTestRuby = pkgs.ruby.withPackages (ps: [ ps.minitest ]);
  seedCodexConfig = pkgs.writeShellApplication {
    name = "seed-codex-config";
    runtimeInputs = [ pkgs.ruby pkgs.toml-cli ];
    text = ''exec ruby ${./seed-codex-config.rb} "$@"'';
    checkPhase = ''
      ${pkgs.runtimeShell} -n "$target"
      export PATH="${pkgs.toml-cli}/bin:$PATH"
      ${codexTestRuby}/bin/ruby ${../../tests/seed-codex-config.rb} "$target"
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

    # Shared personal preferences, without spreading Pi-specific workflow rules.
    # Leave force off for new instruction files so existing local guidance on
    # other hosts must be merged explicitly rather than silently overwritten.
    ".codex/AGENTS.md".text = globalAgentPreferences;
    ".claude/CLAUDE.md".text = globalAgentPreferences;

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
      '' + "\n" + agentPreferences;
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
    # Pi keeps model/thinking selections session-local unless explicitly saved.
    # Saved preferences and changelog state write directly to the tracked file.
    ".pi/agent/settings.json" = {
      source = outOfStore "nix/files/pi/agent/settings.json";
      force = forceLinks;
    };
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
  # Shared agent skills, layered into pi, Codex, and Claude Code skill dirs.
  // agentSkillLinks ".agents/skills"
  // agentSkillLinks ".codex/skills"
  // agentSkillLinks ".claude/skills";

  # Codex owns one local gateway config. Seed only if missing; migrate the
  # retired ChatGPT profile once, backing up both originals and retaining its
  # model/thinking choices. Detach legacy links before HM's orphan cleanup.
  # Keep this after writeBoundary so dry-run activation remains read-only.
  home.activation.seedCodexConfig = lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${seedCodexConfig}/bin/seed-codex-config \
      "${../../files/codex}" "$HOME/.codex"
  '';

}
