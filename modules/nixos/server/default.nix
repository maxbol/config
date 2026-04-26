{lib-mine, ...}:
lib-mine.barrelGroup {
  here = ./.;
  path = "features.server";
  submodules = [
    "kubernetes"
  ];
}
