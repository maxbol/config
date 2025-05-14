{lib-mine, ...}:
lib-mine.barrelGroup {
  here = ./.;
  path = "features.application-config";
  submodules = ["password-management"];
}
