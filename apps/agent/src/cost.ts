export type ModelRates = {
  /** USD per million input tokens */
  inputPerM: number;
  /** USD per million output tokens */
  outputPerM: number;
};

// Verified against the gateway model catalog on 2026-08-20; re-verify in #4's
// benchmark rather than trusting these to stay current.
export const MODEL_RATES: Record<string, ModelRates> = {
  "zai/glm-4.7-flash": { inputPerM: 0.07, outputPerM: 0.4 },
};

export function sessionCostUsd(
  usages: Array<{ inputTokens: number; outputTokens: number }>,
  rates: ModelRates,
): number {
  const input = usages.reduce((sum, u) => sum + u.inputTokens, 0);
  const output = usages.reduce((sum, u) => sum + u.outputTokens, 0);
  return (input * rates.inputPerM + output * rates.outputPerM) / 1_000_000;
}
