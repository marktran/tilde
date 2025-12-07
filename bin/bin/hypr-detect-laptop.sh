#!/usr/bin/env bash
# Auto-detect laptop model and configure monitors accordingly

# First, enable the monitor with a basic config to ensure it's active
hyprctl keyword monitor "eDP-1,preferred,auto,2"

# Give it a moment to initialize
sleep 0.2

# Get the internal display info
MONITOR_INFO=$(hyprctl monitors -j | jq -r '.[] | select(.name == "eDP-1")')

if [ -z "$MONITOR_INFO" ]; then
    echo "No eDP-1 monitor found, using default config"
    exit 0
fi

# Extract available modes to detect the laptop
MODES=$(echo "$MONITOR_INFO" | jq -r '.availableModes[]' 2>/dev/null)

# Detect laptop based on maximum resolution available
if echo "$MODES" | grep -q "2880x1920"; then
    # Framework 13 (3:2 aspect ratio)
    echo "Detected: Framework 13"
    hyprctl keyword monitor "eDP-1,2880x1920@120,auto,2"
elif echo "$MODES" | grep -q "2880x1800"; then
    # Thinkpad X1 Carbon Gen 13 (16:10 aspect ratio)
    echo "Detected: Thinkpad X1 Carbon Gen 13"
    hyprctl keyword monitor "eDP-1,2880x1800@120,auto,2"
else
    # Fallback to preferred mode with 2x scaling
    echo "Unknown laptop model, using preferred resolution"
    hyprctl keyword monitor "eDP-1,preferred,auto,2"
fi
