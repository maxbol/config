{lib-mine, ...}:
lib-mine.mkFeature "features.sysctl" {
  boot.kernel.sysctl = {
    "kernel.yama.ptrace_scope" = "1";
  };
}
