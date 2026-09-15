import process from "node:process";
import { sessionCostUsd } from "../src/cost.ts";
import { defaultQuestionSet } from "../src/default-question-set.ts";
import { runSession } from "../src/session.ts";
import { PROTOCOL_RUNS } from "./benchmark-config.ts";
import type { CatalogModel } from "./catalog.ts";
import { scriptedClient } from "./harness.ts";
import { fullSessionAnswers } from "./scenarios.ts";

// The protocol half of the benchmark: replay the full question set N times and
// record what each run cost, how fast it was, and whether it held the protocol.

export type ProtocolStats = {
  passes: number;
  crashes: number;
  latencies: number[];
  costs: number[];
  cachedShares: number[];
};

const CRASH_RETRIES = 1;

export const emptyProtocolStats = (): ProtocolStats => ({
  passes: 0,
  crashes: 0,
  latencies: [],
  costs: [],
  cachedShares: [],
});

/** Per-question protocol violations; empty means the run passed. */
export function protocolViolations(
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

export async function runProtocol(
  id: string,
  rates: CatalogModel | undefined,
): Promise<ProtocolStats> {
  const stats = emptyProtocolStats();
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
