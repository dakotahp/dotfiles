#!/bin/bash
# Move all workspaces off eDP-1 before disabling it on lid close
LAPTOP="eDP-1"
EXTERNAL="DP-3"

# Check if external monitor is connected
if ! hyprctl monitors -j | jq -e ".[] | select(.name == \"$EXTERNAL\")" > /dev/null 2>&1; then
  exit 0
fi

# Focus the external monitor first so input stays live during migration
hyprctl dispatch focusmonitor "$EXTERNAL"

# Move all default workspace slots (1-10) to the external monitor unconditionally.
# hyprctl workspaces -j only lists populated/visible workspaces — empty workspaces
# "owned" by eDP-1 would be missed and become inaccessible after the monitor is disabled.
for ws in $(seq 1 10); do
  hyprctl dispatch moveworkspacetomonitor "$ws" "$EXTERNAL"
done

# Also catch any numbered workspaces beyond 10 that were on the laptop
hyprctl workspaces -j | jq -r ".[] | select(.monitor == \"$LAPTOP\") | .id" | while read -r ws; do
  hyprctl dispatch moveworkspacetomonitor "$ws" "$EXTERNAL"
done

# Land on workspace 1 so the session is in a predictable state
hyprctl dispatch workspace 1

# Disable the laptop display
hyprctl keyword monitor "$LAPTOP, disable"
