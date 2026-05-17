#!/bin/bash
set -euo pipefail

ALARM_TIME="15:30"
SOUND="/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"

notify() {
    hyprctl notify 1 4000 "rgb(cdd6f4)" "$1"
}

notify_urgent() {
    hyprctl notify 3 6000 "rgb(f38ba8)" "$1"
}

echo "⏰ Alarm set for $ALARM_TIME"

while true; do
    CURRENT_TIME=$(date +"%H:%M")

    if [[ "$CURRENT_TIME" == "$ALARM_TIME" ]]; then
        notify_urgent "⏰ ALARM: Time's up!"
        paplay "$SOUND"
        break
    fi

    sleep 5
done
