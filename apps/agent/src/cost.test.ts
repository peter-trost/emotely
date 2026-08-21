import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { MODEL_RATES, sessionCostUsd } from "./cost.ts";

describe("sessionCostUsd", () => {
  it("prices summed token usage at the model's per-million rates", () => {
    // Worked example: 100k in + 10k out at glm-4.7-flash rates
    // (0.07 $/M input, 0.40 $/M output, gateway catalog 2026-08-20)
    // = 0.1 * 0.07 + 0.01 * 0.40 = 0.007 + 0.004 = 0.011
    const usages = [
      { inputTokens: 60_000, outputTokens: 4_000 },
      { inputTokens: 40_000, outputTokens: 6_000 },
    ];
    const rates = MODEL_RATES["zai/glm-4.7-flash"];
    assert.ok(rates);
    assert.equal(sessionCostUsd(usages, rates), 0.011);
  });

  it("has no rates entry for unknown models", () => {
    assert.equal(MODEL_RATES["not/a-model"], undefined);
  });
});
