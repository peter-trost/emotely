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

// Verified against the gateway model catalog on 2026-08-20; re-verify in #4's
// benchmark rather than trusting these to stay current.
export const MODEL_RATES: Record<string, ModelRates> = {
  "zai/glm-4.7-flash": { inputPerM: 0.07, outputPerM: 0.4 },
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
