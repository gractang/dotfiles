#!/bin/sh

PERCENTAGE="$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)"
CHARGING="$(pmset -g batt | grep 'AC Power')"

if [ "$PERCENTAGE" = "" ]; then
  exit 0
fi

if [[ "$CHARGING" != "" ]]; then
  case "${PERCENTAGE}" in
    9[0-9]|100) ICON="󰂅"
    ;;
    [7-8][0-9]) ICON="󰂉"
    ;;
    [5-6][0-9]) ICON="󰂈"
    ;;
    [3-4][0-9]) ICON="󰂆"
    ;;
    [1-2][0-9]) ICON="󰂄"
    ;;
    *) ICON="󰂄"
    ;;
  esac
else
  case "${PERCENTAGE}" in
    9[0-9]|100) ICON="󰁹"
    ;;
    [7-8][0-9]) ICON="󰂁"
    ;;
    [5-6][0-9]) ICON="󰁿"
    ;;
    [3-4][0-9]) ICON="󰁽"
    ;;
    [1-2][0-9]) ICON="󰁻"
    ;;
    *) ICON="󰁺"
    ;;
  esac
fi

sketchybar --set "$NAME" icon="$ICON" label="${PERCENTAGE}%"
