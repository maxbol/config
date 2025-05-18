{lib, ...}: final: prev: let
  nodejs = prev.nodejs_22;
  nodejs-slim = prev.nodejs-slim_22;
in
  lib.mkIf (prev.hostPlatform.isDarwin) {
    inherit nodejs nodejs-slim;
    nodejs_20 = nodejs;
    nodejs-slim_20 = nodejs-slim;
  }
