{ pkgs, ... }:

# Workstation profile shared by both laptops: the headless core (fish, git,
# neovim, Herdr, Pi/agents -- see core.nix) plus everything that only makes
# sense on a machine with a screen or a full desktop workflow.

{
  imports = [
    ./core.nix
    ./common/tmux.nix
    ./common/ghostty.nix
    ./common/files.nix
    ./common/obsidian.nix
  ];

  # Workstation-only CLI tools, on top of the core set in core.nix.
  home.packages = with pkgs; [
    aspell
    aspellDicts.en
    calc
    enchant
    hunk
    pwgen
    scowl
    sesh
    zig_0_16 # ghostel's build.zig.zon sets minimum_zig_version
  ];
}
