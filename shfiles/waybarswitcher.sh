#!/bin/bash

STATE_FILE="/tmp/waybar_state"

# default state
if [ ! -f "$STATE_FILE" ]; then
    echo "default" > "$STATE_FILE"
fi

CURRENT=$(cat "$STATE_FILE")

# kill running waybar
pkill waybar

# small delay so process fully dies
sleep 0.2

if [ "$CURRENT" = "default" ]; then
    waybar \
        -c ~/.config/waybar/alt-config.jsonc \
        -s ~/.config/waybar/alt-style.css &

    echo "alt" > "$STATE_FILE"
else
    waybar \
        -c ~/.config/waybar/config.jsonc \
        -s ~/.config/waybar/style.css &

    echo "default" > "$STATE_FILE"
fi
