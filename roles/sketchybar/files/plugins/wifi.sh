#!/bin/sh

POWER="$(networksetup -getairportpower en0 2>/dev/null | awk -F': ' '{print $2}')"

if [ "$POWER" != "On" ]; then
  sketchybar --set "$NAME" icon="󰖪" label="Off"
  exit 0
fi

STATUS="$(ifconfig en0 2>/dev/null | awk '/status:/ {print $2}')"
IP="$(ipconfig getifaddr en0 2>/dev/null)"

if [ "$STATUS" != "active" ] || [ -z "$IP" ]; then
  sketchybar --set "$NAME" icon="󰖩" label="—"
  exit 0
fi

LABEL="$IP"

GATEWAY="$(route -n get default 2>/dev/null | awk '/gateway:/ {print $2}')"
CONF="$CONFIG_DIR/wifi_networks.conf"

if [ -n "$GATEWAY" ] && [ -f "$CONF" ]; then
  MAC="$(arp -n "$GATEWAY" 2>/dev/null \
    | awk '{print $4}' \
    | grep -Eo '^([0-9a-fA-F]{1,2}:){5}[0-9a-fA-F]{1,2}$' \
    | awk -F: 'BEGIN{OFS=":"} {for(i=1;i<=NF;i++) if(length($i)==1) $i="0"$i; print tolower($0)}')"

  if [ -n "$MAC" ]; then
    FRIENDLY="$(awk -v mac="$MAC" '
      /^[[:space:]]*#/ || /^[[:space:]]*$/ {next}
      {
        entry=tolower($1)
        if (entry == mac) {
          $1=""; sub(/^[[:space:]]+/, "")
          print
          exit
        }
      }' "$CONF")"

    if [ -n "$FRIENDLY" ]; then
      LABEL="$FRIENDLY"
    fi
  fi
fi

sketchybar --set "$NAME" icon="󰖩" label="$LABEL"
