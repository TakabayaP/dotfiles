#!/usr/bin/env bash

if [ "$SENDER" = "volume_change" ]; then
  VOLUME="$INFO"
else
  VOLUME="$(osascript -e 'output volume of (get volume settings)' 2>/dev/null)"
fi

if [ "$VOLUME" = "missing value" ] || [ -z "$VOLUME" ]; then
  VOLUME="--"
fi

DEVICE="$(system_profiler SPAudioDataType 2>/dev/null | awk '/^        [^ ].*:$/{device=$0} /Default Output Device: Yes/{print device; exit}' | sed 's/^[[:space:]]*//' | sed 's/:$//')"

if [ "$VOLUME" = "--" ]; then
  ICON="󰕾"
elif [ "$VOLUME" -eq 0 ] 2>/dev/null; then
  ICON="󰝟"
elif [ "$VOLUME" -lt 30 ]; then
  ICON="󰕿"
elif [ "$VOLUME" -lt 60 ]; then
  ICON="󰖀"
else
  ICON="󰕾"
fi

sketchybar --set "$NAME" icon="$ICON" label="${VOLUME}% ${DEVICE}"
