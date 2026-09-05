{ lib, outOfStore, ... }:

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

  # The exeuntu image's exe-dev extension is relocated to ~/.pi/exe-dev by
  # script/exe-setup.sh. Keep that extra path in a host-specific, writable
  # settings file without imposing the laptops' saved model preferences.
  home.file.".pi/agent/settings.json".source = lib.mkForce
    (outOfStore "nix/hosts/museum/pi-settings.json");
}
