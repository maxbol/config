#!/usr/bin/env sh

swpy_dir="${XDG_CONFIG_DIR:-$HOME/.config}/swappy"
save_dir="${2:-${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots}"
save_file="$save_dir/$(date +'%y%m%d_%Hh%Mm%Ss_screenshot.png')"
temp_screenshot="/tmp/screenshot.png"

mkdir -p $save_dir

function print_error
{
cat << "EOF"
    ./screenshot.sh <action>
    ...valid actions are...
        p : print all screens
        s : snip current screen
        sf : snip current screen (frozen)
        m : print focused monitor
EOF
}

case $1 in
p)  # print all outputs
    grimblast copysave screen - && swappy -f - -o "$save_file" ;;
s)  # drag to manually snip an area / click on a window to print it
    grimblast copysave area $temp_screenshot && swappy -f $temp_screenshot ;;
sf)  # frozen screen, drag to manually snip an area / click on a window to print it
    grimblast --freeze copysave area - && swappy -f - -o "$save_file" ;;
m)  # print focused monitor
    grimblast copysave output - && swappy -f - -o "$save_file" ;;
*)  # invalid option
    print_error ;;
esac

if [ -f "$save_dir/$save_file" ] ; then
    notify-send "Grimblast" "Your snapshot has been saved." \
        -i video-x-generic \
        -a "Grimblast" \
        -t 7000 \
        -u normal \
        --action="scriptAction:-xdg-open $save_dir=Directory" \
        --action="scriptAction:-xdg-open $save_dir/$save_file=View"
fi

