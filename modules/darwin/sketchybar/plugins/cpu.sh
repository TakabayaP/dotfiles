#!/usr/bin/env bash

CPU=$(top -l 2 -n 0 | awk '/CPU usage/ {sum += $3 + $5; n++} END {if(n>0) printf "%.0f", sum/n; else print "0"}')
sketchybar --set "$NAME" label="CPU ${CPU}%" --push "$NAME" "$(echo "$CPU" | awk '{printf "%.2f", $1/100}')"
