import assert from "node:assert/strict"
import { mkdir, mkdtemp, readFile, writeFile, rm } from "node:fs/promises"
import { join } from "node:path"
import { setTimeout as delay } from "node:timers/promises"
import test from "node:test"
import { setupZellijStatus } from "../dotfiles/opencode/plugins/zellij-status/status.js"

const hammer = "\u{1f528}"
const bell = "\u{1f514}"
const check = "\u2713"
const hourglass = "\u23f3"

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
    OPENCODE_ZELLIJ_STATE: journal,
    OPENCODE: "",
    OPENCODE_SESSION_ID: "",
    FAKE_ZELLIJ_STATE: statePath,
    ...options.env,
  }
  const previous = Object.fromEntries(Object.keys(env).map((key) => [key, process.env[key]]))
  Object.assign(process.env, env)
  let dispose
  t.after(async () => {
    await dispose?.()
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
  if (options.journal) await writeFile(journal, JSON.stringify(options.journal))
  await writeFile(join(dir, "zellij"), `#!${process.execPath}
const fs = require("node:fs")
const path = process.env.FAKE_ZELLIJ_STATE
const state = JSON.parse(fs.readFileSync(path, "utf8"))
const args = process.argv.slice(2)
if (args[0] !== "--session" || args[1] !== "test-session" || args[2] !== "action") process.exit(2)
state.commands.push(args.slice(3))
if (state.fail) process.exit(1)
if (args[3] === "list-panes") {
  process.stdout.write(state.invalid ? "invalid json" : JSON.stringify(state.panes))
} else if (args[3] === "rename-tab") {
  if (args[4] !== "--tab-id" || args[6] !== "--") process.exit(2)
  if (state.failRename) process.exit(1)
  // Ownership must already be journaled when a rename happens.
  const journal = JSON.parse(fs.readFileSync(process.env.OPENCODE_ZELLIJ_STATE, "utf8"))
  if (!journal.some(item => item.id === Number(args[5]) && (item.last === args[7] || item.original === args[7]))) process.exit(3)
  for (const pane of state.panes) if (pane.tab_id === Number(args[5])) pane.tab_name = args[7]
} else process.exit(2)
fs.writeFileSync(path + ".tmp", JSON.stringify(state))
fs.renameSync(path + ".tmp", path)
`, { mode: 0o755 })

  const location = { directory: dir }
  const sessions = new Map([
    ["root", { id: "root", title: "Investigating Blender alert: test or real?", location }],
    ["child", { id: "child", parentID: "root", title: "Explore files", location }],
    ["grandchild", { id: "grandchild", parentID: "child", title: "Read source", location }],
    ["other", { id: "other", title: "Fix another project", location }],
  ])
  const known = new Map(sessions)
  for (const id of options.unknown ?? []) known.delete(id)
  const statuses = new Map(Object.entries(options.statuses ?? {}))
  const permissions = new Map()
  const forms = new Map()
  const shells = new Map(options.shells?.map((info) => [info.id, info]) ?? [])
  const reads = []
  let route = options.route ?? { type: "home" }
  let listener
  let update
  let pending = 0
  const root = (id) => {
    const visited = new Set()
    while (known.get(id)?.parentID && !visited.has(id)) {
      visited.add(id)
      id = known.get(id).parentID
    }
    return id
  }
  const notify = () => update?.()
  const collection = (map, kind) => ({
    list: (id) => Array.from(map.get(id)?.values() ?? []),
    sync: async (id) => { reads.push([kind, id]) },
    invalidate: (id) => { reads.push([`${kind}.invalidate`, id]) },
  })
  const context = {
    data: {
      listen(callback) { listener = callback; return () => { listener = undefined } },
      session: {
        get: (id) => known.get(id),
        list: () => Array.from(known.values()),
        root,
        family: (id) => Array.from(known.keys()).filter((key) => root(key) === root(id)),
        status: (id) => statuses.get(id) ?? "idle",
        sync: async (id) => {
          reads.push(["session", id])
          if (sessions.has(id)) known.set(id, sessions.get(id))
          notify()
        },
        permission: collection(permissions, "permission"),
        form: collection(forms, "form"),
      },
      shell: {
        list: (ref) => Array.from(shells.values()).filter((info) => info.location.directory === ref.directory),
        sync: async (ref) => { reads.push(["shell", ref.directory]) },
        invalidate: (ref) => { reads.push(["shell.invalidate", ref.directory]) },
      },
    },
    client: { session: { list: async (input) => {
      reads.push(["children", input.parentID ?? input.cursor])
      pending++
      try {
        if (options.list) return await options.list(input, sessions)
        return { data: Array.from(sessions.values()).filter((info) => info.parentID === input.parentID), cursor: {} }
      } finally { pending-- }
    } } },
    ui: { router: { current: () => route } },
  }
  dispose = await setupZellijStatus(context, (callback) => {
    update = callback
    return () => { update = undefined }
  })
  const state = async () => JSON.parse(await readFile(statePath, "utf8"))
  const label = async (tab = 11) => (await state()).panes.find((pane) => pane.tab_id === tab)?.tab_name
  // Wait for the debounced external writer to become quiescent before changing
  // its fake on-disk state. This is test synchronization, not job polling.
  async function flush() {
    let previous
    let stable = 0
    for (let n = 0; n < 200; n++) {
      await delay(20)
      const current = JSON.stringify(await state())
      stable = current === previous && pending === 0 ? stable + 1 : 0
      previous = current
      if (stable >= 8) return
    }
    assert.fail("status writer did not settle")
  }
  async function expect(value, tab = 11) {
    await flush()
    assert.equal(await label(tab), value)
  }
  const change = async (fn) => {
    await flush()
    const current = await state()
    fn(current)
    await writeFile(statePath, JSON.stringify(current))
  }
  const emit = (type, props, ref = location) => {
    const id = props?.sessionID
    if (type === "session.execution.started") statuses.set(id, "running")
    if (type.startsWith("session.execution.") && !type.endsWith(".started")) statuses.set(id, "idle")
    if (type === "session.renamed") {
      sessions.get(id).title = props.title
      known.set(id, sessions.get(id))
    }
    if (type === "session.deleted") { sessions.delete(id); known.delete(id) }
    if (type === "permission.asked") {
      if (!permissions.has(id)) permissions.set(id, new Map())
      permissions.get(id).set(props.id, props)
    }
    if (type === "permission.replied") permissions.get(id)?.delete(props.requestID)
    if (type === "form.created") {
      if (!forms.has(props.form.sessionID)) forms.set(props.form.sessionID, new Map())
      forms.get(props.form.sessionID).set(props.form.id, props.form)
    }
    if (["form.replied", "form.cancelled"].includes(type)) forms.get(id)?.delete(props.id)
    if (type === "shell.created") shells.set(props.info.id, { ...props.info, location: ref })
    if (["shell.exited", "shell.deleted"].includes(type)) shells.delete(props.id)
    listener?.({ details: { type, data: props, location: ref } })
    notify()
  }
  const select = (id = "root") => { route = { type: "session", sessionID: id }; notify() }
  const shell = (id, owner = "root", ref = location) => emit("shell.created", {
    info: { id, status: "running", metadata: { sessionID: owner } },
  }, ref)
  return { context, dispose: () => dispose?.(), state, label, expect, flush, change, emit, select, shell,
    sessions, known, statuses, reads, journal, location, notify, home: () => { route = { type: "home" }; notify() } }
}

test("CLI selection, working, retry, permission, question, and done states", async (t) => {
  const h = await setup(t)
  await h.expect("\u00b7")
  h.select()
  h.emit("session.execution.started", { sessionID: "root" })
  await h.expect(`${hammer} Investigating`)
  h.emit("session.status", { sessionID: "root", status: { type: "retry" } })
  h.emit("permission.asked", { sessionID: "root", id: "p1" })
  h.emit("session.status", { sessionID: "root", status: { type: "busy" } })
  await h.expect(`${bell} Investigating`)
  h.emit("permission.replied", { sessionID: "root", requestID: "p1" })
  await h.expect(`${hammer} Investigating`)
  h.emit("form.created", { form: { sessionID: "root", id: "q1" } })
  await h.expect(`${bell} Investigating`)
  h.emit("form.replied", { sessionID: "root", id: "q1" })
  await h.expect(`${hammer} Investigating`)
  h.emit("session.execution.succeeded", { sessionID: "root" })
  await h.expect(`${check} Investigating`)
})

test("root completion cannot finish running children or grandchildren", async (t) => {
  const h = await setup(t)
  h.select()
  for (const sessionID of ["root", "child", "grandchild"]) h.emit("session.execution.started", { sessionID })
  h.emit("session.execution.succeeded", { sessionID: "root" })
  await h.expect(`${hammer} Investigating`)
  h.emit("session.execution.succeeded", { sessionID: "child" })
  await h.expect(`${hammer} Investigating`)
  h.emit("session.execution.succeeded", { sessionID: "grandchild" })
  await h.expect(`${check} Investigating`)
  h.emit("session.execution.started", { sessionID: "child" })
  await h.expect(`${hammer} Investigating`)
})

test("child completion cannot finish a working root; all prompts must resolve", async (t) => {
  const h = await setup(t)
  h.select()
  h.emit("session.execution.started", { sessionID: "root" })
  h.emit("session.execution.succeeded", { sessionID: "child" })
  await h.expect(`${hammer} Investigating`)
  h.emit("permission.asked", { sessionID: "child", id: "same" })
  h.emit("form.created", { form: { sessionID: "grandchild", id: "same" } })
  h.emit("permission.replied", { sessionID: "child", requestID: "same" })
  await h.expect(`${bell} Investigating`)
  h.emit("form.cancelled", { sessionID: "grandchild", id: "same" })
  await h.expect(`${hammer} Investigating`)
})

test("shell-only background work remains visible until every owned command stops", async (t) => {
  const h = await setup(t)
  h.select()
  h.emit("session.execution.started", { sessionID: "root" })
  h.shell("s1")
  h.shell("s2", "grandchild")
  h.shell("unrelated", "other")
  h.shell("unowned", "")
  await h.expect(`${hammer} Investigating`)
  h.emit("session.execution.succeeded", { sessionID: "root" })
  await h.expect(`${hourglass} Investigating`)
  h.emit("permission.asked", { sessionID: "child", id: "p1" })
  await h.expect(`${bell} Investigating`)
  h.emit("permission.replied", { sessionID: "child", requestID: "p1" })
  h.emit("shell.exited", { id: "s1", status: "exited", exit: 0 })
  await h.expect(`${hourglass} Investigating`)
  h.emit("shell.deleted", { id: "s2" })
  h.emit("shell.exited", { id: "unowned", status: "killed" })
  await h.expect(`${check} Investigating`)
})

test("shell timeout, kill, and nonzero exit stop shell activity without declaring the agent failed", async (t) => {
  const h = await setup(t)
  h.select()
  for (const status of ["timeout", "killed", "exited"]) {
    h.shell("s1")
    await h.expect(`${hourglass} Investigating`)
    h.emit("shell.exited", { id: "s1", status, exit: 1 })
    await h.expect(`${check} Investigating`)
  }
})

test("selection follows the viewed family, not unrelated shared-server activity", async (t) => {
  const h = await setup(t)
  h.select()
  h.emit("session.execution.started", { sessionID: "other" })
  h.emit("permission.asked", { sessionID: "other", id: "p1" })
  await h.expect(`${check} Investigating`)
  h.select("other")
  await h.expect(`${bell} Fix`)
  h.select("grandchild")
  await h.expect(`${check} Investigating`)
  h.home()
  await h.expect("\u00b7")
})

test("initial selection hydrates pre-existing nested agents and worktree shells, with no polling", async (t) => {
  const h = await setup(t, { unknown: ["child", "grandchild"], statuses: { grandchild: "running" } })
  const ref = { directory: "/different-worktree" }
  h.sessions.get("grandchild").location = ref
  h.select()
  await h.expect(`${hammer} Investigating`)
  assert.ok(h.reads.some(([kind, id]) => kind === "children" && id === "child"))
  h.emit("session.execution.succeeded", { sessionID: "grandchild" }, ref)
  h.shell("s1", "grandchild", ref)
  await h.expect(`${hourglass} Investigating`)
  const count = h.reads.length
  await delay(250)
  assert.equal(h.reads.length, count, "waiting does not repeatedly query the server")
  h.emit("shell.exited", { id: "s1", status: "exited" }, ref)
  await h.expect(`${check} Investigating`)
})

test("family hydration follows pagination", async (t) => {
  const h = await setup(t, {
    unknown: ["child", "grandchild"], statuses: { grandchild: "running" },
    list: async (input, sessions) => {
      if (input.parentID === "root") return { data: [sessions.get("child")], cursor: { next: "page2" } }
      if (input.cursor === "page2") return { data: [sessions.get("grandchild")], cursor: {} }
      return { data: [], cursor: {} }
    },
  })
  h.select()
  await h.expect(`${hammer} Investigating`)
  assert.ok(h.reads.some(([kind, value]) => kind === "children" && value === "page2"))
})

test("moving a session does not hide its shell still running in the old location", async (t) => {
  const h = await setup(t)
  h.select()
  h.shell("s1", "child")
  await h.expect(`${hourglass} Investigating`)
  h.sessions.get("child").location = { directory: "/moved-child" }
  h.emit("session.moved", { sessionID: "child" })
  await h.expect(`${hourglass} Investigating`)
  h.emit("server.connected", {})
  await h.expect(`${hourglass} Investigating`)
  h.emit("shell.exited", { id: "s1", status: "exited" })
  await h.expect(`${check} Investigating`)
})

test("terminal events clear cancelled prompts and failure stays sticky through idle/replies", async (t) => {
  const h = await setup(t)
  h.select()
  h.emit("form.created", { form: { sessionID: "root", id: "q1" } })
  h.emit("session.execution.interrupted", { sessionID: "root", reason: "user" })
  h.emit("session.status", { sessionID: "root", status: { type: "idle" } })
  await h.expect("! Investigating")
  h.emit("form.cancelled", { sessionID: "root", id: "q1" })
  await h.expect("! Investigating")
  h.emit("session.execution.started", { sessionID: "child" })
  await h.expect(`${hammer} Investigating`)
  h.emit("session.execution.failed", { sessionID: "child" })
  await h.expect("! Investigating")
  h.emit("session.execution.started", { sessionID: "root" })
  h.emit("session.execution.succeeded", { sessionID: "root" })
  await h.expect(`${check} Investigating`)
})

test("interruption of one child does not dismiss another child's prompt", async (t) => {
  const h = await setup(t)
  h.select()
  h.emit("permission.asked", { sessionID: "child", id: "p1" })
  h.emit("form.created", { form: { sessionID: "grandchild", id: "q1" } })
  h.emit("session.execution.interrupted", { sessionID: "child" })
  await h.expect(`${bell} Investigating`)
  h.emit("session.execution.succeeded", { sessionID: "grandchild" })
  await h.expect(`${check} Investigating`)
})

test("reconnect rehydrates missed activity instead of keeping stale event overrides", async (t) => {
  const h = await setup(t)
  h.select()
  h.emit("session.execution.started", { sessionID: "child" })
  await h.expect(`${hammer} Investigating`)
  h.statuses.set("child", "idle")
  h.emit("server.connected", {})
  await h.expect(`${check} Investigating`)
  assert.ok(h.reads.some(([kind]) => kind === "shell.invalidate"))
})

test("bounded Unicode titles are reactive without another execution event", async (t) => {
  const h = await setup(t)
  h.select()
  for (const [title, label] of [["  Refactoring\tfiles", "Refactoring"], ["A".repeat(50), "A".repeat(17) + "..."],
    ["\u{1f431}".repeat(21), "\u{1f431}".repeat(17) + "..."], ["", ""]]) {
    h.emit("session.renamed", { sessionID: "root", title })
    await h.expect(label ? `${check} ${label}` : check)
  }
})

test("targets the terminal pane's stable tab ID, follows moves, and restores both tabs", async (t) => {
  const h = await setup(t)
  h.select()
  await h.expect(`${check} Investigating`)
  assert.equal(await h.label(99), "plugin")
  await h.change((state) => {
    const pane = state.panes.find((item) => item.id === 4 && !item.is_plugin)
    Object.assign(pane, { tab_id: 12, tab_name: "hx" })
    state.panes.push({ id: 9, is_plugin: false, tab_id: 11, tab_name: `${check} Investigating` })
  })
  h.emit("session.execution.started", { sessionID: "root" })
  await h.expect(`${hammer} Investigating`, 12)
  assert.equal(await h.label(11), "original")
  assert.deepEqual(JSON.parse(await readFile(h.journal, "utf8")), [{ id: 12, original: "hx", last: `${hammer} Investigating` }])
  await h.dispose()
  assert.equal(await h.label(12), "hx")
  h.emit("session.execution.succeeded", { sessionID: "root" })
  await h.expect("hx", 12)
})

test("manual names survive cleanup and become the new restoration target after another update", async (t) => {
  const h = await setup(t)
  h.select()
  await h.expect(`${check} Investigating`)
  await h.change((state) => { state.panes.find((item) => item.tab_id === 11).tab_name = "manual" })
  h.emit("session.execution.started", { sessionID: "root" })
  await h.expect(`${hammer} Investigating`)
  await h.dispose()
  assert.equal(await h.label(), "manual")
})

test("a reload/crash journal preserves the original tab name", async (t) => {
  const h = await setup(t, {
    state: { panes: [{ id: 4, is_plugin: false, tab_id: 11, tab_name: "old status" }] },
    journal: [{ id: 11, original: "original", last: "old status" }],
  })
  h.select()
  await h.expect(`${check} Investigating`)
  await h.dispose()
  assert.equal(await h.label(), "original")
})

test("a failed rename does not turn the previous generated title into the original name", async (t) => {
  const h = await setup(t)
  h.select()
  await h.expect(`${check} Investigating`)
  await h.change((state) => { state.failRename = true })
  h.emit("session.execution.started", { sessionID: "root" })
  await h.expect(`${check} Investigating`)
  await h.change((state) => { state.failRename = false })
  h.notify()
  await h.expect(`${hammer} Investigating`)
  await h.dispose()
  assert.equal(await h.label(), "original")
})

test("Zellij failures do not break event processing; bursts are coalesced", async (t) => {
  const h = await setup(t, { state: { fail: true } })
  h.select()
  await h.flush()
  await h.change((state) => { state.fail = false; state.invalid = true })
  h.notify()
  await h.flush()
  await h.change((state) => { state.invalid = false })
  for (let i = 0; i < 100; i++) h.emit("session.execution.started", { sessionID: "root" })
  h.emit("permission.asked", { sessionID: "child", id: "p1" })
  await h.expect(`${bell} Investigating`)
  const renames = (await h.state()).commands.filter(([action]) => action === "rename-tab")
  assert.ok(renames.length <= 2, `burst caused ${renames.length} renames`)
})

test("the CLI plugin cannot run outside the launcher or in nested tool processes", async (t) => {
  const h = await setup(t)
  for (const [key, value] of [["OPENCODE_ZELLIJ_STATUS", "0"], ["OPENCODE_ZELLIJ_STATUS", ""],
    ["OPENCODE", "1"], ["OPENCODE_SESSION_ID", "parent"], ["ZELLIJ_PANE_ID", "invalid"]]) {
    const previous = process.env[key]
    process.env[key] = value
    assert.equal(await setupZellijStatus(h.context, () => assert.fail("must not register")), undefined)
    process.env[key] = previous
  }
})

test("deleting the selected root clears its title and ending a child removes its activity", async (t) => {
  const h = await setup(t)
  h.select()
  h.emit("session.execution.started", { sessionID: "child" })
  h.emit("session.deleted", { sessionID: "child" })
  await h.expect(`${check} Investigating`)
  h.emit("session.deleted", { sessionID: "root" })
  await h.expect("\u00b7")
})
