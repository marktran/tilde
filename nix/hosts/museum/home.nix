{ lib, pkgs, ... }:

let
  # The exeuntu image ships a Pi extension (exe-dev) that routes Pi through
  # the VM's LLM integration endpoints (reflection.int.exe.xyz). The managed
  # ~/.pi/agent/extensions link replaces the directory Pi would auto-discover
  # it in, so script/exe-setup.sh relocates it to ~/.pi/exe-dev and the Pi
  # settings defaults here gain that path. Derived from the laptop defaults so
  # the lists cannot drift.
  laptopPiDefaults = builtins.fromJSON
    (builtins.readFile ../../files/pi/agent/settings.default.json);
  museumPiDefaults = laptopPiDefaults // {
    extensions = laptopPiDefaults.extensions ++ [ "/home/exedev/.pi/exe-dev" ];
  };
in
{
  # Host-specific user config for the museum exe.dev VM (museum.exe.xyz), a
  # headless Ubuntu 24.04 machine for cloud agent development on the Museum
  # project. It imports only nix/home-manager/core.nix; provisioning and
  # machine-local glue (login shell, ~/.config/fish/local.fish, the exe.dev
  # env file) live in script/exe-setup.sh in the museum repo.
  #
  # Secrets and pairing state are out of band, like the Rails master.key:
  # ~/.pi/agent/auth.json, Herdr runtime state, fish_variables.

  # Git signing uses 1Password via op-ssh-sign-wrapper (see common/git.nix),
  # which does not exist on the VM, and the signing key stays on the laptops.
  # Commits made on the VM are therefore unsigned rather than broken.
  programs.git.signing.signByDefault = lib.mkForce false;

  home.file.".pi/agent/settings.default.json".source = lib.mkForce
    (pkgs.writeText "settings.default.json" (builtins.toJSON museumPiDefaults));
}
