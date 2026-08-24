import process from "node:process";
import { sessionCostUsd } from "../src/cost.ts";
import { defaultQuestionSet } from "../src/default-question-set.ts";
import { runSession } from "../src/session.ts";
import {
  BUDGET_USD_PER_MONTH,
  type ModelReport,
  NOT_MEASURED,
  PROTOCOL_RUNS,
  SCENARIO_REQUIRED,
  SCENARIO_RUNS,
  SESSIONS_PER_MONTH,
} from "./benchmark-config.ts";
import { newModels, renderReport } from "./benchmark-report.ts";
import { type CatalogModel, fetchCatalog } from "./catalog.ts";
import { runScenarioOnce, scriptedClient } from "./harness.ts";
import { fullSessionAnswers, scenarios } from "./scenarios.ts";

// Model benchmark (ADR 0003 amendment): eligible = protocol 3/3, every
// behavior scenario 2-of-3, projected monthly cost within budget; ranked by
// median per-round latency, cost as tiebreak. Progress on stderr, markdown
// report on stdout. Re-run monthly by .github/workflows/monthly-benchmark.yml.

const DEFAULT_CANDIDATES = [
  // cheap tier
  "alibaba/qwen3.7-flash",
  "zai/glm-4.7-flash",
  "deepseek/deepseek-v4-flash",
  "google/gemini-2.5-flash-lite",
  "nvidia/nemotron-3.5-lightning",
  "openai/gpt-5-nano",
  "openai/gpt-oss-120b",
  // fast / reliable tier
  "openai/gpt-5.6-luna",
  "openai/gpt-5.6-luna-fast",
  "anthropic/claude-haiku-4.5",
  "google/gemini-3.7-flash",
  "openai/gpt-5-mini",
];
const CONCURRENCY = 3;
const P50 = 0.5;
const P95 = 0.95;

const percentile = (sorted: number[], p: number): number =>
  sorted.length === 0
    ? NOT_MEASURED
    : (sorted[Math.min(sorted.length - 1, Math.floor(sorted.length * p))] ??
      NOT_MEASURED);

const median = (values: number[]): number =>
  percentile(
    [...values].sort((a, b) => a - b),
    P50,
  );

/** Per-question protocol violations; empty means the run passed. */
function protocolViolations(
  answers: Record<string, { answer_type: string; value: unknown }>,
  asked: Set<string>,
): string[] {
  const violations: string[] = [];
  for (const q of defaultQuestionSet.questions) {
    const recorded = answers[q.id];
    if (!asked.has(q.id)) {
      violations.push(
        `${q.id}: ${recorded ? "answered without asking" : "never asked"}`,
      );
    } else if (!recorded) {
      violations.push(`${q.id}: unanswered`);
    } else if (recorded.answer_type !== q.answer_type) {
      violations.push(`${q.id}: ${recorded.answer_type} ≠ ${q.answer_type}`);
    } else if (
      q.min_answers !== undefined &&
      !(Array.isArray(recorded.value) && recorded.value.length >= q.min_answers)
    ) {
      violations.push(`${q.id}: fewer than ${q.min_answers} answers`);
    }
  }
  return violations;
}

type ProtocolStats = {
  passes: number;
  crashes: number;
  latencies: number[];
  costs: number[];
  cachedShares: number[];
};

const CRASH_RETRIES = 1;

async function runProtocol(
  id: string,
  rates: CatalogModel | undefined,
): Promise<ProtocolStats> {
  const stats: ProtocolStats = {
    passes: 0,
    crashes: 0,
    latencies: [],
    costs: [],
    cachedShares: [],
  };
  for (let i = 0; i < PROTOCOL_RUNS; i++) {
    try {
      // Gateway 503s and malformed tool calls are retried once so an
      // infrastructure blip does not decide eligibility.
      const client = scriptedClient(fullSessionAnswers);
      const result = await withCrashRetry(id, () =>
        runSession({
          questionSet: defaultQuestionSet,
          client,
          model: id,
          temperature: 0,
        }),
      );
      stats.latencies.push(...result.roundLatenciesMs);
      if (rates) {
        stats.costs.push(sessionCostUsd([result.usage], rates));
      }
      stats.cachedShares.push(
        result.usage.inputTokens === 0
          ? 0
          : result.usage.cacheReadTokens / result.usage.inputTokens,
      );
      const violations = protocolViolations(result.answers, client.asked);
      if (violations.length === 0) {
        stats.passes++;
      } else {
        process.stderr.write(
          `  ${id} protocol violations: ${violations.join(", ")}\n`,
        );
      }
    } catch (err) {
      stats.crashes++;
      process.stderr.write(`  ${id} protocol run crashed: ${String(err)}\n`);
    }
  }
  return stats;
}

async function withCrashRetry<T>(
  id: string,
  attempt: () => Promise<T>,
): Promise<T> {
  let lastError: unknown;
  for (let tries = 0; tries <= CRASH_RETRIES; tries++) {
    try {
      return await attempt();
    } catch (err) {
      lastError = err;
      process.stderr.write(`  ${id} crashed, retrying: ${String(err)}\n`);
    }
  }
  throw lastError;
}

async function runScenarios(id: string): Promise<Record<string, number>> {
  const passes: Record<string, number> = {};
  for (const scenario of scenarios) {
    let count = 0;
    for (let i = 0; i < SCENARIO_RUNS; i++) {
      let failure = await runScenarioOnce(scenario, id);
      if (failure?.startsWith("session crashed")) {
        failure = await runScenarioOnce(scenario, id);
      }
      if (failure === null) {
        count++;
      } else {
        process.stderr.write(
          `  ${id} ${scenario.name.split(":")[0]} run ${i + 1}: ${failure}\n`,
        );
      }
    }
    passes[scenario.name] = count;
  }
  return passes;
}

function ineligibilityReasons(
  rates: CatalogModel | undefined,
  protocol: ProtocolStats,
  scenarioPasses: Record<string, number>,
  monthlyUsd: number,
): string[] {
  const reasons: string[] = [];
  if (!rates) {
    reasons.push("no catalog price");
  }
  if (protocol.passes < PROTOCOL_RUNS) {
    reasons.push(`protocol ${protocol.passes}/${PROTOCOL_RUNS}`);
  }
  for (const [name, passes] of Object.entries(scenarioPasses)) {
    if (passes < SCENARIO_REQUIRED) {
      reasons.push(`${name.split(":")[0]} ${passes}/${SCENARIO_RUNS}`);
    }
  }
  if (monthlyUsd !== NOT_MEASURED && monthlyUsd > BUDGET_USD_PER_MONTH) {
    reasons.push(`$${monthlyUsd.toFixed(2)}/month over budget`);
  }
  if (protocol.crashes > 0) {
    reasons.push(`${protocol.crashes} protocol run(s) crashed after retry`);
  }
  return reasons;
}

async function benchmarkModel(
  id: string,
  rates: CatalogModel | undefined,
): Promise<ModelReport> {
  const protocol = await runProtocol(id, rates);
  // A model that fails every protocol run (e.g. loops to the round cap) is
  // already ineligible; don't let it burn scenario budget or stall the pool.
  const scenarioPasses =
    protocol.passes === 0
      ? Object.fromEntries(scenarios.map((sc) => [sc.name, 0]))
      : await runScenarios(id);
  const sorted = [...protocol.latencies].sort((a, b) => a - b);
  const cost =
    protocol.costs.length === 0 ? NOT_MEASURED : median(protocol.costs);
  const reasons = ineligibilityReasons(
    rates,
    protocol,
    scenarioPasses,
    cost * SESSIONS_PER_MONTH,
  );
  return {
    id,
    protocolPasses: protocol.passes,
    scenarioPasses,
    p50Ms: percentile(sorted, P50),
    p95Ms: percentile(sorted, P95),
    sessionCostUsd: cost,
    cachedShare:
      protocol.cachedShares.length === 0 ? 0 : median(protocol.cachedShares),
    eligible: reasons.length === 0,
    reason: reasons.join(", "),
  };
}

async function runPool<T, R>(
  items: T[],
  worker: (item: T) => Promise<R>,
): Promise<R[]> {
  const results: R[] = [];
  let next = 0;
  const lanes = Array.from({ length: CONCURRENCY }, async () => {
    while (next < items.length) {
      const index = next++;
      const item = items[index];
      if (item !== undefined) {
        results[index] = await worker(item);
      }
    }
  });
  await Promise.all(lanes);
  return results;
}

const candidates = (process.env["EMOTELY_BENCH_MODELS"] ?? "")
  .split(",")
  .map((s) => s.trim())
  .filter(Boolean);
const models = candidates.length > 0 ? candidates : DEFAULT_CANDIDATES;

const liveCatalog = await fetchCatalog();
const benchmarkReports = await runPool(models, async (id) => {
  process.stderr.write(`benchmarking ${id}…\n`);
  const report = await benchmarkModel(id, liveCatalog.get(id));
  process.stderr.write(
    `  ${id}: ${report.eligible ? "eligible" : report.reason} p50=${report.p50Ms === NOT_MEASURED ? "—" : `${Math.round(report.p50Ms)}ms`}\n`,
  );
  return report;
});

const { PROMPT_ID } = await import("../src/session-prompt.ts");
process.stdout.write(
  `${renderReport(benchmarkReports, newModels(liveCatalog, new Set(models)), PROMPT_ID)}\n`,
);
