{ lib, outOfStore, forceLinks, ... }:

let
  # Agent skills shared across harnesses. Linked per-skill into a target dir
  # (e.g. ~/.agents/skills for pi, ~/.claude/skills for Claude Code) so the
  # Linux-only Omarchy skill (see linux.nix) can be layered into the same dir.
  # Each skill stays live-editable from the checkout.
  sharedAgentSkills = [
    "defuddle"
    "json-canvas"
    "obsidian-bases"
    "obsidian-cli"
    "obsidian-markdown"
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

    # pi: static config (store-backed).
    ".pi/agent/agents" = {
      source = ../../files/pi/agent/agents;
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
    ".pi/agent/presets.json" = {
      source = ../../files/pi/agent/presets.json;
      force = true;
    };
    ".pi/agent/settings.default.json" = {
      source = ../../files/pi/agent/settings.default.json;
      force = true;
    };
    ".pi/agent/prompts" = {
      source = ../../files/pi/agent/prompts;
      force = true;
    };
    ".pi/agent/themes" = {
      source = ../../files/pi/agent/themes;
      force = true;
    };

    # pi: mutable/app-written resources (live-editable bridge links).
    # settings.json is intentionally not managed: Pi rewrites model defaults,
    # thinking level, changelog state, etc. Keep settings.default.json above as
    # a repo-tracked bootstrap reference and let the live settings file flap.
    ".pi/agent/extensions" = {
      source = outOfStore "nix/files/pi/agent/extensions";
      force = forceLinks;
    };
    ".pi/agent/skills" = {
      source = outOfStore "nix/files/pi/agent/skills";
      force = forceLinks;
    };
  }
  # Shared agent skills, layered into both pi's and Claude Code's skill dirs.
  // agentSkillLinks ".agents/skills"
  // agentSkillLinks ".claude/skills";

  home.activation.initPiSettings = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    settings="$HOME/.pi/agent/settings.json"
    defaults="$HOME/.pi/agent/settings.default.json"
    if [ ! -e "$settings" ] && [ -e "$defaults" ]; then
      $DRY_RUN_CMD cp "$defaults" "$settings"
      $DRY_RUN_CMD chmod u+w "$settings"
    fi
  '';

}
