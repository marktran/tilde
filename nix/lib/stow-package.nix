{ config, lib, checkoutPath, forceStowLinks ? false }:

let
  mkEntry = packageName: entry:
    let
      sourcePath = if builtins.isString entry then entry else entry.source;
      targetPath = if builtins.isString entry then entry else entry.target;
      forceLink =
        if builtins.isAttrs entry && builtins.hasAttr "force" entry
        then entry.force
        else forceStowLinks;
    in
    {
      name = targetPath;
      value = {
        force = forceLink;
        source =
          config.lib.file.mkOutOfStoreSymlink
            "${checkoutPath}/${packageName}/${sourcePath}";
      };
    };

  mkPackageLinks = package:
    builtins.listToAttrs (map (mkEntry package.name) package.entries);
in
{
  linksFor = packages:
    lib.foldl' (links: package: links // mkPackageLinks package) { } packages;
}
