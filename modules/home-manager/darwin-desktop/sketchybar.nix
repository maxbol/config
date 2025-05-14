{lib-mine, ...}:
lib-mine.mkFeature
"features.darwin-desktop.sketchybar"
{
  impure-config-management.config."sketchybar/sketchybarrc" = "config/sketchybar/sketchybarrc";
  impure-config-management.config."sketchybar/plugins" = "config/sketchybar/plugins";
}
