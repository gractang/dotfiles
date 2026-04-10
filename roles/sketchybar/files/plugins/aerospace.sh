#!/usr/bin/env bash

if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
  sketchybar --set $NAME background.border_width=2 icon.color=0xffffffff label.color=0xffffffff
else
  sketchybar --set $NAME background.border_width=0 icon.color=0xbbffffff label.color=0xbbffffff
fi
