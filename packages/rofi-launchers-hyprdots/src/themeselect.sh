#!/usr/bin/env sh

# set variables
CONF="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}"
RofiConf="$CONF/rofi/themeselect.rasi"

source compositor.sh

size=$(echo "$x_monres * 0.17" | bc)

# set rofi override
export elem_border_radius=$((border_radius * 5))
export icon_border_radius=$((elem_border_radius - 5))

export r_override="element{border-radius:${elem_border_radius}px;} element-icon{border-radius:${icon_border_radius}px;size:${size}px;}"

# launch rofi menu
ThemeSel=$(jq -r '.[]' "$CONF/chroma/themes.json" | while read THEME; do
  if [ -e "$STATE/swim/$THEME/wallpaper" ]; then
    WP=$(readlink "$STATE/swim/$THEME/wallpaper")
  else
    WP=$(find "$CONF/chroma/themes/$THEME/swim/wallpapers/" -type f | head -n 1)
  fi

  CACHE_DIR="$(nailgun thumbnail-for-wp "$WP")"

  echo -en "$THEME\x00icon\x1f$CACHE_DIR/thumb\n"
done | rofi -dmenu -theme-str "${r_override}" -config $RofiConf -select "$(jq -r ".name" "$CONF/chroma/active/info.json")")

# apply theme
if [ ! -z $ThemeSel ]; then
  chromactl activate-theme "$ThemeSel"
  dunstify "t1" -a " ${ThemeSel}" -i "$CONF/dunst/icons/hyprdots.png" -r 91190 -t 2200
fi
