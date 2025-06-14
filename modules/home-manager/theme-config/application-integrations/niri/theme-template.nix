lib: palette:
with lib;
  {
    active-border ? palette.semantic.accent1,
    inactive-border ? palette.semantic.accent2,
  }: {
    layout = {
      border = {
        enable = mkForce true;
        width = mkForce 2;
        active = mkForce {
          color = "#${active-border}";
        };
        inactive = mkForce {
          color = "#${inactive-border}";
        };
      };
      focus-ring.enable = mkForce false;
    };
  }
