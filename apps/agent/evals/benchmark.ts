import process from "node:process";
import { sessionCostUsd } from "../src/cost.ts";
import { defaultQuestionSet } from "../src/default-question-set.ts";
import { runSession } from "../src/session.ts";
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
const PROTOCOL_RUNS = 3;
const SCENARIO_RUNS = 3;
const SCENARIO_REQUIRED = 2;
const SESSIONS_PER_MONTH = 30;
const BUDGET_USD_PER_MONTH = 1.08; // ≈ €1
const NEW_MODEL_WINDOW_DAYS = 30;
const NEW_MODEL_MAX_INPUT_PER_M = 1;
const CONCURRENCY = 3;
const SECONDS_PER_DAY = 86_400;
const MS_PER_DAY = SECONDS_PER_DAY * 1000;
const P50 = 0.5;
const P95 = 0.95;
const NOT_MEASURED = Number.POSITIVE_INFINITY;

type ModelReport = {
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

const PRICE_DECIMALS = 3;
const usdPerM = (v: number): string => `$${Number(v.toFixed(PRICE_DECIMALS))}`;

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

function protocolOk(
  answers: Record<string, { answer_type: string; value: unknown }>,
): boolean {
  return defaultQuestionSet.questions.every((q) => {
    const recorded = answers[q.id];
    if (!recorded || recorded.answer_type !== q.answer_type) {
      return false;
    }
    return (
      q.min_answers === undefined ||
      (Array.isArray(recorded.value) && recorded.value.length >= q.min_answers)
    );
  });
}

type ProtocolStats = {
  passes: number;
  latencies: number[];
  costs: number[];
  cachedShares: number[];
};

async function runProtocol(
  id: string,
  rates: CatalogModel | undefined,
): Promise<ProtocolStats> {
  const stats: ProtocolStats = {
    passes: 0,
    latencies: [],
    costs: [],
    cachedShares: [],
  };
  for (let i = 0; i < PROTOCOL_RUNS; i++) {
    try {
      const result = await runSession({
        questionSet: defaultQuestionSet,
        client: scriptedClient(fullSessionAnswers),
        model: id,
        temperature: 0,
      });
      stats.latencies.push(...result.roundLatenciesMs);
      if (rates) {
        stats.costs.push(sessionCostUsd([result.usage], rates));
      }
      stats.cachedShares.push(
        result.usage.inputTokens === 0
          ? 0
          : result.usage.cacheReadTokens / result.usage.inputTokens,
      );
      if (protocolOk(result.answers)) {
        stats.passes++;
      }
    } catch (err) {
      process.stderr.write(`  ${id} protocol run crashed: ${String(err)}\n`);
    }
  }
  return stats;
}

async function runScenarios(id: string): Promise<Record<string, number>> {
  const passes: Record<string, number> = {};
  for (const scenario of scenarios) {
    let count = 0;
    for (let i = 0; i < SCENARIO_RUNS; i++) {
      if ((await runScenarioOnce(scenario, id)) === null) {
        count++;
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
  if (monthlyUsd > BUDGET_USD_PER_MONTH) {
    reasons.push(`$${monthlyUsd.toFixed(2)}/month over budget`);
  }
  return reasons;
}

async function benchmarkModel(
  id: string,
  rates: CatalogModel | undefined,
): Promise<ModelReport> {
  const protocol = await runProtocol(id, rates);
  const scenarioPasses = await runScenarios(id);
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

function newModels(catalog: Map<string, CatalogModel>, known: Set<string>) {
  const cutoff = (Date.now() - NEW_MODEL_WINDOW_DAYS * MS_PER_DAY) / 1000;
  return [...catalog.values()]
    .filter(
      (m) =>
        !known.has(m.id) &&
        m.tags.includes("tool-use") &&
        m.released >= cutoff &&
        m.inputPerM <= NEW_MODEL_MAX_INPUT_PER_M,
    )
    .sort((a, b) => a.inputPerM - b.inputPerM);
}

function renderReport(
  reports: ModelReport[],
  fresh: CatalogModel[],
  promptId: string,
): string {
  const rank = (r: ModelReport): [number, number, number] => [
    r.eligible ? 0 : 1,
    r.p50Ms,
    r.sessionCostUsd,
  ];
  const sorted = [...reports].sort((a, b) => {
    const [ea, pa, ca] = rank(a);
    const [eb, pb, cb] = rank(b);
    return ea - eb || pa - pb || ca - cb;
  });
  const ms = (v: number) => (v === NOT_MEASURED ? "—" : `${Math.round(v)}`);
  const usd = (v: number) => (v === NOT_MEASURED ? "—" : `$${v.toFixed(4)}`);
  const pct = (v: number) => `${Math.round(v * 100)}%`;
  const lines = [
    `## Model benchmark — ${new Date().toISOString().slice(0, 10)}, prompt ${promptId}`,
    "",
    `Eligible = protocol ${PROTOCOL_RUNS}/${PROTOCOL_RUNS}, every scenario ≥ ${SCENARIO_REQUIRED}/${SCENARIO_RUNS}, ≤ $${BUDGET_USD_PER_MONTH}/month at ${SESSIONS_PER_MONTH} sessions. Ranked by p50 round latency, cost as tiebreak.`,
    "",
    "| # | Model | Eligible | p50 ms | p95 ms | $/session | $/month | cached | Protocol | Scenarios | Notes |",
    "|---|---|---|---|---|---|---|---|---|---|---|",
    ...sorted.map((r, i) => {
      const scen = Object.values(r.scenarioPasses).join("/");
      const monthly =
        r.sessionCostUsd === NOT_MEASURED
          ? "—"
          : `$${(r.sessionCostUsd * SESSIONS_PER_MONTH).toFixed(2)}`;
      return `| ${i + 1} | \`${r.id}\` | ${r.eligible ? "✅" : "❌"} | ${ms(r.p50Ms)} | ${ms(r.p95Ms)} | ${usd(r.sessionCostUsd)} | ${monthly} | ${pct(r.cachedShare)} | ${r.protocolPasses}/${PROTOCOL_RUNS} | ${scen} | ${r.reason} |`;
    }),
    "",
    `Scenarios column order: ${scenarios.map((s) => s.name.split(":")[0]).join(" / ")}.`,
    "",
    `### New tool-capable models in the catalog (last ${NEW_MODEL_WINDOW_DAYS} days, ≤ $${NEW_MODEL_MAX_INPUT_PER_M}/M input)`,
    "",
    fresh.length === 0
      ? "_none_"
      : fresh
          .map(
            (m) =>
              `- \`${m.id}\` — ${usdPerM(m.inputPerM)}/M in, ${usdPerM(m.outputPerM)}/M out, released ${new Date(m.released * 1000).toISOString().slice(0, 10)}`,
          )
          .join("\n"),
  ];
  return lines.join("\n");
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
    `  ${id}: ${report.eligible ? "eligible" : report.reason} p50=${Math.round(report.p50Ms)}ms\n`,
  );
  return report;
});

const { PROMPT_ID } = await import("../src/session-prompt.ts");
process.stdout.write(
  `${renderReport(benchmarkReports, newModels(liveCatalog, new Set(models)), PROMPT_ID)}\n`,
);
