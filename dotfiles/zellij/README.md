# OpenCode tab status

Launch OpenCode with `oc` to show a status symbol followed by the first
word of the conversation title. Words longer than 20 Unicode code points are
truncated. There is no fixed application-name prefix.

- Hammer: the selected conversation or any descendant is working or retrying.
- Bell: waiting for a permission or question, including subagent prompts.
- Hourglass: agents are idle, but an owned shell command is still running.
- Checkmark: no agents or owned shell commands are running.
- Exclamation mark: no work remains and the root conversation failed or was interrupted.
- Middle dot: no conversation has started yet.

The bell takes priority over working indicators. A completed root does not hide
running children or their shell commands, including descendants in other worktrees.
Only OpenCode-managed command lifetimes are tracked: a detached daemon launched
with `nohup ... &` can outlive its shell and is not a tracked job.

The existing Zellij bar is unchanged; OpenCode's own session tabs are disabled
by Home Manager (`tabs.mode = "off"`). Use one OpenCode TUI per Zellij tab.
`ocw`, direct `opencode` launches, and commands such as `oc run` and `oc mini`
are not opted in. Outside Zellij, `oc` works normally.

The integration is a **CLI-only plugin**, auto-discovered at
`opencode/plugins/zellij-status/tui.js`. It follows the viewed conversation's
root family, not unrelated activity on the same server. It synchronizes existing
descendants, prompts, and shells on attachment and reconnection, then follows live
UI data without job polling. Zellij rendering is debounced independently of events.

The launcher no longer forces `--standalone`: the default shared service and
explicit choices such as `oc --standalone` or `oc --server URL` all work. The
plugin runs locally even when the server is remote. Tool-launched OpenCode
processes are excluded from ownership.

Normal exits restore the previous tab name. The launcher also attempts cleanup
after a TUI crash; killing the entire process group forcibly can leave the last
label behind. Tab moves are detected on the next status/title update. The
ownership journal is written atomically before renaming; manual names are
preserved on cleanup, or adopted as the new restoration target on the next update.

Home Manager installs the launcher and auto-discovered plugin from `dotfiles`.
After activating the configuration, start a fresh shell and restart OpenCode
through `oc`. No npm packages or additional Zellij plugins are required.

The plugins use the v2 `id`/`setup` API (checked against OpenCode 2.0.32 and
Zellij 0.45.1). Context limiting covers OpenAI and
ChatGPT GPT models, with a 320k input cap and 20k compaction buffer. Paste and
thinking and tab preferences are merged into writable `~/.config/opencode/cli.json`;
the first existing file is backed up as `cli.json.before-nix-v2`.

Run the mocked plugin and launcher tests from the repository root:

```sh
node --test tests/*.test.mjs
```
