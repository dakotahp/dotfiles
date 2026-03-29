#!/bin/bash
# Re-enable the laptop display and redistribute workspaces on lid open
LAPTOP="eDP-1"
EXTERNAL="DP-3"

# Verify the lid is actually physically open before proceeding.
# Guards against spurious triggers from hyprctl reload re-firing switch bindings.
LID_STATE=$(cat /proc/acpi/button/lid/*/state 2>/dev/null | awk '{print $2}' | head -1)
if [ "$LID_STATE" != "open" ]; then
  exit 0
fi

# Re-enable the laptop display and update workspace rules to reflect normal split.
# Using keyword (not reload) to avoid triggering another switch re-fire loop.
hyprctl keyword monitor "$LAPTOP, 3840x2160@60.00700, auto, 2"
for ws in $(seq 1 5); do
  hyprctl keyword workspace "$ws, monitor:$LAPTOP, default:true"
done
for ws in $(seq 6 10); do
  hyprctl keyword workspace "$ws, monitor:$EXTERNAL, default:true"
done

# Update the config file so future manual hyprctl reloads apply correctly.
echo "monitor = $LAPTOP, 3840x2160@60.00700, auto, 2" > ~/.config/hypr/monitors-lid.conf

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
