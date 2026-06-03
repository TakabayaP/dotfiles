#!/usr/bin/env bash

if [ "$FOCUSED_WORKSPACE" != "" ]; then
  for i in $(seq 1 10); do
    if [ "$i" = "$FOCUSED_WORKSPACE" ]; then
      sketchybar --set "space.$i" background.drawing=on icon.color=0xffcdd6f4
    else
      sketchybar --set "space.$i" background.drawing=off icon.color=0xff6c7086
    fi
  done
fi
