{
  stdenv,
  fetchFromGitHub,
  fetchYarnDeps,
  yarnConfigHook,
  yarnInstallHook,
  nodejs,
  lib,
  ...
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "synp";
  version = "1.9.13";

  src = fetchFromGitHub {
    owner = "imsnif";
    repo = "synp";
    rev = "v${finalAttrs.version}";
    sha256 = "sha256-7FTpixi0EpRk/JuFhbZP666//4o6/1qODgAteZST3RM=";
  };

  offlineCache = fetchYarnDeps {
    yarnLock = "${finalAttrs.src}/yarn.lock";
    hash = "sha256-40EEAgYC1wjZgqkfd0nWZGVwQHMS8b06juAgWYfFy00=";
  };

  nativeBuildInputs = [
    yarnConfigHook
    yarnInstallHook
    nodejs
  ];

  meta = {
    description = "Convert yarn.lock to package-lock.json and vice versa.";
    homepage = "https://github.com/imsnif/synp";
    license = lib.licenses.mit;
    mainProgram = "synp";
  };
})
