#!/bin/bash
# ~/.config/zellij/scripts/fzf-helix-open.sh
#
# This script is called by fzf to open the selected file ($1)
# in an existing Helix instance running in the next Zellij pane.

# Ensure a file path argument is provided
if [ -z "$1" ]; then
  # No argument provided, exit gracefully
  exit 0
fi

# Get the absolute path of the selected file.
# This helps ensure Helix finds the file correctly, regardless of
# the working directory fzf or Helix was started in.
# Use command -v to find realpath, handle potential errors.
REALPATH_CMD=$(command -v realpath)
if [ -n "$REALPATH_CMD" ]; then
  file_path=$("$REALPATH_CMD" "$1" 2>/dev/null)
fi

# Fallback if realpath failed or isn't available, use the original path
if [ -z "$file_path" ]; then
  file_path="$1"
fi

# Escape potential special characters (like quotes or backslashes)
# in the filename for the Helix :open command.
# This replaces backslash with double-backslash and double-quote with backslash-double-quote.
escaped_file_path=$(printf '%s' "$file_path" | sed 's/\\/\\\\/g; s/"/\\"/g')

# --- Zellij Action Sequence ---

zellij action focus-next-pane

# send the Escape key code (ASCII 27) to ensure Helix is in normal mode.
zellij action write 27

# type the Helix ':open' command followed by the escaped file path and a space.
zellij action write-chars ":open \"$escaped_file_path\" "

# send the Enter key code (ASCII 13) to execute the ':open' command in Helix.
zellij action write 13

# immediately use fzf again without manual pane switching.
zellij action focus-previous-pane

# Exit successfully
exit 0
