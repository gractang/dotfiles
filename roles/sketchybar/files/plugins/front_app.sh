#!/bin/sh

if [ "$SENDER" = "front_app_switched" ]; then
  app=$(aerospace list-windows --focused --format "%{app-name}")
  sketchybar --set "$NAME" label="$app"
fi
