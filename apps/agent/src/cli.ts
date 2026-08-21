import process from "node:process";
import { createInterface } from "node:readline/promises";
import type { JSONValue } from "ai";
import { defaultQuestionSet } from "./default-question-set.ts";
import { runSession, type SessionClient } from "./session.ts";

try {
  process.loadEnvFile(new URL("../.env.local", import.meta.url).pathname);
} catch {
  // fine — key may come from the environment
}

// ponytail: model swap is one env var; PostHog flag payload takes over in issue #5.
const model = process.env["EMOTELY_MODEL"] ?? "zai/glm-4.7-flash";

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
const result = await runSession({
  questionSet: defaultQuestionSet,
  client,
  model,
});
rl?.close();

console.log("\n--- journal entry ---");
console.log(result.summary);
console.log("\n--- recorded answers ---");
console.log(JSON.stringify(result.answers, null, 2));
