install_dir="$HOME/.local/share/resend-cli"
mkdir -p "$install_dir/releases"

# Serialize manual updates and activation without making a switch wait.
exec 9>"$install_dir/update.lock"
if ! flock --nonblock 9; then
  echo "resend: another update is already running."
  exit 0
fi

export npm_config_registry=https://registry.npmjs.org
export npm_config_fetch_retries=1
export npm_config_fetch_timeout=15000
export npm_config_update_notifier=false

latest=$(npm view resend-cli@latest version --json --prefer-online | jq -er '
  select(type == "string" and test("^[0-9]+\\.[0-9]+\\.[0-9]+([+-][0-9A-Za-z.-]+)?$"))
')
cli_path=lib/node_modules/resend-cli/dist/cli.cjs
package_path=lib/node_modules/resend-cli/package.json

if [ -f "$install_dir/current/$package_path" ] &&
  installed=$(jq -er '.version' "$install_dir/current/$package_path") &&
  [ "$installed" = "$latest" ] &&
  node "$install_dir/current/$cli_path" --version >/dev/null 2>&1; then
  echo "resend: already at latest ($latest)."
  exit 0
fi

stage=$(mktemp -d "$install_dir/releases/$latest.XXXXXX")
link="$install_dir/.current.$$"
cleanup() {
  rm -f -- "$link"
  if [ -n "$stage" ]; then
    rm -rf -- "$stage"
  fi
}
trap cleanup EXIT

# Skip lifecycle scripts; esbuild resolves its optional platform package without
# its postinstall script. Use Nix's Node rather than a downloaded Linux runtime.
npm install --global --prefix "$stage" --ignore-scripts \
  --no-audit --no-fund --no-progress --package-lock=false --prefer-online \
  "resend-cli@$latest"

test "$(jq -er '.version' "$stage/$package_path")" = "$latest"
node "$stage/$cli_path" --version
node "$stage/$cli_path" --help >/dev/null

# Publish only a working installation; retain previous releases for recovery.
ln -s "$stage" "$link"
mv -Tf "$link" "$install_dir/current"
stage=""
echo "resend: installed $latest."
