#!/bin/sh

OUTPUT=$(system_profiler SPBluetoothDataType -json 2>/dev/null | python3 -c '
import json, sys

ICONS = {
    "Headphones": "󰋋",
    "Headset": "󰋋",
    "Keyboard": "󰌌",
    "Mouse": "󰍽",
    "Trackpad": "󰍽",
    "Gamepad": "󰊖",
}
DEFAULT = "󰂯"

data = json.load(sys.stdin)
devices = data.get("SPBluetoothDataType", [{}])[0].get("device_connected", [])

parts = []
for entry in devices:
    for name, info in entry.items():
        icon = ICONS.get(info.get("device_minorType", ""), DEFAULT)
        parts.append(f"{icon} {name}")

print("  ".join(parts))
' 2>/dev/null)

if [ -n "$OUTPUT" ]; then
  sketchybar --set "$NAME" icon="󰂯" label="$OUTPUT" drawing=on
else
  sketchybar --set "$NAME" drawing=off
fi
