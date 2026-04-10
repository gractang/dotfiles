#!/usr/bin/env bash

MODE="${1:-main}"

case "$MODE" in
  move)
    LABEL="Move"
    COLOR="0xffa6e3a1"
    BAR_COLOR="0x44a6e3a1"
    ;;
  resize)
    LABEL="Resize"
    COLOR="0xfff9e2af"
    BAR_COLOR="0x44f9e2af"
    ;;
  join)
    LABEL="Join"
    COLOR="0xfff38ba8"
    BAR_COLOR="0x44f38ba8"
    ;;
  workspace)
    LABEL="Workspace"
    COLOR="0xffcba6f7"
    BAR_COLOR="0x44cba6f7"
    ;;
  *)
    LABEL="Main"
    COLOR="0xff89b4fa"
    BAR_COLOR="0x40000000"
    ;;
esac

sketchybar --set mode_indicator label="$LABEL" label.color="$COLOR" \
           --bar color="$BAR_COLOR"
