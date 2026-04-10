#!/bin/sh

if [ "$SENDER" = "front_app_switched" ]; then
  app=$(aerospace list-windows | awk -F'|' '$1 ~ /true/ { gsub(/^ *| *$/, "", $3); print $3 }')
  sketchybar --set "$NAME" label="$app"
fi
