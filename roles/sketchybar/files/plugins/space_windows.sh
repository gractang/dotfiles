#!/bin/bash

if [ "$SENDER" = "aerospace_workspace_change" ]; then
  workspaces=$(aerospace list-workspaces --format "%{id} %{workspace-is-visible}" | grep "true" | awk '{print $1}')

  # Also update the workspace we just left
  if [ -n "$PREV_WORKSPACE" ]; then
    workspaces="$workspaces $PREV_WORKSPACE"
  fi

  for workspace in $workspaces; do
    apps=$(aerospace list-windows --workspace "$workspace" | awk -F'|' '{gsub(/^ *| *$/, "", $2); print $2}')

    sketchybar --set space.$workspace drawing=on

    if [ "${apps}" != "" ]; then
      icon_strip=" "
      while read -r app; do
        icon_strip+=" $($CONFIG_DIR/plugins/icon_map_fn.sh "$app")"
      done <<<"${apps}"
      sketchybar --set space.$workspace label="$icon_strip"
    else
      sketchybar --set space.$workspace label=""
    fi
  done
fi
