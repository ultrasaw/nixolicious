# Rebuild after adding/removing cluster files with `kubeconfig-refresh`.
kubeconfig-refresh() {
  emulate -L zsh

  # Newest YAML wins, followed by the default kubeconfig.
  local -a files=("$HOME"/.kube/*.yaml(Nom))
  [[ ! -f "$HOME/.kube/config" ]] || files+=("$HOME/.kube/config")
  if (( ! ${#files} )); then
    unset KUBECONFIG
    return 0
  fi

  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/kubeconfig"
  local sources="${(j/:/)files}" temporary candidate file
  mkdir -p -m 700 "$cache_dir" || return 1
  temporary=$(mktemp "$cache_dir/config.XXXXXXXX") || return 1

  # Flatten resolves relative certificate paths before relocating the config.
  # mktemp keeps the embedded credentials private; mv publishes atomically.
  if ! KUBECONFIG="$sources" kubectl config view --flatten --raw -o json > "$temporary"; then
    rm -f "$temporary"
    return 1
  fi

  candidate=$(jq -r '."current-context" // ""' "$temporary")
  if [[ -z "$candidate" ]] || ! jq -e --arg name "$candidate" \
    'any(.contexts[]?; .name == $name)' "$temporary" > /dev/null; then
    candidate=""
    for file in "${files[@]}"; do
      candidate=$(kubectl --kubeconfig="$file" config current-context 2>/dev/null) || candidate=""
      if [[ -n "$candidate" ]] && jq -e --arg name "$candidate" \
        'any(.contexts[]?; .name == $name)' "$temporary" > /dev/null; then
        break
      fi
      candidate=""
    done
  fi

  # An empty selection is safer than silently choosing an arbitrary cluster.
  local merged
  merged=$(jq --arg name "$candidate" '."current-context" = $name' "$temporary") || {
    rm -f "$temporary"
    return 1
  }
  print -r -- "$merged" > "$temporary"
  mv -f "$temporary" "$cache_dir/config" || return 1
  export KUBECONFIG="$cache_dir/config"
}

kubeconfig-refresh
