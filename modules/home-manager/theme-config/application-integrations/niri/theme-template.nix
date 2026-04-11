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
      borderWidth = 2;
      strutSize = 0;
    in {
      gaps = gapSize;
      struts = {
        left = strutSize;
        right = strutSize;
        top = strutSize;
        bottom = strutSize;
        # left = -borderWidth;
        # right = -borderWidth;
        # bottom = -borderWidth;
        # top = -borderWidth;
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
        enable = mkForce false;
        # width = mkForce borderWidth;
        # active = mkForce {
        #   color = "#${active-border}";
        # };
        # inactive = mkForce {
        #   color = "#${inactive-border}";
        # };
      };
      focus-ring.enable = mkForce false;
    };
    window-rules = [
      {
        matches = [
          {
            is-focused = true;
          }
        ];
        excludes = [
          {
            is-active = true;
          }
        ];
        opacity = 0.99;
      }
      {
        excludes = [
          {
            is-active = true;
          }
          {
            is-focused = true;
          }
        ];
        opacity = 0.90;
      }
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
