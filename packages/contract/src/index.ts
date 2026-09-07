import { z } from "zod";

const nonemptyString = z.string().min(1);

export const answerValueSchemas = {
  color: z.array(z.string().regex(/^#[0-9A-Fa-f]{6}$/)).nonempty(),
  emoji: z.array(nonemptyString).nonempty(),
  longtext: nonemptyString,
  rating: z.int().min(1).max(10),
  text_list: z.array(nonemptyString).nonempty(),
};

export const answerTypes = [
  "color",
  "emoji",
  "longtext",
  "rating",
  "text_list",
] as const;
export type AnswerType = (typeof answerTypes)[number];

const answerVariant = <T extends AnswerType>(t: T) =>
  z.object({
    answer_type: z.literal(t),
    value: answerValueSchemas[t],
  });

// Nested under `answer` (not a top-level union): some providers reject tool
// schemas whose root is not type "object" (hit live with Bedrock via gateway).
export const answer = z.discriminatedUnion("answer_type", [
  answerVariant("color"),
  answerVariant("emoji"),
  answerVariant("longtext"),
  answerVariant("rating"),
  answerVariant("text_list"),
]);
export type Answer = z.infer<typeof answer>;

export const recordAnswerInput = z.object({
  question_id: nonemptyString,
  answer,
});
export type RecordAnswerInput = z.infer<typeof recordAnswerInput>;

export const askQuestionInput = z.object({
  question_id: nonemptyString,
  question: nonemptyString,
  answer_type: z.enum(answerTypes),
});
export type AskQuestionInput = z.infer<typeof askQuestionInput>;

export const completeSessionInput = z.object({
  summary: nonemptyString,
});
export type CompleteSessionInput = z.infer<typeof completeSessionInput>;

// The HTTP envelope of `POST /api/advance-session`. Wire keys are snake_case
// end to end, like the tool payloads above; the agent (producer) and the app
// (consumer) both pin against the JSON Schema emitted from these.
const jsonValue = z.json();

// Bare semver (`pubspec.yaml` `version` without the build number): the app
// reports it, the server gates on it and names the minimum it still serves.
const appVersion = z.string().regex(/^\d+\.\d+\.\d+$/);

export const advanceSessionRequest = z.object({
  transcript: z.array(z.unknown()).optional(),
  signature: z.string().optional(),
  answer: z
    .object({ tool_call_id: nonemptyString, value: jsonValue })
    .optional(),
  // Optional on the wire so clients that predate it keep working (additive
  // change); the app always sends it.
  app_version: appVersion.optional(),
});
export type AdvanceSessionRequest = z.infer<typeof advanceSessionRequest>;

const advanceSessionBase = {
  transcript: z.array(z.unknown()),
  signature: nonemptyString,
  prompt_id: nonemptyString,
  // Below this the app must update before it can continue (force-update).
  min_app_version: appVersion,
};

export const advanceSessionResponse = z.discriminatedUnion("status", [
  z.object({
    status: z.literal("awaiting_answer"),
    ...advanceSessionBase,
    pending: z.object({
      tool_call_id: nonemptyString,
      question: askQuestionInput,
    }),
  }),
  z.object({
    status: z.literal("completed"),
    ...advanceSessionBase,
    entry: z.object({
      summary: nonemptyString,
      answers: z.record(nonemptyString, answer),
    }),
  }),
]);
export type AdvanceSessionResponse = z.infer<typeof advanceSessionResponse>;
