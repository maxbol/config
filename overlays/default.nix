overlayArgs @ {inputs, ...}: system:
[
  (import ./azuredatastudio-fix.nix overlayArgs)
  inputs.hyprpanel.overlay
  inputs.niri.overlays.niri
]
++ (
  if system == "aarch64-darwin"
  then [
    (import ./nodejs-build-issue.nix overlayArgs)
  ]
  else []
)
