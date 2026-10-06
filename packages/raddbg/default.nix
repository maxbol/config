{
  lib,
  llvmPackages,
  fetchFromGitHub,
  pkg-config,
  copyDesktopItems,
  makeDesktopItem,
  freetype,
  libglvnd,
  libx11,
  libxext,
  libxfixes,
  ...
}:
llvmPackages.stdenv.mkDerivation (finalAttrs: {
  pname = "raddbg";
  version = "0.9.29-alpha";

  src = fetchFromGitHub {
    owner = "EpicGames";
    repo = "raddebugger";
    rev = "v${finalAttrs.version}";
    hash = "sha256-IQNicRWKdIamDeQU1RRceRR2QgoUlomQYoeCgepO10w=";
  };

  nativeBuildInputs = [
    pkg-config
    copyDesktopItems
  ];

  buildInputs = [
    freetype
    libglvnd
    libx11
    libxext
    libxfixes
  ];

  # build.sh derives the version stamp from `git describe`, which has no
  # repository to look at here.
  postPatch = ''
    substituteInPlace build.sh \
      --replace-fail 'git_hash=$(git describe --always --dirty)' 'git_hash=v${finalAttrs.version}' \
      --replace-fail 'git_hash_full=$(git rev-parse HEAD)' 'git_hash_full=${finalAttrs.src.rev}'
  '';

  # `clang` and GNU `ar` instead of build.sh's `llvm-ar` default.
  buildPhase = ''
    runHook preBuild

    CC=clang AR=ar bash ./build.sh raddbg radbin radlink release

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 build/raddbg  -t $out/bin
    install -Dm755 build/radbin  -t $out/bin
    install -Dm755 build/radlink -t $out/bin
    install -Dm644 data/logo.png $out/share/icons/hicolor/256x256/apps/raddbg.png

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "raddbg";
      exec = "raddbg %f";
      icon = "raddbg";
      desktopName = "RAD Debugger";
      comment = "Native, user-mode, multi-process, graphical debugger";
      categories = ["Development" "Debugger"];
      terminal = false;
    })
  ];

  meta = {
    homepage = "https://github.com/EpicGames/raddebugger";
    description = "Native, user-mode, multi-process, graphical debugger";
    longDescription = ''
      The RAD Debugger is a native, user-mode, multi-process, graphical
      debugger. Linux x64 support is preliminary: fork/vfork debugging is
      unsupported, thread-local storage lookup assumes a matching libc, and
      binaries without .eh_frame_hdr can produce broken callstacks.
    '';
    license = lib.licenses.mit;
    mainProgram = "raddbg";
    platforms = ["x86_64-linux"];
  };
})
