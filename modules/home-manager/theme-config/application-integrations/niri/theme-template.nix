lib: palette:
with lib;
  {
    active-border ? palette.semantic.overlay,
    inactive-border ? palette.semantic.surface,
    screencast-border ? palette.colors.green,
    active-tab ? palette.semantic.accent1,
    inactive-tab ? palette.semantic.overlay,
    urgent-tab ? palette.colors.yellow,
  }: {
    layout = let
      # strutSize = 10.;
      gapSize = 0;
      # topOuterGapSize = 5;
      # topStrutSize = topOuterGapSize - gapSize;
    in {
      gaps = gapSize;
      struts = {
        # left = strutSize - gapSize;
        # right = strutSize - gapSize;
        # top = strutSize;
        # bottom = strutSize;
      };
      # struts = {
      #   top = topStrutSize;
      # };
      tab-indicator = {
        active.color = "#${active-tab}";
        inactive.color = "#${inactive-tab}";
        urgent.color = "#${urgent-tab}";
      };
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
