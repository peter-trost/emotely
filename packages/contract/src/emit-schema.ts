import { writeFileSync } from "node:fs";
import { z } from "zod";
import {
  askQuestionInput,
  completeSessionInput,
  recordAnswerInput,
} from "./index.ts";

// CI tripwire: the committed JSON Schema must match the zod source of truth.
// Regenerate with `pnpm --filter @emotely/contract schema`; a diff in CI means
// the TS contract changed without the Dart side (and this file) following.
const schema = {
  ask_question: z.toJSONSchema(askQuestionInput, { io: "input" }),
  record_answer: z.toJSONSchema(recordAnswerInput, { io: "input" }),
  complete_session: z.toJSONSchema(completeSessionInput, { io: "input" }),
};

writeFileSync(
  new URL("../contract.schema.json", import.meta.url),
  `${JSON.stringify(schema, null, 2)}\n`,
);
