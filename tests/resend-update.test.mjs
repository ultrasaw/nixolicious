import assert from "node:assert/strict"
import { spawnSync } from "node:child_process"
import { mkdtemp, mkdir, readFile, readdir, readlink, rm, writeFile } from "node:fs/promises"
import { join } from "node:path"
import test from "node:test"
import { fileURLToPath } from "node:url"

const script = fileURLToPath(new URL("../modules/resend-update.sh", import.meta.url))
const mockNpm = `#!/usr/bin/env node
const fs = require("node:fs")
const path = require("node:path")
const args = process.argv.slice(2)
fs.appendFileSync(process.env.NPM_MOCK_LOG, JSON.stringify(args) + "\\n")
if (args[0] === "view") {
  if (process.env.NPM_MOCK_MODE === "offline") process.exit(1)
  console.log(JSON.stringify(process.env.NPM_MOCK_LATEST))
} else if (args[0] === "install") {
  if (process.env.NPM_MOCK_MODE === "install-failure") process.exit(1)
  const prefix = args[args.indexOf("--prefix") + 1]
  const pkg = path.join(prefix, "lib/node_modules/resend-cli")
  fs.mkdirSync(path.join(pkg, "dist"), { recursive: true })
  fs.writeFileSync(path.join(pkg, "package.json"), JSON.stringify({ version: process.env.NPM_MOCK_LATEST }))
  fs.writeFileSync(path.join(pkg, "dist/cli.cjs"), process.env.NPM_MOCK_MODE === "broken-cli"
    ? "process.exit(1)"
    : "console.log(JSON.stringify(process.argv.slice(2)))")
} else {
  process.exit(2)
}
`

async function fixture(t) {
  const dir = await mkdtemp("/tmp/opencode/resend-test-")
  t.after(() => rm(dir, { recursive: true, force: true }))
  const bin = join(dir, "bin")
  await mkdir(bin)
  await writeFile(join(bin, "npm"), mockNpm, { mode: 0o755 })
  const log = join(dir, "npm.log")
  const install = join(dir, ".local/share/resend-cli")
  const env = {
    ...process.env,
    HOME: dir,
    PATH: `${bin}:${process.env.PATH}`,
    NPM_MOCK_LOG: log,
    NPM_MOCK_LATEST: "2.26.2",
  }
  const run = (extra = {}) => spawnSync("bash", ["-euo", "pipefail", script], {
    env: { ...env, ...extra }, encoding: "utf8",
  })
  const calls = async () => (await readFile(log, "utf8")).trim().split("\n").map(JSON.parse)
  return { dir, install, log, env, run, calls }
}

test("installs a concrete latest version and checks again without reinstalling", async (t) => {
  const f = await fixture(t)
  let result = f.run()
  assert.equal(result.status, 0, result.stderr)
  const first = await readlink(join(f.install, "current"))
  let calls = await f.calls()
  assert.deepEqual(calls.map((args) => args[0]), ["view", "install"])
  assert.ok(calls[0].includes("--prefer-online"))
  assert.ok(calls[1].includes("--ignore-scripts"))
  assert.equal(calls[1].at(-1), "resend-cli@2.26.2")

  result = f.run()
  assert.equal(result.status, 0, result.stderr)
  assert.match(result.stdout, /already at latest/)
  assert.equal(await readlink(join(f.install, "current")), first)
  calls = await f.calls()
  assert.deepEqual(calls.map((args) => args[0]), ["view", "install", "view"])

  result = f.run({ NPM_MOCK_LATEST: "2.27.0" })
  assert.equal(result.status, 0, result.stderr)
  assert.notEqual(await readlink(join(f.install, "current")), first)
  assert.equal((await readdir(join(f.install, "releases"))).length, 2)
  assert.ok(await readFile(join(first, "lib/node_modules/resend-cli/package.json")))
})

for (const mode of ["offline", "install-failure", "broken-cli", "invalid-version"]) {
  test(`preserves the working release and cleans staging after ${mode}`, async (t) => {
    const f = await fixture(t)
    assert.equal(f.run().status, 0)
    const first = await readlink(join(f.install, "current"))
    const result = f.run({
      NPM_MOCK_LATEST: mode === "invalid-version" ? "../../unsafe" : "2.27.0",
      NPM_MOCK_MODE: mode,
    })
    assert.notEqual(result.status, 0)
    assert.equal(await readlink(join(f.install, "current")), first)
    assert.equal((await readdir(join(f.install, "releases"))).length, 1)
    assert.ok(!(await readdir(f.install)).some((name) => name.startsWith(".current.")))
  })
}

test("does not start another update while the lock is held", async (t) => {
  const f = await fixture(t)
  await mkdir(f.install, { recursive: true })
  const result = spawnSync("flock", [join(f.install, "update.lock"), "bash", "-euo", "pipefail", script], {
    env: f.env, encoding: "utf8",
  })
  assert.equal(result.status, 0, result.stderr)
  assert.match(result.stdout, /already running/)
  await assert.rejects(readFile(f.log), { code: "ENOENT" })
})

test("launcher reports missing installs and forwards arguments after installation", async (t) => {
  const f = await fixture(t)
  const source = await readFile(new URL("../modules/resend.nix", import.meta.url), "utf8")
  const launcher = source.match(/writeShellScriptBin "resend" ''([\s\S]*?)\n  '';/)[1]
    .replaceAll("${nodejs}/bin/node", process.execPath)
  const run = () => spawnSync("bash", ["-c", launcher, "resend", "emails", "list", "--json"], {
    env: f.env, encoding: "utf8",
  })
  let result = run()
  assert.equal(result.status, 1)
  assert.match(result.stderr, /run resend-update/)
  assert.equal(f.run().status, 0)
  result = run()
  assert.equal(result.status, 0, result.stderr)
  assert.deepEqual(JSON.parse(result.stdout), ["emails", "list", "--json"])
})
