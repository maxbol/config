lib: palette: {
  active-border ? palette.semantic.overlay,
  inactive-border ? palette.semantic.surface,
  urgent-border ? palette.colors.yellow,
  screencast-border ? palette.colors.green,
  active-tab ? palette.semantic.accent1,
  inactive-tab ? palette.semantic.overlay,
  urgent-tab ? palette.colors.yellow,
}: ''
  layout {
      tab-indicator {
          active-color "#${active-tab}"
          inactive-color "#${inactive-tab}"
          urgent-color "#${urgent-tab}"
      }
      // Colors only - whether borders and the focus ring show at all, and how
      // wide they are, is managed by dms.
      border {
          active-color "#${active-border}"
          inactive-color "#${inactive-border}"
          urgent-color "#${urgent-border}"
      }
      focus-ring {
          active-color "#${active-border}"
          inactive-color "#${inactive-border}"
          urgent-color "#${urgent-border}"
      }
  }

  window-rule {
      match is-window-cast-target=true
      border {
          active-color "#${screencast-border}"
          inactive-color "#${screencast-border}"
      }
  }
''
