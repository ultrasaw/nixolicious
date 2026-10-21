import assert from "node:assert/strict"
import test from "node:test"
import ContextLimit from "../dotfiles/opencode/plugins/context-limit.js"

test("caps discovered OpenAI and ChatGPT models without increasing smaller limits or changing other providers", async () => {
  const candidates = [
    { providerID: "openai", id: "gpt-large", limit: { context: 1_000_000, output: 64_000 } },
    { providerID: "chatgpt", id: "gpt-oauth", limit: { context: 1_000_000, input: 900_000, output: 32_000 } },
    { providerID: "alias", canonical: "openai", id: "gpt-alias", limit: { context: 400_000, input: 200_000 } },
    { providerID: "openai", id: "gpt-small", limit: { context: 128_000 } },
    { providerID: "openai", id: "gpt-unknown", limit: { context: 0 } },
    { providerID: "other", id: "gpt-other", limit: { context: 1_000_000 } },
    { providerID: "openai", id: "other-model", limit: { context: 1_000_000 } },
  ]
  const outputLimits = candidates.map((candidate) => candidate.limit.output)
  await ContextLimit.setup({ model: { transform: async (transform) => {
    transform({
      list: () => structuredClone(candidates),
      update: (providerID, id, update) => update(candidates.find((item) => item.providerID === providerID && item.id === id)),
    })
  } } })
  assert.deepEqual(candidates.map((candidate) => candidate.limit.input),
    [320_000, 320_000, 200_000, 128_000, undefined, undefined, undefined])
  assert.deepEqual(candidates.map((candidate) => candidate.limit.output), outputLimits)
})
