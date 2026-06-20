{ config, lib, checkoutPath }:

let
  mkEntry = packageName: entry:
    let
      sourcePath = if builtins.isString entry then entry else entry.source;
      targetPath = if builtins.isString entry then entry else entry.target;
    in
    {
      name = targetPath;
      value = {
        force = true;
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
