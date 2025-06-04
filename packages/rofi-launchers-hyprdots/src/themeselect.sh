#!/usr/bin/env sh

# set variables
CONF="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}"
RofiConf="$CONF/rofi/themeselect.rasi"

# compositor specific info
if [[ ! -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
  x_monres=$(hyprctl -j monitors | jq '.[] | select(.focused==true) | .width')
  monitor_scale=$(hyprctl -j monitors | jq '.[] | select (.focused == true) | .scale')
  border=$(hyprctl -j getoption decoration:rounding | jq '.int')
elif [[ ! -z "${NIRI_SOCKET:-}" ]]; then
  x_monres=$(niri msg -j focused-output | jq '.logical.width')
  monitor_scale=$(niri msg -j focused-output | jq '.logical.scale')
  border=1 # // TODO(2025-06-02, Max Bolotin): Let's see if we can get this directly from the config file
else
  echo "Error getting layout info: No compositor running"
  exit 1
fi

# scale for monitor x res
x_monres=$(echo "$x_monres * 17 / $monitor_scale" | bc)

# set rofi override
elem_border=$((border * 5))
icon_border=$((elem_border - 5))
r_override="element{border-radius:${elem_border}px;} element-icon{border-radius:${icon_border}px;size:${x_monres}px;}"

echo "foo"

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

echo "ThemeSel: $ThemeSel"

# apply theme
if [ ! -z $ThemeSel ]; then
  chromactl activate-theme "$ThemeSel"
  dunstify "t1" -a " ${ThemeSel}" -i "$CONF/dunst/icons/hyprdots.png" -r 91190 -t 2200
fi
