{lib, ...}: {
  dirname = path: let
    parts = lib.path.splitRoot path;
  in
    parts.root + (dirOf parts.subpath);
}
