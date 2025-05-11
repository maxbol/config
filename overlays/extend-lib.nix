final: prev: {
  lib = prev.lib // ((import ../lib) {inherit (prev) lib;});
}
