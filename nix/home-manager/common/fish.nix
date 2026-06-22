{ outOfStore, ... }:

let
  fishFile = path: {
    source = outOfStore "nix/files/fish/${path}";
    force = true;
  };
in
{
  programs.direnv = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
    options = [ "--cmd" "j" ];
  };

  programs.mise = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.fish = {
    enable = true;
    generateCompletions = false;

    # Keep Home Manager-owned integrations here, but source frequently edited
    # fish syntax from repo-managed files under nix/files/fish/config.d/.
    shellInit = ''
      source "$HOME/.config/fish/config.d/env.fish"
      source "$HOME/.config/fish/config.d/colors.fish"
      source "$HOME/.config/fish/config.d/git-prompt.fish"
      source "$HOME/.config/fish/config.d/local-loader.fish"
    '';

    interactiveShellInit = ''
      source "$HOME/.config/fish/config.d/aliases.fish"
    '';

    shellInitLast = ''
      source "$HOME/.config/fish/config.d/post-integrations.fish"
    '';
  };

  xdg.configFile = {
    "fish/config.d/aliases.fish" = fishFile "config.d/aliases.fish";
    "fish/config.d/colors.fish" = fishFile "config.d/colors.fish";
    "fish/config.d/env.fish" = fishFile "config.d/env.fish";
    "fish/config.d/git-prompt.fish" = fishFile "config.d/git-prompt.fish";
    "fish/config.d/local-loader.fish" = fishFile "config.d/local-loader.fish";
    "fish/config.d/post-integrations.fish" = fishFile "config.d/post-integrations.fish";

    "fish/completions/docker.fish" = fishFile "completions/docker.fish";
    "fish/completions/kubectl.fish" = fishFile "completions/kubectl.fish";
    "fish/completions/orbctl.fish" = fishFile "completions/orbctl.fish";
    "fish/completions/sesh.fish" = fishFile "completions/sesh.fish";
    "fish/completions/tmuxinator.fish" = fishFile "completions/tmuxinator.fish";

    "fish/functions/__bass.py" = fishFile "functions/__bass.py";
    "fish/functions/bass.fish" = fishFile "functions/bass.fish";
    "fish/functions/btmm.fish" = fishFile "functions/btmm.fish";
    "fish/functions/cd.fish" = fishFile "functions/cd.fish";
    "fish/functions/fish_greeting.fish" = fishFile "functions/fish_greeting.fish";
    "fish/functions/fish_prompt.fish" = fishFile "functions/fish_prompt.fish";
    "fish/functions/l..fish" = fishFile "functions/l..fish";
    "fish/functions/ls.fish" = fishFile "functions/ls.fish";
    "fish/functions/set_pwd_color.fish" = fishFile "functions/set_pwd_color.fish";
  };
}
