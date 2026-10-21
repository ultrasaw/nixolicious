import { execFile } from "node:child_process"
import { writeFile } from "node:fs/promises"
import { promisify } from "node:util"

const exec = promisify(execFile)

export default { id: "local.zellij-status", setup: ZellijStatus }

async function ZellijStatus({ session: sessionAPI, shell, event: events, location: { directory } }) {
  const sessionName = process.env.ZELLIJ_SESSION_NAME
  const paneID = process.env.ZELLIJ_PANE_ID
  const stateFile = process.env.OPENCODE_ZELLIJ_STATE
  if (process.env.OPENCODE_ZELLIJ_STATUS !== "1" || !sessionName || !/^\d+$/.test(paneID ?? "") ||
      !stateFile || directory !== process.env.OPENCODE_ZELLIJ_DIRECTORY) return

  const sessions = new Map()
  const pending = new Map()
  const tabs = new Map()
  let activeSession
  let phase = "\u00b7"
  let disposed = false
  let queue = Promise.resolve()

  const zellij = async (...args) => {
    const { stdout } = await exec("zellij", ["--session", sessionName, "action", ...args], {
      timeout: 2000,
      maxBuffer: 1024 * 1024,
    })
    return stdout
  }
  const panes = async () => JSON.parse(await zellij("list-panes", "--json", "--tab"))
  const rename = (id, name) => zellij("rename-tab", "--tab-id", String(id), "--", name)

  // OpenCode dispatches hooks concurrently. Keep lookups and renames in event order,
  // and never let a notification failure propagate into the agent's work.
  const enqueue = (fn) => {
    queue = queue.then(() => disposed ? undefined : fn()).catch(() => {})
    return queue
  }

  async function session(id) {
    if (!sessions.has(id)) {
      const result = await sessionAPI.get({ sessionID: id })
      if (result) sessions.set(id, result)
    }
    return sessions.get(id)
  }

  async function root(id) {
    const visited = new Set()
    while (id && !visited.has(id)) {
      visited.add(id)
      const info = await session(id)
      if (!info) return undefined
      if (!info.parentID) return id
      id = info.parentID
    }
  }

  async function render() {
    let icon = phase
    for (const id of pending.values()) {
      if (await root(id) === activeSession) {
        icon = "\u{1f514}"
        break
      }
    }
    const title = sessions.get(activeSession)?.title ?? ""
    const word = Array.from(title.replace(/[\u0000-\u001f\u007f-\u009f]/g, " ").trim().split(/\s+/u)[0])
    const label = word.length > 20 ? word.slice(0, 17).join("") + "..." : word.join("")
    const name = label ? `${icon} ${label}` : icon
    const list = await panes()
    const pane = list.find((item) => !item.is_plugin && item.id === Number(paneID))
    if (!pane || pane.tab_id == null || disposed) return

    // A moved pane must not leave its old tab showing a stale status.
    for (const [id, saved] of tabs) {
      if (id === pane.tab_id) continue
      if (list.some((item) => item.tab_id === id && item.tab_name === saved.last)) {
        await rename(id, saved.original)
      }
      tabs.delete(id)
    }
    if (!tabs.has(pane.tab_id)) tabs.set(pane.tab_id, { original: pane.tab_name })
    if (pane.tab_name !== name) await rename(pane.tab_id, name)
    tabs.get(pane.tab_id).last = name
    await writeFile(stateFile, JSON.stringify(Array.from(tabs, ([id, saved]) => ({ id, ...saved }))))
  }

  await enqueue(render)

  const registrations = []
  const controller = new AbortController()
  registrations.push(await sessionAPI.hook("prompt", (input) => enqueue(async () => {
    if (await root(input.sessionID) !== input.sessionID) return
    activeSession = input.sessionID
    phase = "\u{1f528}"
    await render()
  })))

  // Nested CLI commands launched by tools should not inherit ownership of this tab.
  registrations.push(await shell.hook("create.before", (input) => {
    input.env.OPENCODE_ZELLIJ_STATUS = "0"
  }))

  const onEvent = (event) => {
      if (event.location && event.location.directory !== directory) return
      const { type, data: props } = event
      if (!["session.created", "session.renamed", "session.deleted", "session.status", "session.idle",
        "session.execution.failed", "session.execution.interrupted", "session.execution.started", "session.execution.succeeded",
        "permission.asked", "permission.replied", "form.created", "form.replied", "form.cancelled"].includes(type)) return

      return enqueue(async () => {
        if (type === "session.created" || type === "session.renamed") {
          if (type === "session.created") sessions.set(props.sessionID, { ...props, id: props.sessionID })
          else {
            const info = await session(props.sessionID)
            if (info) sessions.set(props.sessionID, { ...info, title: props.title })
          }
          if (props.sessionID === activeSession) await render()
          return
        }
        if (type === "session.deleted") {
          sessions.delete(props.sessionID)
          for (const [key, id] of pending) if (id === props.sessionID) pending.delete(key)
          if (props.sessionID === activeSession) {
            activeSession = undefined
            phase = "\u00b7"
            pending.clear()
          }
          await render()
          return
        }

        const owner = type === "form.created" ? props.form.sessionID : props.sessionID
        const rootID = await root(owner)
        if (!rootID) return
        // This is an activity indicator, not a TUI selection listener. Resumed
        // sessions are discovered on their first event; the prompt hook selects new work.
        activeSession ??= rootID
        let replied = false
        if (type === "permission.asked" || type === "form.created") {
          pending.set(type === "form.created" ? `form:${props.form.id}` : `permission:${props.id}`, owner)
        } else if (type.endsWith(".replied") || type === "form.cancelled") {
          replied = pending.delete(type.startsWith("form.") ? `form:${props.id}` : `permission:${props.requestID}`)
        }
        const failed = ["session.execution.failed", "session.execution.interrupted"].includes(type)
        const busy = type === "session.execution.started" || (type === "session.status" && ["busy", "retry"].includes(props.status.type))
        const idle = type === "session.execution.succeeded" || type === "session.idle" || (type === "session.status" && props.status.type === "idle")
        if (idle || failed) {
          // Cancellation can remove a question/permission without a reply event.
          for (const [key, id] of pending) if (id === owner) pending.delete(key)
        }
        if (busy && owner === rootID) {
          activeSession = rootID
        }
        if (rootID !== activeSession) return

        if (owner === activeSession) {
          if (failed) {
            phase = "!"
            for (const [key, id] of pending) if (await root(id) === activeSession) pending.delete(key)
          } else if (busy) {
            phase = "\u{1f528}"
          } else if (idle && phase !== "!") {
            phase = "\u2713"
          }
        }
        if (replied && phase !== "!") phase = "\u{1f528}"
        await render()
      })
    }

  // Subscribe before returning setup; events carry v2 data, not v1 properties.
  const listening = (async () => {
    try {
      for await (const event of events.subscribe({ signal: controller.signal })) await onEvent(event)
    } catch {
      // A closing server/event stream must not interfere with the session.
    }
  })()

  return async () => {
    disposed = true
    controller.abort()
    await Promise.all(registrations.map((registration) => registration.dispose()))
    await listening
    await queue
    try {
      const list = await panes()
      for (const [id, saved] of tabs) {
        if (list.some((item) => item.tab_id === id && item.tab_name === saved.last)) {
          await rename(id, saved.original)
        }
      }
    } catch {
      // The Zellij session may already have closed. The launcher also restores on exit.
    }
  }
}
