#!/bin/bash
# Re-enable the laptop display and redistribute workspaces on lid open
LAPTOP="eDP-1"

# Verify the lid is actually physically open before proceeding.
# Guards against spurious triggers from hyprctl reload re-firing switch bindings.
LID_STATE=$(cat /proc/acpi/button/lid/*/state 2>/dev/null | awk '{print $2}' | head -1)
if [ "$LID_STATE" != "open" ]; then
  exit 0
fi

# Detect the connected external monitor at runtime — connector name (DP-3, DP-5,
# HDMI-A-1, etc.) is not stable across physical monitors, so we can't hardcode it.
EXTERNAL=$(hyprctl monitors -j | jq -r ".[] | select(.name != \"$LAPTOP\") | .name" | head -1)

# Re-enable the laptop display and update workspace rules to reflect normal split.
# Using keyword (not reload) to avoid triggering another switch re-fire loop.
hyprctl keyword monitor "$LAPTOP, 3840x2160@60.00700, auto, 2"

if [ -n "$EXTERNAL" ]; then
  # Split workspaces: 1-5 to laptop, 6-10 to external.
  for ws in $(seq 1 5); do
    hyprctl keyword workspace "$ws, monitor:$LAPTOP, default:true"
  done
  for ws in $(seq 6 10); do
    hyprctl keyword workspace "$ws, monitor:$EXTERNAL, default:true"
  done
  {
    echo "monitor = $LAPTOP, 3840x2160@60.00700, auto, 2"
    for ws in $(seq 1 5); do
      echo "workspace = $ws, monitor:$LAPTOP, default:true"
    done
    for ws in $(seq 6 10); do
      echo "workspace = $ws, monitor:$EXTERNAL, default:true"
    done
  } > ~/.config/hypr/monitors-lid.conf

  # Wait for the monitor to initialize before moving workspaces to it
  sleep 1
  for ws in $(seq 1 5); do
    hyprctl dispatch moveworkspacetomonitor "$ws" "$LAPTOP"
  done
else
  # No external connected: pin all workspaces to the laptop display.
  for ws in $(seq 1 10); do
    hyprctl keyword workspace "$ws, monitor:$LAPTOP, default:true"
  done
  {
    echo "monitor = $LAPTOP, 3840x2160@60.00700, auto, 2"
    for ws in $(seq 1 10); do
      echo "workspace = $ws, monitor:$LAPTOP, default:true"
    done
  } > ~/.config/hypr/monitors-lid.conf
fi

# Focus the laptop display and land on workspace 1
hyprctl dispatch focusmonitor "$LAPTOP"
hyprctl dispatch workspace 1
