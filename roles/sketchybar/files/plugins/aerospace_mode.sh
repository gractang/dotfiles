#!/usr/bin/env bash

MODE="${1:-main}"

case "$MODE" in
  move)
    LABEL="Move"
    COLOR="0xaa2d5a3f"
    BAR_COLOR="0x302d5a3f"
    ;;
  resize)
    LABEL="Resize"
    COLOR="0xaa5a4a1f"
    BAR_COLOR="0x305a4a1f"
    ;;
  join)
    LABEL="Join"
    COLOR="0xaa5a1f2a"
    BAR_COLOR="0x305a1f2a"
    ;;
  workspace)
    LABEL="Workspace"
    COLOR="0xaa3a2a5a"
    BAR_COLOR="0x303a2a5a"
    ;;
  *)
    LABEL="Main"
    COLOR="0x55000000"
    BAR_COLOR="0x40000000"
    ;;
esac

sketchybar --set mode_indicator label="$LABEL" label.color=0xffffffff background.color="$COLOR" \
           --bar color="$BAR_COLOR"
