#!/bin/bash

# Workspace indicator script
# Updates the workspace ovals based on current AeroSpace workspace

FOCUSED_WORKSPACE=$(aerospace list-workspaces --focused 2>/dev/null)

# Get workspace visible on each monitor
MONITOR_WORKSPACES=$(aerospace list-workspaces --monitor all --visible 2>/dev/null)

# If still no workspace, default to 1
if [ -z "$FOCUSED_WORKSPACE" ]; then
  FOCUSED_WORKSPACE="1"
fi

# Update all workspace indicators
for i in {1..4}; do
  if [ "$i" = "$FOCUSED_WORKSPACE" ]; then
    # Focused workspace - wide and bright
    sketchybar --animate tanh 8 \
               --set workspace_$i width=24 \
               background.color=0xffffffff
  elif echo "$MONITOR_WORKSPACES" | grep -qx "$i"; then
    # Visible on another monitor - wide but dimmed
    sketchybar --animate tanh 8 \
               --set workspace_$i width=24 \
               background.color=0x66ffffff
  else
    # Not visible - narrow
    sketchybar --animate tanh 8 \
               --set workspace_$i width=12 \
               background.color=0xffffffff
  fi
done