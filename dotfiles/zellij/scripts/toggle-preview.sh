#!/run/current-system/sw/bin/bash
# ~/.config/zellij/scripts/toggle-preview.sh
#
# Toggle between preview mode (yazi bigger) and edit mode (helix bigger)
# Cycles through swap layouts and optionally focuses yazi

# Cycle to next swap layout (preview <-> edit)
zellij action next-swap-layout

# Optionally focus yazi pane (uncomment if desired)
# zellij action focus-previous-pane

exit 0
