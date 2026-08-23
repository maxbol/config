# Emits the Chroma theme list as JSON for the dms launcher plugin:
#   {"active": "<name>", "themes": [{"name": "...", "wallpaper": "/abs/path"}, ...]}
#
# The wallpaper is the one pinned for that theme if it is still present,
# otherwise the first one the theme ships. Pins are passed in as a JSON object
# of {"<theme>": "<filename>"} so that all filesystem lookups stay here; the
# plugin owns the pin state itself.

CHROMA_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/chroma"
PINS="${1-}"
[ -n "$PINS" ] || PINS='{}'

active=$(jq -r '.name // empty' "$CHROMA_DIR/active/info.json" 2>/dev/null || true)

# The chroma wallpapers integration exposes the images at `wallpapers/images`.
# The other two are older layouts, kept so a rollback to an earlier generation
# still shows thumbnails.
theme_wallpaper_dir() {
  for sub in wallpapers/images wallpapers/wallpapers swim/wallpapers; do
    if [ -d "$CHROMA_DIR/themes/$1/$sub" ]; then
      printf '%s\n' "$CHROMA_DIR/themes/$1/$sub"
      return
    fi
  done
}

jq -r '.[]' "$CHROMA_DIR/themes.json" | while IFS= read -r theme; do
  dir=$(theme_wallpaper_dir "$theme")
  wallpaper=""
  if [ -n "$dir" ]; then
    pinned=$(printf '%s' "$PINS" | jq -r --arg t "$theme" '.[$t] // empty')
    if [ -n "$pinned" ] && [ -f "$pinned" ]; then
      wallpaper="$pinned"
    elif [ -n "$pinned" ] && [ -f "$dir/${pinned##*/}" ]; then
      wallpaper="$dir/${pinned##*/}"
    else
      wallpaper=$(find -L "$dir" -maxdepth 1 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
        -o -iname '*.webp' -o -iname '*.avif' -o -iname '*.bmp' \) |
        sort | sed -n 1p)
    fi
  fi
  jq -n --arg name "$theme" --arg wallpaper "$wallpaper" '{name: $name, wallpaper: $wallpaper}'
done | jq -s --arg active "$active" '{active: $active, themes: .}'
