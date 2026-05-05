#!/bin/bash

LOGFILE="$HOME/network_log.txt"
TARGET="8.8.8.8"

echo "Network monitor started at $(date)" >> "$LOGFILE"

while true; do
    if ping -c 1 -W 2 $TARGET > /dev/null 2>&1; then
        STATUS="UP"
    else
        STATUS="DOWN"
    fi

    echo "$(date '+%Y-%m-%d %H:%M:%S') - $STATUS" >> "$LOGFILE"

    sleep 5
done
