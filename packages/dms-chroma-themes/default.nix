{
  lib,
  stdenvNoCC,
  writeShellApplication,
  self,
  jq,
  coreutils,
  findutils,
  ...
}: let
  themeList = writeShellApplication {
    name = "chroma-theme-list";
    runtimeInputs = [jq coreutils findutils];
    text = builtins.readFile ./src/chroma-theme-list.sh;
  };
in
  stdenvNoCC.mkDerivation {
    name = "dms-chroma-themes";
    src = ./src;

    dontBuild = true;
    dontConfigure = true;

    installPhase = ''
      mkdir -p $out
      cp plugin.json ChromaThemes.qml ChromaWallpaperDaemon.qml $out/

      # The plugin runs as part of dms, whose PATH we do not control, so the
      # tools it shells out to are baked in.
      substituteInPlace $out/ChromaThemes.qml \
        --replace-fail "@chromactl@" "${lib.getExe self.chromactl}" \
        --replace-fail "@themeList@" "${lib.getExe themeList}"

      substituteInPlace $out/ChromaWallpaperDaemon.qml \
        --replace-fail "@themeList@" "${lib.getExe themeList}"
    '';

    meta = with lib; {
      description = "DankMaterialShell launcher plugin for switching Chroma themes";
      platforms = platforms.linux;
    };
  }
