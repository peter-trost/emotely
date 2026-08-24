import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { MODEL_RATES, sessionCostUsd } from "./cost.ts";

describe("sessionCostUsd", () => {
  it("prices summed token usage at the model's per-million rates", () => {
    // Worked example: 100k in + 10k out at gpt-oss-120b rates
    // (0.10 $/M input, 0.50 $/M output, gateway catalog 2026-08-23)
    // = 0.1 * 0.10 + 0.01 * 0.50 = 0.010 + 0.005 = 0.015
    const usages = [
      { inputTokens: 60_000, cacheReadTokens: 0, outputTokens: 4000 },
      { inputTokens: 40_000, cacheReadTokens: 0, outputTokens: 6000 },
    ];
    const rates = MODEL_RATES["openai/gpt-oss-120b"];
    assert.ok(rates);
    assert.equal(sessionCostUsd(usages, rates), 0.015);
  });

  it("bills cache-read tokens at the cache rate, not the input rate", () => {
    // inputTokens is the TOTAL (inclusive of cache reads, per ai v7
    // LanguageModelUsage). 100k in of which 80k cached, 10k out at
    // in 0.10 / cache 0.01 / out 0.40 $/M:
    // 20k*0.10 + 80k*0.01 + 10k*0.40 = 2000 + 800 + 4000 = 6800 / 1M = 0.0068
    const usages = [
      { inputTokens: 100_000, cacheReadTokens: 80_000, outputTokens: 10_000 },
    ];
    const rates = { inputPerM: 0.1, cacheReadPerM: 0.01, outputPerM: 0.4 };
    assert.equal(sessionCostUsd(usages, rates), 0.0068);
  });

  it("bills cache reads at full input rate when a model publishes no cache rate", () => {
    const usages = [
      { inputTokens: 100_000, cacheReadTokens: 80_000, outputTokens: 0 },
    ];
    const rates = { inputPerM: 0.1, outputPerM: 0.4 };
    assert.equal(sessionCostUsd(usages, rates), 0.01);
  });

  it("has no rates entry for unknown models", () => {
    assert.equal(MODEL_RATES["not/a-model"], undefined);
  });
});
