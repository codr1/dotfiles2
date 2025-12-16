#!/bin/bash

entries="Logout\nLock\nSuspend\nReboot\nShutdown"

selected=$(echo -e $entries | wofi --dmenu --cache-file /dev/null -p "Power Menu")

case $selected in
    Logout)
        swaymsg exit;;
    Lock)
        swaylock;;
    Suspend)
        systemctl suspend;;
    Reboot)
        systemctl reboot;;
    Shutdown)
        systemctl poweroff;;
esac
