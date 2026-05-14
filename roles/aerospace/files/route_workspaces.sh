#!/usr/bin/env bash
# Re-pins workspaces to their preferred monitors and refreshes sketchybar after
# a display change. AeroSpace's force-assignment is supposed to re-apply on
# monitor change, but in practice workspaces stay on whichever monitor they
# migrated to when displays disappeared — so we re-pin them explicitly here.
#
# Also explicitly rewrites each sketchybar space item's `display=N` binding to
# match the current monitor layout. A plain `sketchybar --reload` races
# AeroSpace's own re-pin and leaves spaces stuck on monitors that no longer
# exist (e.g. ws 4-6 showing as `display=2` after dropping back to one screen).
#
# Finally, restores window placement from the snapshot maintained by
# window_state_watcher.sh — macOS shuffles windows when a display goes away
# and AeroSpace can end up consolidating them onto whichever workspace is
# active on the surviving monitor (usually 1).
#
# Invoked from aerospace's after-startup-command and from sketchybar's
# display_change event.

set -eu

# Serialize against rapid display_change events. macOS fires several in a row
# while monitors are settling.
exec 9> "/tmp/aerospace_route_workspaces.lock"
flock 9

# Give macOS a moment to finish updating display info before we query it.
sleep 1

monitors=$(aerospace list-monitors --format "%{monitor-id}|%{monitor-name}")

find_monitor() {
  echo "$monitors" | awk -F'|' -v p="$1" '$2 ~ p { print $1; exit }'
}

dell_main=$(find_monitor 'DELL U3223QE \(2\)')
dell_secondary=$(find_monitor 'DELL U3223QE \(1\)')
laptop=$(find_monitor 'Built-in Retina Display')

assign() {
  local ws="$1"
  shift
  for target in "$@"; do
    [ -n "$target" ] || continue
    aerospace move-workspace-to-monitor --workspace "$ws" "$target" 2>/dev/null && return
  done
}

# Workspaces 1-3: prefer DELL(2), fall back to laptop, then DELL(1).
for ws in 1 2 3; do assign "$ws" "$dell_main" "$laptop" "$dell_secondary"; done
# Workspaces 4-6: prefer DELL(1), fall back to DELL(2), then laptop.
for ws in 4 5 6; do assign "$ws" "$dell_secondary" "$dell_main" "$laptop"; done
# Workspaces 7-9: prefer laptop, fall back to DELL(2), then DELL(1).
for ws in 7 8 9; do assign "$ws" "$laptop" "$dell_main" "$dell_secondary"; done

# Let AeroSpace finish applying the re-pin before we read state back.
sleep 1

# Sketchybar enumerates displays main-first (CGGetActiveDisplayList order):
# main → display 1, then non-main monitors left-to-right → 2, 3, ...
# Build the same monitor-id → sketchybar-display mapping that sketchybarrc
# computes at init time, then rewrite each space item's binding from it.
declare -A monitor_display
idx=1
while read -r mid; do
  [ -n "$mid" ] || continue
  monitor_display[$mid]=$idx
  idx=$((idx + 1))
done < <(
  aerospace list-monitors --format "%{monitor-id}|%{monitor-appkit-nsscreen-screens-id}" \
    | awk -F'|' '$2 == 1 { print $1 }
                 $2 != 1 { non_main = non_main $1 "\n" }
                 END { printf "%s", non_main }'
)

while IFS='|' read -r ws mid; do
  display=${monitor_display[$mid]:-}
  [ -n "$display" ] || continue
  sketchybar --set "space.$ws" display="$display" >/dev/null 2>&1 || true
done < <(aerospace list-workspaces --all --format "%{workspace}|%{monitor-id}")

# Restore window placement from the watcher's snapshot. The watcher pauses
# writes while the monitor count is in flux, so this file reflects the layout
# from just before the disconnect/reconnect.
state_file="/tmp/aerospace_window_state.txt"
if [ -r "$state_file" ]; then
  current=$(aerospace list-windows --all --format "%{window-id}|%{workspace}")
  while IFS='|' read -r wid want_ws; do
    [ -n "$wid" ] && [ -n "$want_ws" ] || continue
    have_ws=$(printf '%s\n' "$current" | awk -F'|' -v w="$wid" '$1 == w { print $2; exit }')
    [ -n "$have_ws" ] || continue                  # window no longer exists
    [ "$have_ws" = "$want_ws" ] && continue        # already in place
    aerospace move-node-to-workspace --window-id "$wid" "$want_ws" 2>/dev/null || true
  done < "$state_file"
fi
