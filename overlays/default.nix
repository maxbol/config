overlayArgs: system:
[
  (import ./azuredatastudio-fix.nix overlayArgs)
]
++ (
  if system == "aarch64-darwin"
  then [
    (import ./nodejs-build-issue.nix overlayArgs)
  ]
  else []
)
