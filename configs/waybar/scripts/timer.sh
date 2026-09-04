#!/bin/bash
TIMER_FILE="/tmp/waybar_timer"

if [ ! -f "$TIMER_FILE" ]; then
  echo "⏱ --:--"
  exit 0
fi

END=$(cat "$TIMER_FILE")
NOW=$(date +%s)
DIFF=$((END - NOW))

if [ "$DIFF" -le 0 ]; then
  rm "$TIMER_FILE"
  notify-send "⏰ Timer finished!"
  echo "✅ Done!"
else
  printf "⏱ %02d:%02d:%02d\n" $((DIFF/3600)) $((DIFF%3600/60)) $((DIFF%60))
fi
