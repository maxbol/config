{...}: final: prev: let
  nodejs =
    if prev.stdenv.hostPlatform.isDarwin == true
    then prev.nodejs_22
    else prev.nodejs;
  nodejs-slim =
    if prev.stdenv.hostPlatform.isDarwin == true
    then prev.nodejs-slim_22
    else prev.nodejs-slim;
in {
  inherit nodejs nodejs-slim;
  nodejs_20 = nodejs;
  nodejs-slim_20 = nodejs-slim;
}
