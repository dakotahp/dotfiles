#!/bin/bash
# Re-enable the laptop display and redistribute workspaces on lid open
LAPTOP="eDP-1"
EXTERNAL="DP-3"

# Re-enable the laptop display
hyprctl keyword monitor "$LAPTOP, 3840x2160@60.00700, auto, 2"

# Wait for the monitor to initialize before trying to move workspaces to it
sleep 1

# If the external monitor is also connected, split workspaces between both displays.
# Workspaces 1-5 return to the laptop; 6-10 stay on the external monitor.
if hyprctl monitors -j | jq -e ".[] | select(.name == \"$EXTERNAL\")" > /dev/null 2>&1; then
  for ws in $(seq 1 5); do
    hyprctl dispatch moveworkspacetomonitor "$ws" "$LAPTOP"
  done
fi

# Focus the laptop display and land on workspace 1
hyprctl dispatch focusmonitor "$LAPTOP"
hyprctl dispatch workspace 1
