#!/usr/bin/env sh

roconf="${XDG_CONFIG_HOME:-$HOME/.config}/rofi/config.rasi"

# rofi action

case $1 in
# d) r_mode="drun" ;;
d) r_mode="combi -combi-modes window,drun -modes combi" ;;
w) r_mode="window" ;;
f) r_mode="filebrowser" ;;
h)
  echo -e "rofilaunch.sh [action]\nwhere action,"
  echo "d :  drun mode"
  echo "w :  window mode"
  echo "f :  filebrowser mode,"
  exit 0
  ;;
*) r_mode="drun" ;;
esac

source compositor.sh

wind_border=$((border_radius * 3))
elem_border=$([ $border_radius -eq 0 ] && echo "10" || echo $((border_radius * 2)))
r_override="window {border: ${border_width}px; border-radius: ${wind_border}px;} element {border-radius: ${elem_border}px;}"

# read hypr font size

fnt_override=$(dconf read /org/gnome/desktop/interface/monospace-font-name | awk '{gsub(/'\''/,""); print $NF}')
fnt_override="configuration {font: \"JetBrainsMono Nerd Font ${fnt_override}\";}"

# read hypr theme icon

icon_override=$(dconf read /org/gnome/desktop/interface/icon-theme | sed "s/'//g")
icon_override="configuration {icon-theme: \"${icon_override}\";}"

# launch rofi
if [[ "$compositor" == "hyprland" ]]; then
  # Assume uwsm
  rofi -show $r_mode -theme-str "${fnt_override}" -theme-str "${r_override}" -theme-str "${icon_override}" -config "${roconf}" -run-command "uwsm app -- {cmd}"
else
  echo "rofi -show $r_mode -theme-str \"${fnt_override}\" -theme-str \"${r_override}\" -theme-str \"${icon_override}\" -config \"${roconf}\" -run-command \"{cmd}\""
  rofi -show $r_mode -theme-str "${fnt_override}" -theme-str "${r_override}" -theme-str "${icon_override}" -config "${roconf}" -run-command "{cmd}"
fi
