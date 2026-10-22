import assert from "node:assert/strict"
import { readFile } from "node:fs/promises"
import { spawnSync } from "node:child_process"
import test from "node:test"

test("Home Manager disables OpenCode tabs without replacing unrelated CLI preferences", async () => {
  const source = await readFile(new URL("../home/common.nix", import.meta.url), "utf8")
  const filter = source.match(/\/bin\/jq -e -s '([\s\S]*?)' "\$input_file"/)[1]
  const merge = (input) => spawnSync("jq", ["-e", "-s", filter], { input, encoding: "utf8" })
  const input = {
    theme: { name: "custom" },
    plugins: ["another-plugin"],
    tabs: { mode: "on", scope: "global" },
    prompt: { editor: false },
    session: { sidebar: "hide" },
  }
  const result = merge(JSON.stringify(input))
  assert.equal(result.status, 0, result.stderr)
  const output = JSON.parse(result.stdout)
  assert.deepEqual(output, {
    ...input,
    $schema: "https://opencode.ai/v2/cli.json",
    tabs: { mode: "off", scope: "global" },
    prompt: { editor: false, paste: "full" },
    session: { sidebar: "hide", thinking: "show" },
  })
  assert.equal(JSON.parse(merge("").stdout).tabs.mode, "off")
  for (const invalid of ["[]", "null", "{} {}", "not json"]) {
    assert.notEqual(merge(invalid).status, 0, "invalid settings must not be replaced")
  }
})
