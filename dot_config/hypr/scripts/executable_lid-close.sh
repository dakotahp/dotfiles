#!/bin/bash
# Move all workspaces off eDP-1 before disabling it on lid close
LAPTOP="eDP-1"
EXTERNAL="DP-3"

# Verify the lid is actually physically closed before proceeding.
# hyprctl reload re-fires switch bindings based on current state, so without
# this check the script would run spuriously on every reload.
LID_STATE=$(cat /proc/acpi/button/lid/*/state 2>/dev/null | awk '{print $2}' | head -1)
if [ "$LID_STATE" != "closed" ]; then
  exit 0
fi

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

# Write the disable rule + workspace pins to the sourced config file, then reload.
# Workspace rules are required: without them, Hyprland reassigns odd workspaces to
# eDP-1 after reload (based on monitor order), and switching to one re-enables it.
{
  echo "monitor = $LAPTOP, disable"
  for ws in $(seq 1 10); do
    echo "workspace = $ws, monitor:$EXTERNAL, default:true"
  done
} > ~/.config/hypr/monitors-lid.conf
hyprctl reload
