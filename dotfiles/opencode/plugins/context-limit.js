// With the 20k compaction reserve in home/common.nix, this triggers at ~300k.
const MAX_INPUT_TOKENS = 320_000

export default async function ContextLimit() {
  return {
    provider: {
      id: "openai",
      async models(provider) {
        // Runs after built-in model discovery, including ChatGPT OAuth aliases.
        for (const model of Object.values(provider.models)) {
          if (!model.id.startsWith("gpt-") || model.limit.context <= 0) continue
          model.limit.input = Math.min(model.limit.input || model.limit.context, MAX_INPUT_TOKENS)
        }
        return provider.models
      },
    },
  }
}
