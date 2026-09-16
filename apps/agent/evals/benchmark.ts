import process from "node:process";
import { generateText } from "ai";
import {
  describeQualification,
  measureQualification,
  type ProviderQualification,
  qualificationReason,
} from "../src/provider-qualification.ts";
import {
  BUDGET_USD_PER_MONTH,
  type ModelReport,
  NOT_MEASURED,
  PROTOCOL_RUNS,
  SCENARIO_REQUIRED,
  SCENARIO_RUNS,
  SESSIONS_PER_MONTH,
} from "./benchmark-config.ts";
import {
  emptyProtocolStats,
  type ProtocolStats,
  runProtocol,
} from "./benchmark-protocol.ts";
import { newModels, renderReport } from "./benchmark-report.ts";
import { type CatalogModel, fetchCatalog } from "./catalog.ts";
import { runScenarioOnce } from "./harness.ts";
import { scenarios } from "./scenarios.ts";

// Model benchmark (ADR 0003 amendment): eligible = protocol 3/3, every
// behavior scenario 2-of-3, projected monthly cost within budget, and enough
// providers qualifying under ZDR + no-prompt-training; ranked by median
// per-round latency, cost as tiebreak. Progress on stderr, markdown report on
// stdout. Re-run monthly by .github/workflows/monthly-benchmark.yml.

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

function ineligibilityReasons(opts: {
  rates: CatalogModel | undefined;
  protocol: ProtocolStats;
  scenarioPasses: Record<string, number>;
  monthlyUsd: number;
  qualification: ProviderQualification;
}): string[] {
  const { rates, protocol, scenarioPasses, monthlyUsd, qualification } = opts;
  const reasons: string[] = [];
  if (!rates) {
    reasons.push("no catalog price");
  }
  // Both gateway privacy filters fail closed (ADR 0003 amendment), so a model
  // whose providers do not qualify cannot serve a single session — no latency
  // or cost number can redeem it. Listed first: it is the disqualifier that
  // says "never promote this", not "this scored badly".
  const qualificationProblem = qualificationReason(qualification);
  if (qualificationProblem !== undefined) {
    reasons.push(qualificationProblem);
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

const noScenarioPasses = (): Record<string, number> =>
  Object.fromEntries(scenarios.map((sc) => [sc.name, 0]));

async function benchmarkModel(
  id: string,
  rates: CatalogModel | undefined,
): Promise<ModelReport> {
  // Measured first, with one cheap round: a model the privacy filters refuse
  // cannot complete a protocol run either, and the failure would otherwise
  // surface as an unexplained crash after three full sessions of spend.
  const qualification = await measureQualification(id, (opts) =>
    generateText(opts),
  );
  const unservable = !qualification.served;
  const protocol = unservable
    ? emptyProtocolStats()
    : await runProtocol(id, rates);
  // A model that fails every protocol run (e.g. loops to the round cap) is
  // already ineligible; don't let it burn scenario budget or stall the pool.
  const scenarioPasses =
    protocol.passes === 0 ? noScenarioPasses() : await runScenarios(id);
  const sorted = [...protocol.latencies].sort((a, b) => a - b);
  const cost =
    protocol.costs.length === 0 ? NOT_MEASURED : median(protocol.costs);
  const reasons = ineligibilityReasons({
    rates,
    protocol,
    scenarioPasses,
    monthlyUsd: cost * SESSIONS_PER_MONTH,
    qualification,
  });
  return {
    id,
    protocolPasses: protocol.passes,
    scenarioPasses,
    p50Ms: percentile(sorted, P50),
    p95Ms: percentile(sorted, P95),
    sessionCostUsd: cost,
    cachedShare:
      protocol.cachedShares.length === 0 ? 0 : median(protocol.cachedShares),
    providerQualification: describeQualification(qualification),
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
