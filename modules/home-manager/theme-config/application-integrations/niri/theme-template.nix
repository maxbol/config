lib: palette:
with lib;
  {
    active-border ? palette.semantic.accent1,
    inactive-border ? palette.semantic.text2,
    screencast-border ? palette.colors.green,
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
    window-rules = [
      {
        matches = [
          {
            is-window-cast-target = true;
          }
        ];
        border = {
          active.color = "#${screencast-border}";
          inactive.color = "#${screencast-border}";
        };
      }
    ];
  }
