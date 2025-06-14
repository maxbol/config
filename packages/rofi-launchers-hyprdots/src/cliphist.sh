#!/usr/bin/env sh

CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/rofi"
roconf="$CONF_DIR/clipboard.rasi"

source compositor.sh

# set position
#!base on $HOME/.config/rofi/clipboard.rasi
clip_h=$(cat $CONF_DIR/clipboard.rasi | awk '/window {/,/}/' | awk '/height:/ {print $2}' | awk -F "%" '{print $1}')
clip_w=$(cat $CONF_DIR/clipboard.rasi | awk '/window {/,/}/' | awk '/width:/ {print $2}' | awk -F "%" '{print $1}')

# Multiply before dividing to avoid losing precision due to integer division
clip_w=$((x_monres * clip_w / 100))
clip_h=$((y_monres * clip_h / 100))
max_x=$((x_monres - clip_w - 5))  #offset of 5 for gaps
max_y=$((y_monres - clip_h - 15)) #offset of 15 for gaps

pos=""
if [[ "$compositor" == "hyprland" ]]; then
  x_offset=-15 #* Cursor spawn position on clipboard
  y_offset=210 #* To point the Cursor to the 1st and 2nd latest word

  x_cur=$((x_cur - x_offset))
  y_cur=$((y_cur - y_offset))
  #
  x_cur=$((x_cur < 0 ? 0 : (x_cur > max_x ? max_x : x_cur)))
  y_cur=$((y_cur < 0 ? 0 : (y_cur > max_y ? max_y : y_cur)))

  pos="window {location: north west; x-offset: ${x_cur}px; y-offset: ${y_cur}px;}" #! I just Used the old pos function
fi

# read hypr theme border
wind_border=$((border_radius * 3 / 2))
elem_border=$([ $border_radius -eq 0 ] && echo "5" || echo $border_radius)
r_override="window {border: ${border_width}px; border-radius: ${wind_border}px;} entry {border-radius: ${elem_border}px;} element {border-radius: ${elem_border}px;}"

# read hypr font size
fnt_override=$(dconf read /org/gnome/desktop/interface/monospace-font-name | awk '{gsub(/'\''/,""); print $NF}')
fnt_override="configuration {font: \"JetBrainsMono Nerd Font ${fnt_override}\";}"

# clipboard action

case $1 in
c)
  cliphist list | rofi -dmenu -theme-str "entry { placeholder: \"Copy...\";} ${pos} ${r_override}" -theme-str "${fnt_override}" -config $roconf | cliphist decode | wl-copy
  ;;
d)
  cliphist list | rofi -dmenu -theme-str "entry { placeholder: \"Delete...\";} ${pos} ${r_override}" -theme-str "${fnt_override}" -config $roconf | cliphist delete
  ;;
w)
  if [ $(echo -e "Yes\nNo" | rofi -dmenu -theme-str "entry { placeholder: \"Clear Clipboard History?\";} ${pos} ${r_override}" -theme-str "${fnt_override}" -config $roconf) == "Yes" ]; then
    cliphist wipe
  fi
  ;;
*)
  echo -e "cliphist.sh [action]"
  echo "c :  cliphist list and copy selected"
  echo "d :  cliphist list and delete selected"
  echo "w :  cliphist wipe database"
  exit 1
  ;;
esac
