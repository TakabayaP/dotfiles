#!/usr/bin/env bash

PERCENTAGE="$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)"
CHARGING="$(pmset -g batt | grep 'AC Power')"

if [ "$CHARGING" != "" ]; then
  ICON="󰂄"
else
  ICON="󰁹"
fi

sketchybar --set "$NAME" icon="$ICON" label="${PERCENTAGE}%"
