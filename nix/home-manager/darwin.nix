{ config, lib, checkoutPath, ... }:

let
  stow = import ../lib/stow-package.nix {
    inherit config lib checkoutPath;
  };
in
{
  home.file = stow.linksFor [
    {
      name = "macos";
      entries = [
        "Brewfile"
        "Elgato Wave XLR.wavelink"
        "Pastels.terminal"
      ];
    }
  ];
}
