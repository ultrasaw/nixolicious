import assert from "node:assert/strict"
import { mkdir, mkdtemp, readFile, writeFile, rm } from "node:fs/promises"
import { join } from "node:path"
import test from "node:test"
import ZellijStatus from "../dotfiles/opencode/plugins/zellij-status.js"

const hammer = "\u{1f528}"
const bell = "\u{1f514}"
const check = "\u2713"

async function setup(t, options = {}) {
  await mkdir("/tmp/opencode", { recursive: true })
  const dir = await mkdtemp("/tmp/opencode/zellij-status-test-")
  const statePath = join(dir, "panes.json")
  const journal = join(dir, "journal.json")
  const env = {
    PATH: `${dir}:${process.env.PATH}`,
    ZELLIJ_SESSION_NAME: "test-session",
    ZELLIJ_PANE_ID: "4",
    OPENCODE_ZELLIJ_STATUS: "1",
    OPENCODE_ZELLIJ_DIRECTORY: dir,
    OPENCODE_ZELLIJ_STATE: journal,
    FAKE_ZELLIJ_STATE: statePath,
    ...options.env,
  }
  const previous = Object.fromEntries(Object.keys(env).map((key) => [key, process.env[key]]))
  Object.assign(process.env, env)
  let hooks
  t.after(async () => {
    await hooks?.dispose?.()
    for (const [key, value] of Object.entries(previous)) {
      if (value === undefined) delete process.env[key]
      else process.env[key] = value
    }
    await rm(dir, { recursive: true, force: true })
  })
  await writeFile(statePath, JSON.stringify({
    panes: [
      { id: 4, is_plugin: true, tab_id: 99, tab_name: "plugin" },
      { id: 4, is_plugin: false, tab_id: 11, tab_name: "original" },
      { id: 8, is_plugin: false, tab_id: 12, tab_name: "hx" },
    ],
    commands: [],
    ...options.state,
  }))
  await writeFile(join(dir, "zellij"), `#!${process.execPath}
const fs = require("node:fs")
const path = process.env.FAKE_ZELLIJ_STATE
const state = JSON.parse(fs.readFileSync(path, "utf8"))
const args = process.argv.slice(2)
if (args[0] !== "--session" || args[1] !== "test-session" || args[2] !== "action") process.exit(2)
if (state.fail) process.exit(1)
state.commands.push(args.slice(3))
if (args[3] === "list-panes") {
  process.stdout.write(state.invalid ? "invalid json" : JSON.stringify(state.panes))
} else if (args[3] === "rename-tab") {
  if (args[4] !== "--tab-id" || args[6] !== "--") process.exit(2)
  for (const pane of state.panes) if (pane.tab_id === Number(args[5])) pane.tab_name = args[7]
} else process.exit(2)
fs.writeFileSync(path, JSON.stringify(state))
`, { mode: 0o755 })

  const sessions = new Map([
    ["root", { id: "root", title: "Investigating Blender alert: test or real?" }],
    ["child", { id: "child", parentID: "root", title: "Explore files" }],
    ["grandchild", { id: "grandchild", parentID: "child", title: "Read source" }],
    ["other", { id: "other", title: "Fix another project" }],
  ])
  const context = {
    directory: dir,
    client: { session: { get: async ({ path: { id } }) => ({ data: sessions.get(id) }) } },
  }
  hooks = await ZellijStatus(context)
  const state = async () => JSON.parse(await readFile(statePath, "utf8"))
  const change = async (fn) => {
    const current = await state()
    fn(current)
    await writeFile(statePath, JSON.stringify(current))
  }
  const label = async (tab = 11) => (await state()).panes.find((pane) => pane.tab_id === tab)?.tab_name
  const emit = (type, properties) => hooks.event({ event: { type, properties } })
  const status = (type, sessionID = "root") => emit("session.status", { sessionID, status: { type } })
  const chat = (sessionID = "root") => hooks["chat.message"]({ sessionID })
  return { hooks, state, change, label, emit, status, chat, sessions, context, journal }
}

test("first title word with working, retry, input, and done states", async (t) => {
  const h = await setup(t)
  assert.equal(await h.label(), "\u00b7")
  await h.chat()
  assert.equal(await h.label(), `${hammer} Investigating`)
  await h.status("retry")
  assert.equal(await h.label(), `${hammer} Investigating`)
  await h.emit("permission.asked", { sessionID: "root", id: "p1" })
  await h.status("busy")
  assert.equal(await h.label(), `${bell} Investigating`)
  await h.emit("permission.replied", { sessionID: "root", requestID: "p1", reply: "once" })
  assert.equal(await h.label(), `${hammer} Investigating`)
  await h.emit("question.asked", { sessionID: "root", id: "q1" })
  assert.equal(await h.label(), `${bell} Investigating`)
  await h.emit("question.replied", { sessionID: "root", requestID: "q1", answers: [["Yes"]] })
  assert.equal(await h.label(), `${hammer} Investigating`)
  await h.status("idle")
  assert.equal(await h.label(), `${check} Investigating`)
  await h.emit("session.idle", { sessionID: "root" })
  assert.equal(await h.label(), `${check} Investigating`)
})

test("subagent titles/idle cannot finish the root; all prompts must be resolved", async (t) => {
  const h = await setup(t)
  await h.chat()
  await h.emit("session.updated", { info: h.sessions.get("child") })
  await h.status("idle", "child")
  assert.equal(await h.label(), `${hammer} Investigating`)
  await h.emit("permission.asked", { sessionID: "child", id: "same-id" })
  await h.emit("question.asked", { sessionID: "grandchild", id: "same-id" })
  await h.emit("permission.replied", { sessionID: "child", requestID: "same-id", reply: "reject" })
  assert.equal(await h.label(), `${bell} Investigating`)
  await h.emit("question.rejected", { sessionID: "grandchild", requestID: "same-id" })
  assert.equal(await h.label(), `${hammer} Investigating`)
})

test("child cancellation clears its requests but preserves another child's prompt", async (t) => {
  const h = await setup(t)
  await h.chat()
  await h.emit("permission.asked", { sessionID: "child", id: "p1" })
  await h.emit("question.asked", { sessionID: "grandchild", id: "q1" })
  await h.emit("session.error", { sessionID: "child", error: { name: "MessageAbortedError" } })
  assert.equal(await h.label(), `${bell} Investigating`)
  await h.status("idle", "grandchild")
  assert.equal(await h.label(), `${hammer} Investigating`)
  await h.status("idle")
  assert.equal(await h.label(), `${check} Investigating`)
})

test("root interruption clears prompts and stays interrupted through idle and late replies", async (t) => {
  const h = await setup(t)
  await h.chat()
  await h.emit("question.asked", { sessionID: "grandchild", id: "q1" })
  await h.emit("session.error", { sessionID: "root", error: { name: "MessageAbortedError" } })
  await h.status("idle")
  await h.emit("question.rejected", { sessionID: "grandchild", requestID: "q1" })
  assert.equal(await h.label(), "! Investigating")
  await h.chat()
  assert.equal(await h.label(), `${hammer} Investigating`)
})

test("resumed activity loads its title and unrelated idle/prompts do not change it", async (t) => {
  const h = await setup(t)
  await h.status("busy")
  assert.equal(await h.label(), `${hammer} Investigating`)
  await h.emit("question.asked", { sessionID: "other", id: "q2" })
  await h.status("idle", "other")
  assert.equal(await h.label(), `${hammer} Investigating`)
  await h.status("busy", "other")
  assert.equal(await h.label(), `${hammer} Fix`)
  await h.status("idle")
  assert.equal(await h.label(), `${hammer} Fix`)
  await h.chat()
  assert.equal(await h.label(), `${hammer} Investigating`)
})

test("updated titles use one bounded Unicode word, with no fixed app prefix", async (t) => {
  const h = await setup(t)
  await h.chat()
  await h.emit("session.updated", { info: { id: "root", title: "  Refactoring\tvery long conversation title" } })
  assert.equal(await h.label(), `${hammer} Refactoring`)
  await h.emit("session.updated", { info: { id: "root", title: "A".repeat(50) + " details" } })
  assert.equal(await h.label(), `${hammer} ${"A".repeat(17)}...`)
  await h.emit("session.updated", { info: { id: "root", title: "\u{1f431}".repeat(21) + " details" } })
  assert.equal(await h.label(), `${hammer} ${"\u{1f431}".repeat(17)}...`)
  await h.emit("session.updated", { info: { id: "root", title: "" } })
  assert.equal(await h.label(), hammer)
})

test("targets terminal pane's tab, follows moves, and restores original names", async (t) => {
  const h = await setup(t)
  await h.chat()
  assert.equal(await h.label(99), "plugin")
  assert.equal(await h.label(12), "hx")
  await h.change((state) => {
    state.panes.find((pane) => pane.id === 4 && !pane.is_plugin).tab_id = 12
    state.panes.find((pane) => pane.id === 4 && !pane.is_plugin).tab_name = "hx"
    state.panes.push({ id: 9, is_plugin: false, tab_id: 11, tab_name: `${hammer} Investigating` })
  })
  await h.status("idle")
  assert.equal(await h.label(11), "original")
  assert.equal(await h.label(12), `${check} Investigating`)
  assert.deepEqual(JSON.parse(await readFile(h.journal, "utf8")), [{ id: 12, original: "hx", last: `${check} Investigating` }])
  await h.hooks.dispose()
  assert.equal(await h.label(12), "hx")
  await h.status("busy")
  assert.equal(await h.label(12), "hx")
})

test("manual names are preserved on disposal", async (t) => {
  const h = await setup(t)
  await h.chat()
  await h.change((state) => { state.panes.find((pane) => pane.tab_id === 11).tab_name = "! urgent" })
  await h.hooks.dispose()
  assert.equal(await h.label(), "! urgent")
})

test("concurrent callbacks are serialized and a prompt wins over later busy updates", async (t) => {
  const h = await setup(t)
  await h.chat()
  await Promise.all([
    h.status("busy"),
    h.emit("permission.asked", { sessionID: "root", id: "p1" }),
    h.status("busy"),
    h.emit("session.updated", { info: { id: "root", title: "Testing concurrency" } }),
  ])
  assert.equal(await h.label(), `${bell} Testing`)
})

test("CLI and malformed JSON failures do not break hooks or poison subsequent updates", async (t) => {
  const h = await setup(t, { state: { fail: true } })
  await h.chat()
  await h.change((state) => { state.fail = false; state.invalid = true })
  await h.status("busy")
  await h.change((state) => { state.invalid = false })
  await h.status("busy")
  assert.equal(await h.label(), `${hammer} Investigating`)
})

test("disabled outside launcher and in other directory instances; tools get explicit opt-out", async (t) => {
  const h = await setup(t)
  assert.deepEqual(await ZellijStatus({ ...h.context, directory: "/other" }), {})
  const output = { env: {} }
  await h.hooks["shell.env"]({}, output)
  assert.equal(output.env.OPENCODE_ZELLIJ_STATUS, "0")
  process.env.OPENCODE_ZELLIJ_STATUS = "0"
  assert.deepEqual(await ZellijStatus(h.context), {})
  delete process.env.OPENCODE_ZELLIJ_STATUS
  assert.deepEqual(await ZellijStatus(h.context), {})
})

test("unknown sessions are ignored, and deleting the active session clears its title", async (t) => {
  const h = await setup(t)
  await h.chat()
  await h.status("busy", "missing")
  assert.equal(await h.label(), `${hammer} Investigating`)
  await h.emit("session.deleted", { info: h.sessions.get("root") })
  assert.equal(await h.label(), "\u00b7")
})
