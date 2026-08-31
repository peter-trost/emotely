import { randomUUID } from "node:crypto";
import process from "node:process";
import { createInterface } from "node:readline/promises";
import type { JSONValue } from "ai";
import { PostHog } from "posthog-node";
import { defaultQuestionSet } from "./default-question-set.ts";
import { runSession, type SessionClient } from "./session.ts";
import { resolveSessionConfig } from "./session-config.ts";
import { initTelemetry } from "./telemetry.ts";

try {
  process.loadEnvFile(new URL("../.env.local", import.meta.url).pathname);
} catch {
  // fine — key may come from the environment
}

const posthogKey = process.env["POSTHOG_KEY"];
const posthogHost = process.env["POSTHOG_HOST"] ?? "https://eu.i.posthog.com";
const shutdownTelemetry = initTelemetry(
  posthogKey
    ? { posthog: { projectToken: posthogKey, host: posthogHost } }
    : {},
);
const posthog = posthogKey
  ? new PostHog(posthogKey, {
      host: posthogHost,
      enableExceptionAutocapture: false,
    })
  : undefined;

// Model priority: env override → 'agent-model' flag payload (cached) → default.
const config = await resolveSessionConfig({
  fetchPayload: async (distinctId) => {
    if (!posthog) {
      return;
    }
    const flags = await posthog.evaluateFlags(distinctId);
    return flags.getFlagPayload("agent-model");
  },
});
const model = process.env["EMOTELY_MODEL"] ?? config.model;
const sessionId = randomUUID();

// Piped stdin (the scripted driver) EOF-closes readline before the first
// question, so pre-read all lines in that case; interactive keeps readline.
const piped: string[] = [];
if (!process.stdin.isTTY) {
  const chunks: Buffer[] = [];
  for await (const chunk of process.stdin) {
    chunks.push(chunk as Buffer);
  }
  piped.push(
    ...Buffer.concat(chunks).toString("utf8").split("\n").filter(Boolean),
  );
}

const rl = process.stdin.isTTY
  ? createInterface({ input: process.stdin, output: process.stdout })
  : undefined;

async function prompt(text: string): Promise<string> {
  if (rl) {
    return rl.question(text);
  }
  const line = piped.shift();
  if (line === undefined) {
    throw new Error("scripted stdin ran out of answers");
  }
  console.log(`${text}${line}`);
  return line;
}

const hints: Record<string, string> = {
  text_list: "one or more answers, comma-separated",
  longtext: "one answer, free text",
  rating: "a number from 1 to 10",
  emoji: "one or more emojis, comma-separated",
  color: "one or more hex colors like #FF0000, comma-separated",
};

const client: SessionClient = {
  askQuestion: async (input) => {
    const raw = await prompt(
      `\n${input.question}\n(${hints[input.answer_type]}) > `,
    );
    if (input.answer_type === "rating") {
      return Number(raw.trim());
    }
    if (input.answer_type === "longtext") {
      return raw.trim();
    }
    return raw
      .split(",")
      .map((s) => s.trim())
      .filter(Boolean) as JSONValue;
  },
};

console.log(
  `emotely journaling session — set "${defaultQuestionSet.name}", model ${model}`,
);
let result: Awaited<ReturnType<typeof runSession>>;
try {
  result = await runSession({
    questionSet: defaultQuestionSet,
    client,
    model,
    attribution: {
      distinctId: config.distinctId,
      sessionId,
      promptId: config.promptId,
    },
  });
} catch (err) {
  posthog?.captureException(err, config.distinctId, { model, sessionId });
  throw err;
} finally {
  rl?.close();
  // Both clients queue in memory; an unflushed CLI exit silently loses events.
  await shutdownTelemetry();
  await posthog?.shutdown();
}

console.log("\n--- journal entry ---");
console.log(result.summary);
console.log("\n--- recorded answers ---");
console.log(JSON.stringify(result.answers, null, 2));
