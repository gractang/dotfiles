#!/usr/bin/env bash
# Continuously snapshots window-to-workspace mapping for route_workspaces.sh
# to restore from after a display change. Skips writes while the monitor
# count is changing so the snapshot preserves the pre-change layout.
#
# Single-instance via flock. Launched from aerospace.toml after-startup-command.

set -eu

state_file="/tmp/aerospace_window_state.txt"
count_file="/tmp/aerospace_monitor_count.txt"
self_lock="/tmp/aerospace_window_state_watcher.lock"
route_lock="/tmp/aerospace_route_workspaces.lock"
interval=3

exec 8> "$self_lock"
flock -n 8 || exit 0

trap 'rm -f "$state_file.tmp"' EXIT

while :; do
  current_count=$(aerospace list-monitors --format "%{monitor-id}" 2>/dev/null | wc -l | tr -d ' ')
  last_count=$(cat "$count_file" 2>/dev/null || echo "")

  # Snapshot only when:
  #   1. Monitor count is unchanged from last iteration. If it just changed,
  #      the prior snapshot survives for route_workspaces.sh to restore from.
  #   2. route_workspaces.sh isn't running. Otherwise we'd race it and capture
  #      its intermediate (collapsed) state, overwriting the good snapshot
  #      before it gets a chance to restore.
  if [ -n "$last_count" ] && [ "$current_count" = "$last_count" ]; then
    (
      flock -n 7 || exit 1
      aerospace list-windows --all --format "%{window-id}|%{workspace}" 2>/dev/null \
        > "$state_file.tmp" \
        && mv "$state_file.tmp" "$state_file"
    ) 7> "$route_lock" || true
  fi

  printf '%s' "$current_count" > "$count_file"
  sleep "$interval"
done
