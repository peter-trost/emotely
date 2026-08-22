import {
  BUDGET_USD_PER_MONTH,
  type ModelReport,
  NEW_MODEL_MAX_INPUT_PER_M,
  NEW_MODEL_WINDOW_DAYS,
  NOT_MEASURED,
  PROTOCOL_RUNS,
  SCENARIO_REQUIRED,
  SCENARIO_RUNS,
  SESSIONS_PER_MONTH,
} from "./benchmark-config.ts";
import type { CatalogModel } from "./catalog.ts";
import { scenarios } from "./scenarios.ts";

const SECONDS_PER_DAY = 86_400;
const MS_PER_DAY = SECONDS_PER_DAY * 1000;
const PRICE_DECIMALS = 3;
const usdPerM = (v: number): string => `$${Number(v.toFixed(PRICE_DECIMALS))}`;

export function newModels(
  catalog: Map<string, CatalogModel>,
  known: Set<string>,
) {
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

export function renderReport(
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
