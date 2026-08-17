#!/bin/bash
# waybar-timer.sh — flexible countdown timer module for Waybar
#
# Usage:
#   waybar-timer.sh status              -> JSON for waybar "exec"
#   waybar-timer.sh start [DURATION] [LABEL]
#                                        -> starts immediately; if DURATION
#                                           omitted, pops a rofi/zenity prompt
#   waybar-timer.sh click               -> smart button (see below)
#   waybar-timer.sh scroll-up           -> increase by current step
#   waybar-timer.sh scroll-down         -> decrease by current step
#   waybar-timer.sh toggle-step         -> switch step between 1m and 10s
#   waybar-timer.sh cancel              -> stops and clears everything
#   waybar-timer.sh pause / resume / toggle-pause
#
# DURATION formats for `start`: "10" (bare number = minutes), "10m",
# "1h30m", "90s", "1:30:00" (h:m:s)
#
# Workflow: while idle, scroll to STAGE a duration (nothing runs yet).
# Left-click starts the staged duration. While running/paused, scroll
# adjusts the live timer directly, and left-click pauses/resumes.
# Middle-click toggles the scroll step between 1 minute and 10 seconds.

set -uo pipefail

STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}"
TIMER_FILE="$STATE_DIR/waybar_timer_end"
PAUSE_FILE="$STATE_DIR/waybar_timer_paused"
LABEL_FILE="$STATE_DIR/waybar_timer_label"
STAGE_FILE="$STATE_DIR/waybar_timer_stage"
STEP_FILE="$STATE_DIR/waybar_timer_step"
RINGING_FILE="$STATE_DIR/waybar_timer_ringing"
RING_PID_FILE="$STATE_DIR/waybar_timer_ring_pid"

# Sound played when the timer finishes. Override with:
#   WAYBAR_TIMER_SOUND=/path/to/sound.oga waybar-timer.sh status
# or just edit the default path below.
SOUND="${WAYBAR_TIMER_SOUND:-/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga}"
RING_INTERVAL=3   # seconds between repeats while ringing

notify() { command -v notify-send >/dev/null 2>&1 && notify-send "$@"; }

play_sound_once() {
  if [ -f "$SOUND" ] && command -v paplay >/dev/null 2>&1; then
    paplay "$SOUND" >/dev/null 2>&1
  elif [ -f "$SOUND" ] && command -v pw-play >/dev/null 2>&1; then
    pw-play "$SOUND" >/dev/null 2>&1
  elif [ -f "$SOUND" ] && command -v ffplay >/dev/null 2>&1; then
    ffplay -nodisp -autoexit -loglevel quiet "$SOUND" >/dev/null 2>&1
  elif [ -f "$SOUND" ] && command -v mpv >/dev/null 2>&1; then
    mpv --no-video --really-quiet "$SOUND" >/dev/null 2>&1
  elif [ -f "$SOUND" ] && command -v aplay >/dev/null 2>&1; then
    aplay -q "$SOUND" >/dev/null 2>&1
  elif command -v canberra-gtk-play >/dev/null 2>&1; then
    canberra-gtk-play -i alarm-clock-elapsed >/dev/null 2>&1
  else
    printf '\a'   # terminal bell as last resort
  fi
}

# Repeats the sound every RING_INTERVAL seconds until RINGING_FILE is
# removed (by stop_ringing / click), so an alarm can't be missed.
start_ringing() {
  touch "$RINGING_FILE"
  (
    while [ -f "$RINGING_FILE" ]; do
      play_sound_once
      sleep "$RING_INTERVAL"
    done
  ) &
  disown
  echo $! > "$RING_PID_FILE"
}

stop_ringing() {
  if [ -f "$RING_PID_FILE" ]; then
    local pid; pid=$(cat "$RING_PID_FILE")
    pkill -P "$pid" >/dev/null 2>&1   # kill whatever player is mid-playback
    kill "$pid" >/dev/null 2>&1
  fi
  rm -f "$RINGING_FILE" "$RING_PID_FILE"
}

fmt() {
  local s=$1
  printf "%02d:%02d:%02d" $((s/3600)) $((s%3600/60)) $((s%60))
}

duration_to_seconds() {
  local input=$1
  if [[ "$input" =~ ^[0-9]+$ ]]; then
    echo $(( input * 60 ))   # bare number = minutes
    return
  fi
  if [[ "$input" =~ ^([0-9]+):([0-9]+)(:([0-9]+))?$ ]]; then
    local h=${BASH_REMATCH[1]} m=${BASH_REMATCH[2]} s=${BASH_REMATCH[4]:-0}
    echo $(( h*3600 + m*60 + s ))
    return
  fi
  local h=0 m=0 s=0
  [[ "$input" =~ ([0-9]+)h ]] && h=${BASH_REMATCH[1]}
  [[ "$input" =~ ([0-9]+)m ]] && m=${BASH_REMATCH[1]}
  [[ "$input" =~ ([0-9]+)s ]] && s=${BASH_REMATCH[1]}
  echo $(( h*3600 + m*60 + s ))
}

get_step() {
  cat "$STEP_FILE" 2>/dev/null || echo 60
}

toggle_step() {
  local cur; cur=$(get_step)
  if [ "$cur" -eq 60 ]; then echo 10 > "$STEP_FILE"; else echo 60 > "$STEP_FILE"; fi
}

# start_seconds SECS [LABEL] — starts the real countdown right now
start_seconds() {
  local secs=$1 label=${2:-Timer}
  [ "$secs" -le 0 ] && exit 0
  echo $(( $(date +%s) + secs )) > "$TIMER_FILE"
  echo "$label" > "$LABEL_FILE"
  rm -f "$PAUSE_FILE" "$STAGE_FILE"
}

start() {
  local dur=${1:-10m} label=${2:-Timer} secs
  secs=$(duration_to_seconds "$dur")
  start_seconds "$secs" "$label"
}

cancel() {
  stop_ringing
  rm -f "$TIMER_FILE" "$PAUSE_FILE" "$LABEL_FILE" "$STAGE_FILE"
}

pause() {
  [ -f "$TIMER_FILE" ] || exit 0
  [ -f "$PAUSE_FILE" ] && exit 0
  local end now
  end=$(cat "$TIMER_FILE")
  now=$(date +%s)
  echo $(( end - now )) > "$PAUSE_FILE"
}

resume() {
  [ -f "$PAUSE_FILE" ] || exit 0
  local remaining; remaining=$(cat "$PAUSE_FILE")
  echo $(( $(date +%s) + remaining )) > "$TIMER_FILE"
  rm -f "$PAUSE_FILE"
}

toggle_pause() {
  if [ -f "$PAUSE_FILE" ]; then resume; else pause; fi
}

# scroll_adjust DELTA_SECONDS (signed) — routes to stage, paused, or
# running timer depending on current state, clamped at 0.
scroll_adjust() {
  [ -f "$RINGING_FILE" ] && exit 0   # ignore scroll while alarm is sounding
  local delta=$1
  if [ -f "$PAUSE_FILE" ]; then
    local remaining new; remaining=$(cat "$PAUSE_FILE")
    new=$(( remaining + delta )); [ "$new" -lt 0 ] && new=0
    echo "$new" > "$PAUSE_FILE"
  elif [ -f "$TIMER_FILE" ]; then
    local end now diff new; end=$(cat "$TIMER_FILE"); now=$(date +%s)
    diff=$(( end - now )); new=$(( diff + delta )); [ "$new" -lt 0 ] && new=0
    echo $(( now + new )) > "$TIMER_FILE"
  else
    local stage new; stage=$(cat "$STAGE_FILE" 2>/dev/null || echo 0)
    new=$(( stage + delta )); [ "$new" -lt 0 ] && new=0
    echo "$new" > "$STAGE_FILE"
  fi
}

scroll_up()   { scroll_adjust "$(get_step)"; }
scroll_down() { scroll_adjust "-$(get_step)"; }

# Smart single-button action:
#   staged duration set  -> start it
#   paused               -> resume
#   running              -> pause
#   nothing set          -> prompt for manual entry
click() {
  if [ -f "$RINGING_FILE" ]; then
    stop_ringing
  elif [ -f "$STAGE_FILE" ] && [ "$(cat "$STAGE_FILE")" -gt 0 ]; then
    start_seconds "$(cat "$STAGE_FILE")"
  elif [ -f "$PAUSE_FILE" ]; then
    resume
  elif [ -f "$TIMER_FILE" ]; then
    pause
  else
    prompt_start
  fi
}

prompt_start() {
  local dur
  if command -v rofi >/dev/null 2>&1; then
    dur=$(rofi -dmenu -p "Timer (e.g. 10m, 1h30m)")
  elif command -v zenity >/dev/null 2>&1; then
    dur=$(zenity --entry --title="Timer" --text="Duration (e.g. 10m, 1h30m):")
  else
    notify "Timer" "Install rofi or zenity to use the prompt, or run: waybar-timer.sh start 10m"
    exit 1
  fi
  [ -n "${dur:-}" ] && start "$dur"
}

status() {
  local step; step=$(get_step)
  local step_label="1m"; [ "$step" -eq 10 ] && step_label="10s"

  if [ -f "$RINGING_FILE" ]; then
    local label; label=$(cat "$LABEL_FILE" 2>/dev/null || echo Timer)
    printf '{"text":"🔔 %s","tooltip":"%s finished! Left click to silence","class":"alarm"}\n' "$label" "$label"
    return
  fi

  if [ -f "$PAUSE_FILE" ]; then
    local remaining label
    remaining=$(cat "$PAUSE_FILE")
    label=$(cat "$LABEL_FILE" 2>/dev/null || echo Timer)
    printf '{"text":"⏸ %s","tooltip":"%s paused – %s left\\nLeft click: resume · Scroll ±%s\\nMiddle click: step\\nRight click: cancel","class":"paused"}\n' \
      "$(fmt "$remaining")" "$label" "$(fmt "$remaining")" "$step_label"
    return
  fi

  if [ -f "$TIMER_FILE" ]; then
    local end now diff label
    end=$(cat "$TIMER_FILE")
    now=$(date +%s)
    diff=$(( end - now ))
    label=$(cat "$LABEL_FILE" 2>/dev/null || echo Timer)

    if [ "$diff" -le 0 ]; then
      rm -f "$TIMER_FILE" "$PAUSE_FILE" "$STAGE_FILE"   # keep LABEL_FILE for the alarm
      notify "⏰ $label finished!"
      start_ringing
      printf '{"text":"🔔 %s","tooltip":"%s finished! Left click to silence","class":"alarm"}\n' "$label" "$label"
    else
      local cls="running"
      [ "$diff" -le 60 ] && cls="urgent"
      printf '{"text":"⏱ %s","tooltip":"%s\\nLeft click: pause · Scroll ±%s\\nMiddle click: step\\nRight click: cancel","class":"%s"}\n' \
        "$(fmt "$diff")" "$label" "$step_label" "$cls"
    fi
    return
  fi

  if [ -f "$STAGE_FILE" ] && [ "$(cat "$STAGE_FILE")" -gt 0 ]; then
    local staged; staged=$(cat "$STAGE_FILE")
    printf '{"text":"⏱ %s ●","tooltip":"Staged, not started – Left click: start\\nScroll ±%s · Middle click: step\\nRight click: clear","class":"staged"}\n' \
      "$(fmt "$staged")" "$step_label"
    return
  fi

  printf '{"text":"⏱ --:--","tooltip":"No timer\\nLeft click: type a duration\\nScroll: stage a duration (±%s)\\nMiddle click: step\\nRight click: cancel","class":"idle"}\n' \
    "$step_label"
}

case "${1:-status}" in
  start)
    shift
    if [ -n "${1:-}" ]; then start "$@"; else prompt_start; fi
    ;;
  cancel) cancel ;;
  pause) pause ;;
  resume) resume ;;
  toggle-pause) toggle_pause ;;
  toggle-step) toggle_step ;;
  scroll-up) scroll_up ;;
  scroll-down) scroll_down ;;
  click) click ;;
  status) status ;;
  *)
    echo "Usage: $0 {start [duration] [label]|click|scroll-up|scroll-down|toggle-step|cancel|pause|resume|toggle-pause|status}"
    exit 1
    ;;
esac
