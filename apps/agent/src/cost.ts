export type ModelRates = {
  /** USD per million input tokens */
  inputPerM: number;
  /** USD per million cache-read input tokens; absent = billed at inputPerM */
  cacheReadPerM?: number;
  /** USD per million output tokens */
  outputPerM: number;
};

export type TokenUsage = {
  /** Total input tokens — INCLUSIVE of cacheReadTokens (ai v7 semantics). */
  inputTokens: number;
  cacheReadTokens: number;
  outputTokens: number;
};

// Rates for the default model only, verified against the gateway catalog on
// 2026-08-23; the benchmark reads live prices, this is for the PR-gate eval.
// gpt-oss-120b publishes no cache-read rate, so cached tokens bill at the
// input rate here (conservative — the live reading was 97% cached).
export const MODEL_RATES: Record<string, ModelRates> = {
  "openai/gpt-oss-120b": { inputPerM: 0.1, outputPerM: 0.5 },
};

const TOKENS_PER_MILLION = 1_000_000;

export function sessionCostUsd(
  usages: TokenUsage[],
  rates: ModelRates,
): number {
  const input = usages.reduce((sum, u) => sum + u.inputTokens, 0);
  const cached = usages.reduce((sum, u) => sum + u.cacheReadTokens, 0);
  const output = usages.reduce((sum, u) => sum + u.outputTokens, 0);
  const cacheRate = rates.cacheReadPerM ?? rates.inputPerM;
  return (
    ((input - cached) * rates.inputPerM +
      cached * cacheRate +
      output * rates.outputPerM) /
    TOKENS_PER_MILLION
  );
}
