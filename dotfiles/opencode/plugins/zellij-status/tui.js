import { createEffect } from "solid-js"
import { setupZellijStatus } from "./status.js"

export default {
  id: "local.zellij-status",
  setup(context) {
    // Mount the effect in a Solid owner so route/cache changes are reactive and
    // OpenCode tears it down with the plugin. This slot draws nothing.
    return setupZellijStatus(context, (update) => context.ui.slot({
      append: "app",
      render() {
        createEffect(update)
        return null
      },
    }))
  },
}
