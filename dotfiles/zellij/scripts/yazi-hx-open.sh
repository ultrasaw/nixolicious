#!/run/current-system/sw/bin/bash
# ~/.config/zellij/scripts/yazi-hx-open.sh
#
# Smart opener: works in Zellij OR standalone (opens helix directly)
# $1 = file path to open

FILE_PATH="$1"

if [ -z "$FILE_PATH" ]; then exit 0; fi

# Get absolute path
if command -v realpath &>/dev/null; then
  FILE_PATH=$(realpath "$FILE_PATH" 2>/dev/null) || true
fi

# Check if running inside Zellij
if [ -n "$ZELLIJ" ]; then
  # Escape path for Helix (escape backslashes and quotes)
  ESCAPED_PATH=$(printf '%s' "$FILE_PATH" | sed 's/\\/\\\\/g; s/"/\\"/g')
  
  zellij action focus-next-pane
  
  # Step 1: Send ESC (27) separately to ensure Normal Mode
  zellij action write 27

  # Step 2: Prepare command string ":open "path""
  # We use 'tr -d' to remove newlines from od output which breaks zellij args
  CMD_BYTES=$(printf ":open \"$ESCAPED_PATH\"" | od -An -t u1 | tr -d '\n')

  # Send Command Bytes + Enter (13) in one go
  zellij action write $CMD_BYTES 13
else
  # Not in Zellij - just open helix directly with the file
  hx "$FILE_PATH"
fi
