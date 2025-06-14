#!/usr/bin/env sh

# set variables
ConfDir="${XDG_CONFIG_HOME:-$HOME/.config}/rofi"
RofiConf="$ConfDir/themeselect.rasi"
RofiStyle="$ConfDir/styles"
Rofilaunch="$ConfDir/config.style.rasi"

source compositor.sh

size=$(echo "$x_monres * 0.17" | bc)

# set rofi override
export elem_border_radius=$((border_radius * 5))
export icon_border_radius=$((elem_border_radius - 5))

export r_override="element{border-radius:${elem_border_radius}px;} element-icon{border-radius:${icon_border_radius}px;size:${size}px;}"

# TODO: this string can probably be pre-computed in Nix
# launch rofi menu
RofiSel=$(ls $RofiStyle/style_*.rasi | awk -F '/' '{print $NF}' | cut -d '.' -f 1 | while read rstyle; do
  echo -en "$rstyle\x00icon\x1f$RofiStyle/${rstyle}.png\n"
done | rofi -dmenu -theme-str "${r_override}" -config $RofiConf)

# apply rofi style
if [ ! -z $RofiSel ]; then
  rm $Rofilaunch
  ln -s $RofiStyle/$RofiSel.rasi $Rofilaunch
  dunstify "t1" -a " ${RofiSel} applied..." -i "$RofiStyle/$RofiSel.png" -r 91190 -t 2200
fi
