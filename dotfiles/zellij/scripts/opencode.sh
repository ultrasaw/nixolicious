#!/run/current-system/sw/bin/bash

# Tool subprocesses are explicitly excluded, even if they invoke this launcher.
if [[ ${OPENCODE_ZELLIJ_STATUS:-} == 0 ]]; then exec opencode "$@"; fi
unset OPENCODE_ZELLIJ_STATUS
if [[ -z ${ZELLIJ_SESSION_NAME:-} || ! ${ZELLIJ_PANE_ID:-} =~ ^[0-9]+$ ]]; then
  exec opencode "$@"
fi

# Recognize TUI options without changing the arguments passed to OpenCode.
# Unknown options and all subcommands fall back to an uninstrumented launch.
project=$PWD
for ((i = 1; i <= $#; i++)); do
  arg=${!i}
  case "$arg" in
    --print-logs|--standalone|-c|--continue|--auto|--yolo|--dangerously-skip-permissions) ;;
    -s|--session|--prompt)
      ((i++)) ;;
    --session=*|--prompt=*) ;;
    --) break ;;
    acp|api|mcp|run|mini|debug|auth|upgrade|update|uninstall|serve|models|stats|pair|reload|session|service|plugin|-*)
      exec opencode "$@" ;;
    *)
      if [[ ! -d $arg ]]; then exec opencode "$@"; fi
      project=$arg ;;
  esac
done
project=$(realpath -e -- "$project") || exec opencode "$@"
zellij_session=$ZELLIJ_SESSION_NAME
state_file=$(mktemp "${TMPDIR:-/tmp}/opencode-zellij.XXXXXXXX") || exec opencode "$@"

restore_tab() {
  local list saved id original
  # Exact ownership records also cover a crashed TUI without clobbering manual names.
  if [[ -s $state_file ]] && list=$(timeout 3 zellij --session "$zellij_session" action list-panes --json --tab 2>/dev/null); then
    while IFS= read -r saved; do
      if jq -e --argjson saved "$saved" 'any(.[]; .tab_id == $saved.id and .tab_name == $saved.last)' <<< "$list" >/dev/null; then
        id=$(jq -r '.id' <<< "$saved")
        original=$(jq -r '.original' <<< "$saved")
        timeout 3 zellij --session "$zellij_session" action rename-tab --tab-id "$id" -- "$original" >/dev/null 2>&1 || true
      fi
    done < <(jq -c '.[]' "$state_file" 2>/dev/null)
  fi
  rm -f -- "$state_file"
}
trap restore_tab EXIT

# V2 defaults to a shared background service, which cannot inherit per-pane
# ownership. A private server keeps status and cleanup scoped to this launch.
OPENCODE_ZELLIJ_STATUS=1 OPENCODE_ZELLIJ_DIRECTORY="$project" OPENCODE_ZELLIJ_STATE="$state_file" opencode --standalone "$@"
exit "$?"
