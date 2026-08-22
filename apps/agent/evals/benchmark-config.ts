// Benchmark configuration + report types (leaf module: no local imports).

export const PROTOCOL_RUNS = 3;
export const SCENARIO_RUNS = 3;
export const SCENARIO_REQUIRED = 2;
export const SESSIONS_PER_MONTH = 30;
export const BUDGET_USD_PER_MONTH = 1.08; // ≈ €1
export const NEW_MODEL_WINDOW_DAYS = 30;
export const NEW_MODEL_MAX_INPUT_PER_M = 1;
export const NOT_MEASURED = Number.POSITIVE_INFINITY;

export type ModelReport = {
  id: string;
  protocolPasses: number;
  scenarioPasses: Record<string, number>;
  p50Ms: number;
  p95Ms: number;
  sessionCostUsd: number;
  cachedShare: number;
  eligible: boolean;
  reason: string;
};
