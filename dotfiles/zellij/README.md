# OpenCode tab status

Launch local OpenCode with `oc` to show a status symbol followed by the first
word of the conversation title. Words longer than 20 Unicode code points are
truncated. There is no fixed application-name prefix.

- Hammer: working or retrying.
- Bell: waiting for a permission or question, including subagent prompts.
- Checkmark: finished.
- Exclamation mark: failed or interrupted.
- Middle dot: no conversation has started yet.

The existing tab bar is unchanged. `ocw`, direct `opencode` launches, and
commands such as `oc run`, `oc mini`, and `oc --server URL` are not opted in. Outside
Zellij, `oc` works normally. Use one local OpenCode process per Zellij tab.

The v2 launcher adds `--standalone` so the private server inherits the current
pane's environment instead of using OpenCode's shared background service.
`ocw` uses `--server http://127.0.0.1:4096 "$PWD"` to connect to the system service.

The plugin follows the most recently prompted or actively running conversation.
Merely viewing an older conversation does not necessarily
change the indicator. Its persisted title is loaded when you interact with it.
Only the launched project's directory instance owns the indicator; additional
server instances for other directories are excluded.

Normal exits restore the previous tab name. The launcher also attempts cleanup
after a TUI crash; killing the entire process group forcibly can leave the last
label behind. Tab moves are detected on the next status/title update.

Home Manager installs the launcher and auto-discovered plugin from `dotfiles`.
After activating the configuration, start a fresh shell and restart OpenCode
through `oc`. No npm packages or additional Zellij plugins are required.

The plugins use the v2 `id`/`setup` API. Context limiting covers OpenAI and
ChatGPT GPT models, with a 320k input cap and 20k compaction buffer. Paste and
thinking preferences are merged into writable `~/.config/opencode/cli.json`;
the first existing file is backed up as `cli.json.before-nix-v2`.

Run the mocked plugin and launcher tests from the repository root:

```sh
node --test tests/zellij-status.test.mjs tests/opencode-launcher.test.mjs tests/context-limit.test.mjs
```
