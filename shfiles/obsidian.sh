#!/bin/bash
syncthing --no-browser &
ST_PID=$!

obsidian
# Obsidian closed — kill syncthing
kill $ST_PID 2>/dev/null
