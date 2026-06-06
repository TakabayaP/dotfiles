#!/usr/bin/env bash

PAGE_SIZE=$(sysctl -n hw.pagesize)
TOTAL_MEM=$(sysctl -n hw.memsize)

VMSTAT=$(vm_stat)
ACTIVE=$(echo "$VMSTAT" | awk '/Pages active/ {gsub(/\./,"",$3); print $3}')
WIRED=$(echo "$VMSTAT" | awk '/Pages wired/ {gsub(/\./,"",$4); print $4}')
COMPRESSED=$(echo "$VMSTAT" | awk '/Pages occupied by compressor/ {gsub(/\./,"",$5); print $5}')

USED_BYTES=$(( (ACTIVE + WIRED + COMPRESSED) * PAGE_SIZE ))
USED_GB=$(echo "$USED_BYTES" | awk "{printf \"%.0f\", \$1/1024/1024/1024}")
#TOTAL_GB=$(echo "$TOTAL_MEM" | awk "{printf \"%.0f\", \$1/1024/1024/1024}")
RATIO=$(echo "$USED_BYTES $TOTAL_MEM" | awk '{printf "%.2f", $1/$2}')

#sketchybar --set "$NAME" label="MEM ${USED_GB}/${TOTAL_GB}GB" --push "$NAME" "$RATIO"
sketchybar --set "$NAME" label="MEM ${USED_GB}GB" --push "$NAME" "$RATIO"
