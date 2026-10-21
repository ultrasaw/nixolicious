// With the 20k compaction reserve in home/common.nix, this triggers at ~300k.
const MAX_INPUT_TOKENS = 320_000

export default {
  id: "local.context-limit",
  async setup({ model }) {
    await model.transform((editor) => {
      // Runs after discovery, including ChatGPT OAuth and canonical provider aliases.
      for (const candidate of editor.list()) {
        if (![candidate.providerID, candidate.canonical].some((id) => id === "openai" || id === "chatgpt") ||
            !candidate.id.startsWith("gpt-") || candidate.limit.context <= 0) continue
        editor.update(candidate.providerID, candidate.id, (model) => {
          model.limit.input = Math.min(model.limit.input || model.limit.context, MAX_INPUT_TOKENS)
        })
      }
    })
  },
}
