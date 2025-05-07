{pkgs, ...}:
pkgs.writeTextFile {
  name = "runcached";
  destination = "/bin/runcached";
  executable = true;
  text = builtins.readFile ./runcached.zsh;
}
