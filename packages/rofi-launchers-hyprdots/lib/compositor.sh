#!/usr/bin/env sh

# compositor specific info
if [[ ! -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
  compositor="hyprland"
  focused_monitor=$(hyprctl -j monitors | jq '.[] | select(.focused=true)')
  cursor_pos=$(hyprctl -j cursorpos)
  x_monres=$(echo $focused_monitor | jq '.width')
  y_monres=$(echo $focused_monitor | jq '.height')
  x_pos=$(echo $focused_monitor | jq '.x')
  y_pos=$(echo $focused_monitor | jq '.y')
  x_cur=$(echo $cursor_pos | jq '.x')
  y_cur=$(echo $cursor_pos | jq '.y')
  x_cur=$(($x_cur - x_pos))
  y_cur=$(($x_cur - x_pos))
  monitor_scale=$(echo $focused_monitor | jq '.scale' | sed 's/\.//')
  border_radius=$(hyprctl -j getoption decoration:rounding | jq '.int')
  border_width=$(hyprctl -j getoption general:border_size | jq '.int')
  monitor_rot=$(echo $focused_monitor | jq '.transform')
  if [[ "$monitor_rot" == "1" || "$monitor_rot" == "3" || "$monitor_rot" == "5" || "$monitor_rot" == "7" ]]; then
    orientation="portrait"
  else
    orientation="landscape"
  fi
elif [[ ! -z "${NIRI_SOCKET:-}" ]]; then
  compositor="niri"
  focused_output=$(niri msg -j focused-output)
  x_monres=$(echo $focused_output | jq '.logical.width')
  y_monres=$(echo $focused_output | jq '.logical.height')
  x_pos=$(echo $focused_output | jq '.logical.x')
  y_pos=$(echo $focused_output | jq '.logical.y')
  # Niri IPC does not guarantee two digit precision for floats, so resorting to the sed trick above does not strictly work
  monitor_scale=$(echo $focused_output | jq '.logical.scale')
  monitor_scale=$(echo "scale=3; $monitor_scale * 100" | bc)
  # // TODO(2025-06-02, Max Bolotin): Let's see if we can get this directly from the config file
  border_radius=12
  border_width=2
  x_cur=0
  y_cur=0
  monitor_rot=$(echo $focused_output | jq '.logical.transform')
  if [[ "$monitor_rot" == "90" || "$monitor_rot" == "270" || "$monitor_rot" == "Flipped90" || "$monitor_rot" == "Flipped270" ]]; then
    orientation="portrait"
  else
    orientation="landscape"
  fi
else
  echo "Error getting layout info: No compositor running"
  exit 1
fi

if [ "$orientation" == "portrait" ]; then
  tempmon=$x_monres
  x_monres=$y_monres
  y_monres=$x_monres
fi

export x_monres=$(echo "$x_monres * 100 / $monitor_scale" | bc)
export y_monres=$(echo "$y_monres * 100 / $monitor_scale" | bc)

export x_cur
export y_cur

export monitor_scale
export monitor_rot
export border_radius
export border_width
export compositor
