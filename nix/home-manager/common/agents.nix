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
    ".pi/agent/prompts" = {
      source = ../../files/pi/agent/prompts;
      force = true;
    };
    ".pi/agent/themes" = {
      source = ../../files/pi/agent/themes;
      force = true;
    };

    # pi: mutable/app-written state (live-editable bridge links).
    ".pi/agent/settings.json" = {
      source = outOfStore "nix/files/pi/agent/settings.json";
      force = forceLinks;
    };
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
}
