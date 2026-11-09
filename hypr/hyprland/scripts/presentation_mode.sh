#!/usr/bin/env bash

STATE_FILE="/tmp/hypr_presentation_mode"

get_primary_monitor() {
    local edp
    edp=$(hyprctl -j monitors 2>/dev/null | jq -r '.[] | select(.name | test("^eDP")) | .name' | head -n 1)
    if [ -n "$edp" ]; then
        echo "$edp"
    else
        hyprctl -j monitors 2>/dev/null | jq -r '.[0].name // empty'
    fi
}

get_external_monitors() {
    local primary="$1"
    hyprctl -j monitors 2>/dev/null | jq -r --arg prim "$primary" '.[] | select(.name != $prim) | .name'
}

is_mirroring() {
    local mirrored
    mirrored=$(hyprctl -j monitors 2>/dev/null | jq -r '.[] | select(.mirrorOf != null and .mirrorOf != "" and .mirrorOf != "none") | .name' | head -n 1)
    if [ -n "$mirrored" ] || [ -f "$STATE_FILE" ]; then
        return 0
    else
        return 1
    fi
}

enable_presentation() {
    local primary
    primary=$(get_primary_monitor)
    if [ -z "$primary" ]; then
        notify-send -a "Presentation" -u critical "Presentation Mode" "No active displays found."
        exit 1
    fi

    local externals
    externals=$(get_external_monitors "$primary")

    if [ -z "$externals" ]; then
        notify-send -a "Presentation" -u normal "Presentation Mode" "No external display detected.\nPlease connect HDMI or DisplayPort cable first."
        touch "$STATE_FILE"
        exit 0
    fi

    for ext in $externals; do
        hyprctl keyword monitor "$ext,preferred,auto,1,mirror,$primary"
    done

    touch "$STATE_FILE"
    notify-send -a "Presentation" -u normal "Presentation Mode: ON" "Screen mirrored to external display ($externals)."
}

disable_presentation() {
    local primary
    primary=$(get_primary_monitor)
    local externals
    externals=$(get_external_monitors "$primary")

    rm -f "$STATE_FILE"

    if [ -n "$externals" ]; then
        for ext in $externals; do
            hyprctl keyword monitor "$ext,preferred,auto,1"
        done
    else
        hyprctl reload
    fi

    notify-send -a "Presentation" -u normal "Presentation Mode: OFF" "Extended display mode restored."
}

toggle_presentation() {
    if is_mirroring; then
        disable_presentation
    else
        enable_presentation
    fi
}

case "$1" in
    enable)
        enable_presentation
        ;;
    disable)
        disable_presentation
        ;;
    toggle)
        toggle_presentation
        ;;
    status)
        if is_mirroring; then
            echo "enabled"
            exit 0
        else
            echo "disabled"
            exit 1
        fi
        ;;
    *)
        toggle_presentation
        ;;
esac
