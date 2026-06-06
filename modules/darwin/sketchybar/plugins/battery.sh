#!/usr/bin/env bash

PMSET_OUTPUT=$(pmset -g batt)
PERCENTAGE=$(echo "$PMSET_OUTPUT" | grep -Eo "[0-9]+%" | cut -d% -f1)
CHARGING=$(echo "$PMSET_OUTPUT" | grep 'AC Power')

if [ -n "$CHARGING" ]; then
  ICON="󰂄"
  COLOR="0xffa6e3a1"
elif [ "$PERCENTAGE" -ge 80 ]; then
  ICON="󰂁"
  COLOR="0xffa6e3a1"
elif [ "$PERCENTAGE" -ge 60 ]; then
  ICON="󰁿"
  COLOR="0xffa6e3a1"
elif [ "$PERCENTAGE" -ge 40 ]; then
  ICON="󰁽"
  COLOR="0xfff9e2af"
elif [ "$PERCENTAGE" -ge 20 ]; then
  ICON="󰁻"
  COLOR="0xfff9e2af"
else
  ICON="󰂎"
  COLOR="0xfff38ba8"
fi

sketchybar --set "$NAME" icon="$ICON" icon.color="$COLOR" label="${PERCENTAGE}%"
