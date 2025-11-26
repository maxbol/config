{
  fetchFromGitHub,
  glib,
  lib,
  libxkbcommon,
  pango,
  pkg-config,
  rustPlatform,
  ...
}:
rustPlatform.buildRustPackage rec {
  pname = "wayscriber";
  version = "0.7.0";

  src = fetchFromGitHub {
    owner = "devmobasa";
    repo = "wayscriber";
    rev = "v${version}";
    hash = "sha256-BV87dBnKmPFCwKOBGEH/BS36NFkqXRecxVkBT+7HKDE=";
  };

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    pango
    glib
    libxkbcommon
  ];

  cargoHash = "sha256-a1Bb5Y37RBQJnGnqXNWV54BBAqeLlm5SxKHsODfNHww=";

  meta = with lib; {
    description = "Live overlay for drawing, annotating, hiding text, and capturing screenshots on Wayland. Can be used as whiteboard or blackboard. Highly customisable.";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "wayscriber";
  };
}
