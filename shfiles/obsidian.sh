#!/bin/bash

# Start Syncthing in background
syncthing --no-browser &
ST_PID=$!

# Open Obsidian
obsidian

# Kill Syncthing after Obsidian closes
kill $ST_PID
