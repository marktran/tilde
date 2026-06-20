{ config, lib, checkoutPath, forceStowLinks, ... }:

let
  stow = import ../lib/stow-package.nix {
    inherit config lib checkoutPath forceStowLinks;
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
