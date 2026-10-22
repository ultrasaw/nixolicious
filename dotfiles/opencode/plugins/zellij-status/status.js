import { execFile } from "node:child_process"
import { readFile, rename as renameFile, rm, writeFile } from "node:fs/promises"
import { promisify } from "node:util"

const exec = promisify(execFile)
const locationKey = (location) => JSON.stringify([location.directory, location.workspaceID])

export async function setupZellijStatus({ data, client, ui }, watch) {
  const sessionName = process.env.ZELLIJ_SESSION_NAME
  const paneID = process.env.ZELLIJ_PANE_ID
  const stateFile = process.env.OPENCODE_ZELLIJ_STATE
  if (process.env.OPENCODE_ZELLIJ_STATUS !== "1" || !sessionName || !/^\d+$/.test(paneID ?? "") ||
      !stateFile || process.env.OPENCODE === "1" || process.env.OPENCODE_SESSION_ID) return

  const tabs = new Map()
  const statuses = new Map()
  const outcomes = new Map()
  const dismissed = new Set()
  const hydrated = new Set()
  const families = new Set()
  const locations = new Map()
  const controller = new AbortController()
  let disposed = false
  let timer
  let running = false
  let dirty = false
  let name = "\u00b7"
  let queue = Promise.resolve()

  const zellij = async (...args) => {
    const { stdout } = await exec("zellij", ["--session", sessionName, "action", ...args], {
      timeout: 2000,
      maxBuffer: 1024 * 1024,
    })
    return stdout
  }
  const panes = async () => JSON.parse(await zellij("list-panes", "--json", "--tab"))
  const rename = (id, title) => zellij("rename-tab", "--tab-id", String(id), "--", title)
  const persist = async () => {
    await writeFile(`${stateFile}.tmp`, JSON.stringify(Array.from(tabs, ([id, saved]) => ({ id, ...saved }))), { mode: 0o600 })
    await renameFile(`${stateFile}.tmp`, stateFile)
  }

  // A reload can inherit the launcher's ownership journal, including a rename
  // whose previous plugin instance did not manage to restore it.
  try {
    for (const { id, original, last } of JSON.parse(await readFile(stateFile, "utf8"))) {
      if (Number.isInteger(id) && typeof original === "string" && typeof last === "string") {
        tabs.set(id, { original, last })
      }
    }
  } catch {
    // The launcher initially supplies an empty file.
  }

  async function render() {
    const title = name
    const list = await panes()
    const pane = list.find((item) => !item.is_plugin && item.id === Number(paneID))
    if (!pane || pane.tab_id == null || disposed) return
    for (const [id, saved] of tabs) {
      if (id === pane.tab_id) continue
      if (list.some((item) => item.tab_id === id && item.tab_name === saved.last)) {
        await rename(id, saved.original)
      }
      tabs.delete(id)
    }
    let saved = tabs.get(pane.tab_id)
    if (!saved) tabs.set(pane.tab_id, saved = { original: pane.tab_name })
    else if (pane.tab_name !== saved.last) saved.original = pane.tab_name
    const previous = saved.last
    saved.last = title
    // Journal before renaming: a crash between the two cannot strand a title
    // that the launcher does not know it owns.
    try {
      await persist()
    } catch (error) {
      saved.last = previous
      throw error
    }
    // Once journaled, finish this rename even during teardown. Cleanup waits
    // for the writer before restoring, so it must see the journaled title.
    if (pane.tab_name !== title) {
      try {
        await rename(pane.tab_id, title)
      } catch {
        // Do not mistake the old generated name for a manual rename on retry.
        // A timeout may have applied the rename: inspect before rolling back.
        try {
          const current = await panes()
          if (current.some((item) => !item.is_plugin && item.id === Number(paneID) && item.tab_id === pane.tab_id && item.tab_name === pane.tab_name)) {
            saved.last = previous
            await persist()
          }
        } catch {
          // Keep the prospective journal for the launcher's best-effort cleanup.
        }
      }
    }
  }

  function schedule() {
    dirty = true
    if (disposed || running || timer) return
    timer = setTimeout(async () => {
      timer = undefined
      if (disposed) return
      running = true
      dirty = false
      // Only one writer, with at most one trailing render. Slow Zellij calls
      // never block OpenCode's event listener or build up a queue of renames.
      queue = render().catch(() => {})
      await queue
      running = false
      if (dirty) schedule()
    }, 50)
  }

  function hydrate(key, load) {
    if (disposed || hydrated.has(key)) return
    hydrated.add(key)
    void Promise.resolve().then(load).catch(() => {
      hydrated.delete(key)
    }).then(() => {
      if (!disposed) update(false)
    })
  }

  // Discover descendants once on selection/reconnection, including nested
  // agents which were already running before this TUI attached. These are
  // initial reads, not a timer or polling loop; live updates use the UI cache.
  function hydrateFamily(rootID) {
    if (families.has(rootID)) return
    families.add(rootID)
    void (async () => {
      const ids = new Set([rootID])
      for (const parentID of ids) {
        let cursor
        do {
          if (disposed) return
          const page = await client.session.list(cursor ? { cursor, limit: 100 } : { parentID, limit: 100 }, {
            signal: controller.signal,
          })
          for (const child of page.data) {
            if (ids.has(child.id)) continue
            ids.add(child.id)
            await data.session.sync(child.id)
          }
          cursor = page.cursor.next
        } while (cursor)
      }
    })().catch(() => families.delete(rootID))
  }

  function requests(id) {
    return [
      ...(data.session.permission.list(id) ?? []).map((item) => `permission:${id}:${item.id}`),
      ...(data.session.form.list(id) ?? []).map((item) => `form:${id}:${item.id}`),
    ]
  }

  function update(sync = true) {
    if (disposed) return
    const route = ui.router.current()
    const rootID = route.type === "session" ? data.session.root(route.sessionID) : undefined
    const root = rootID && data.session.get(rootID)
    const ids = rootID ? new Set([rootID, ...data.session.family(rootID)]) : new Set()
    let attention = false
    let busy = false
    for (const id of ids) {
      const info = data.session.get(id)
      if (info?.location) locations.set(locationKey(info.location), info.location)
      attention ||= requests(id).some((key) => !dismissed.has(key))
      busy ||= (statuses.get(id) ?? data.session.status(id)) === "running"
      if (sync) {
        hydrate(`session:${id}`, () => data.session.sync(id))
        hydrate(`permission:${id}`, () => data.session.permission.sync(id))
        hydrate(`form:${id}`, () => data.session.form.sync(id))
      }
    }
    let shell = false
    for (const [key, location] of locations) {
      shell ||= data.shell.list(location).some((item) => item.status === "running" && ids.has(item.metadata.sessionID))
      if (sync) hydrate(`shell:${key}`, () => data.shell.sync(location))
    }
    if (sync && root) hydrateFamily(rootID)
    const outcome = outcomes.has(rootID) ? outcomes.get(rootID) : root?.outcome
    const icon = attention ? "\u{1f514}" : busy ? "\u{1f528}" : shell ? "\u23f3" :
      ["failed", "interrupted"].includes(outcome) ? "!" : root ? "\u2713" : "\u00b7"
    const word = Array.from((root?.title ?? "").replace(/[\u0000-\u001f\u007f-\u009f]/g, " ").trim().split(/\s+/u)[0])
    const label = word.length > 20 ? word.slice(0, 17).join("") + "..." : word.join("")
    name = label ? `${icon} ${label}` : icon
    schedule()
  }

  const stopEvents = data.listen(({ details: { type, data: props, location } }) => {
    if (disposed) return
    if (type === "server.connected") {
      // The client refreshes active executions on reconnect. Also refresh our
      // one-shot reads, so missed shell exits/prompts do not remain sticky.
      statuses.clear()
      outcomes.clear()
      dismissed.clear()
      hydrated.clear()
      families.clear()
      for (const ref of locations.values()) data.shell.invalidate(ref)
      for (const info of data.session.list()) {
        data.session.permission.invalidate(info.id)
        data.session.form.invalidate(info.id)
        if (info.location) data.shell.invalidate(info.location)
      }
    } else if (type === "session.execution.started" || (type === "session.status" && ["busy", "retry"].includes(props.status.type))) {
      statuses.set(props.sessionID, "running")
      outcomes.set(props.sessionID, undefined)
    } else if (["session.execution.succeeded", "session.execution.failed", "session.execution.interrupted", "session.idle"].includes(type) ||
        (type === "session.status" && props.status.type === "idle")) {
      statuses.set(props.sessionID, "idle")
      if (type.startsWith("session.execution.")) outcomes.set(props.sessionID, type.slice("session.execution.".length))
      for (const key of requests(props.sessionID)) dismissed.add(key)
    } else if (type === "session.deleted") {
      statuses.delete(props.sessionID)
      outcomes.delete(props.sessionID)
    } else if (type === "permission.asked") {
      dismissed.delete(`permission:${props.sessionID}:${props.id}`)
    } else if (type === "form.created") {
      dismissed.delete(`form:${props.form.sessionID}:${props.form.id}`)
    } else if (type === "shell.created") {
      const route = ui.router.current()
      const owner = props.info.metadata.sessionID
      if (location && owner && route.type === "session" && data.session.root(owner) === data.session.root(route.sessionID)) {
        locations.set(locationKey(location), location)
      }
    } else if (!/^(session\.(created|renamed|moved)|shell\.(created|exited|deleted)|permission\.replied|form\.(replied|cancelled))$/.test(type)) {
      return
    }
    // No directory filter: descendants can move to another worktree. The
    // selected root's family and shell metadata decide ownership instead.
    // Remember old locations too: a running shell can outlive a session move.
    update()
  })
  const stopWatch = watch(update)
  update()

  return async () => {
    if (disposed) return
    disposed = true
    clearTimeout(timer)
    controller.abort()
    stopEvents()
    stopWatch()
    await queue
    try {
      const list = await panes()
      for (const [id, saved] of tabs) {
        if (list.some((item) => item.tab_id === id && item.tab_name === saved.last)) {
          await rename(id, saved.original)
        }
      }
    } catch {
      // The launcher also restores on exit if the TUI or Zellij closed first.
    }
    await rm(`${stateFile}.tmp`, { force: true }).catch(() => {})
  }
}
