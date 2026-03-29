#!/bin/bash
# Re-enable the laptop display and redistribute workspaces on lid open
LAPTOP="eDP-1"
EXTERNAL="DP-3"

# Verify the lid is actually physically open before proceeding.
# hyprctl reload re-fires switch bindings based on current state, so without
# this check the script would undo clamshell mode on every reload while lid is open.
LID_STATE=$(cat /proc/acpi/button/lid/*/state 2>/dev/null | awk '{print $2}' | head -1)
if [ "$LID_STATE" != "open" ]; then
  exit 0
fi

# Restore the normal eDP-1 rule (no workspace pins) and reload
echo "monitor = $LAPTOP, 3840x2160@60.00700, auto, 2" > ~/.config/hypr/monitors-lid.conf
hyprctl reload

# Wait for the monitor to initialize before moving workspaces to it
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
