#!/bin/bash

# Get the current opacity and clean it up
# We use 'cut' to just look at the first two characters (e.g., "0." or "1.")
current=$(hyprctl getoption decoration:active_opacity -j | jq -r ".float" | cut -c 1-3)

# If it starts with 1.0, it's solid. Change to transparent.
if [ "$current" == "1.0" ]; then
    hyprctl keyword decoration:active_opacity 0.9
    hyprctl keyword decoration:inactive_opacity 0.8
    echo "Switched to Transparent"
else
    # Otherwise, it's already transparent, so make it solid.
    hyprctl keyword decoration:active_opacity 1.0
    hyprctl keyword decoration:inactive_opacity 1.0
    echo "Switched to Solid"
fi
