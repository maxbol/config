lib: palette:
with lib;
  {
    active-border ? palette.semantic.overlay,
    inactive-border ? palette.semantic.surface,
    screencast-border ? palette.colors.green,
  }: {
    layout = let
      gapSize = 0;
      # topOuterGapSize = 5;
      # topStrutSize = topOuterGapSize - gapSize;
    in {
      gaps = gapSize;
      # struts = {
      #   top = topStrutSize;
      # };
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
