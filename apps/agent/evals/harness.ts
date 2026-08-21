import type { JSONValue, ModelMessage } from "ai";
import type { SessionClient } from "../src/session.ts";

try {
  process.loadEnvFile(new URL("../.env.local", import.meta.url).pathname);
} catch {
  // fine — CI provides the key via the environment
}

export const modelUnderTest = process.env.EMOTELY_MODEL ?? "zai/glm-4.7-flash";
// Judge: open source, cheap, and from a different family than the candidates
// it grades (avoids same-family self-preference). Benched 2026-08-21 for
// schema reliability + verdict quality: qwen3.7-plus 5/5 on both; deepseek
// v4-flash and gpt-oss-120b could not hold the verdict schema, qwen3.7-flash
// misjudged 4/5. $0.40/M in, $1.20/M out.
export const judgeModel =
  process.env.EMOTELY_JUDGE_MODEL ?? "alibaba/qwen3.7-plus";

/** Scripted user: answers each question from a canned map. */
export function scriptedClient(
  answers: Record<string, JSONValue>,
): SessionClient {
  return {
    askQuestion: async (input) => {
      const answer = answers[input.question_id];
      if (answer === undefined) {
        throw new Error(`fixture has no answer for ${input.question_id}`);
      }
      return answer;
    },
  };
}

/** Renders the session messages as plain text for the judge. */
export function formatTranscript(messages: ModelMessage[]): string {
  const lines: string[] = [];
  for (const m of messages) {
    if (typeof m.content === "string") {
      lines.push(`${m.role}: ${m.content}`);
      continue;
    }
    for (const part of m.content) {
      if (part.type === "text") lines.push(`${m.role}: ${part.text}`);
      else if (part.type === "tool-call")
        lines.push(
          `${m.role} [${part.toolName}]: ${JSON.stringify(part.input)}`,
        );
      else if (part.type === "tool-result")
        lines.push(
          `${m.role} [${part.toolName} result]: ${JSON.stringify(part.output)}`,
        );
    }
  }
  return lines.join("\n");
}

/** N runs with a 2/3 pass-rate gate (single runs must pass outright). */
export const evalRuns = Number(process.env.EVAL_RUNS ?? "1");
export const requiredPasses = Math.ceil((evalRuns * 2) / 3);
