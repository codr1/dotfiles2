#!/usr/bin/env bash

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Launch polybar on each monitor
for monitor in $(xrandr --query | grep " connected" | cut -d" " -f1); do
    MONITOR="$monitor" polybar -q main &
done

echo "Polybar launched..."
