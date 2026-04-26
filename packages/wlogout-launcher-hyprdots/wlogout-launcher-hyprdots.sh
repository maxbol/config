#!/usr/bin/env sh

# Check if wlogout is already running
if pgrep -x "wlogout" >/dev/null; then
  pkill -x "wlogout"
  exit 0
fi

# set file variables
export CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/wlogout"
wLayout="$CONF_DIR/layout_$1"
wlTmplt="$CONF_DIR/style_$1.css"

if [ ! -f "$wLayout" ] || [ ! -f "$wlTmplt" ]; then
  # if [ ! -f "$wLayout" ]; then
  echo "ERROR: Config $1 not found..."
  exit 1
fi

source compositor.sh

# scale config layout and style
case $1 in
1)
  wlColms=6
  export mgn=$(echo "$y_monres * 28 / $monitor_scale" | bc)
  export hvr=$(echo "$y_monres * 23 / $monitor_scale" | bc)
  ;;
2)
  wlColms=2
  export x_mgn=$(echo "$x_monres * 35 / $monitor_scale" | bc)
  export y_mgn=$(echo "$y_monres * 25 / $monitor_scale" | bc)
  export x_hvr=$(echo "$x_monres * 32 / $monitor_scale" | bc)
  export y_hvr=$(echo "$y_monres * 20 / $monitor_scale" | bc)
  ;;
esac

# scale font size
export fntSize=$(echo "$y_monres * 2 / 100" | bc)

# detect gtk system theme
# TODO: can this be pre-computed in Nix?
gtkMode=$(dconf read /org/gnome/desktop/interface/color-scheme | sed "s/'//g" | awk -F '-' '{print $2}')
BtnCol=$(if [ "$gtkMode" == "dark" ]; then (echo "white"); else (echo "black"); fi)
WindBg=$(if [ "$gtkMode" == "dark" ]; then (echo "rgba(0,0,0,0.5)"); else (echo "rgba(255,255,255,0.5)"); fi)
export BtnCol
export WindBg

export active_rad=$(echo "$border_radius * 5" | bc)
export button_rad=$(echo "$border_radius * 8" | bc)

# eval config files
wlStyle=$(envsubst <"$wlTmplt")

# launch wlogout
wlogout -b "$wlColms" -c 0 -r 0 -m 0 --layout "$wLayout" --css <(echo "$wlStyle") --protocol layer-shell
# wlogout -b "$wlColms" -c 0 -r 0 -m 0 --layout "$wLayout" --protocol layer-shell
