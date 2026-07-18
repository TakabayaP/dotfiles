#!/usr/bin/env bash

if [ -z "$FOCUSED_WORKSPACE" ]; then
  exit 0
fi

ACTIVE_COLOR="0xffcdd6f4"
INACTIVE_COLOR="0xff6c7086"
args=()

for i in $(seq 1 10); do
  if [ "$i" = "$FOCUSED_WORKSPACE" ]; then
    args+=(--set "space.$i" background.drawing=on icon.color="$ACTIVE_COLOR")
  else
    args+=(--set "space.$i" background.drawing=off icon.color="$INACTIVE_COLOR")
  fi
done

sketchybar "${args[@]}"
