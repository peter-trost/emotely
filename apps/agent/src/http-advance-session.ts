import { z } from "zod";
import type { AdvanceResult, SessionAnswer } from "./session-core.ts";
import { signTranscript, verifyTranscript } from "./transcript-auth.ts";

const MAX_TRANSCRIPT_MESSAGES = 200;
const MAX_ANSWER_BYTES = 4096;
const HTTP_OK = 200;
const HTTP_BAD_REQUEST = 400;
const HTTP_UNAUTHORIZED = 401;
const HTTP_METHOD_NOT_ALLOWED = 405;
const HTTP_PAYLOAD_TOO_LARGE = 413;

const jsonValue: z.ZodType<unknown> = z.lazy(() =>
  z.union([
    z.string(),
    z.number(),
    z.boolean(),
    z.null(),
    z.array(jsonValue),
    z.record(z.string(), jsonValue),
  ]),
);

const requestSchema = z.object({
  transcript: z.array(z.unknown()).optional(),
  signature: z.string().optional(),
  answer: z
    .object({ toolCallId: z.string().min(1), value: jsonValue })
    .optional(),
});

type Advance = (input: {
  messages: unknown[];
  answer?: SessionAnswer;
}) => Promise<AdvanceResult>;

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });
}

function validate(
  parsed: z.infer<typeof requestSchema>,
  secret: string,
): { error: Response } | { error?: never; transcript: unknown[] } {
  const { transcript, signature, answer } = parsed;
  if (transcript === undefined) {
    return { transcript: [] };
  }
  if (
    signature === undefined ||
    !verifyTranscript(transcript, signature, secret)
  ) {
    return { error: json(HTTP_UNAUTHORIZED, { error: "invalid signature" }) };
  }
  if (transcript.length > MAX_TRANSCRIPT_MESSAGES) {
    return {
      error: json(HTTP_PAYLOAD_TOO_LARGE, { error: "transcript too long" }),
    };
  }
  if (
    answer !== undefined &&
    JSON.stringify(answer.value).length > MAX_ANSWER_BYTES
  ) {
    return { error: json(HTTP_BAD_REQUEST, { error: "answer too large" }) };
  }
  return { transcript };
}

async function runAdvance(
  advance: Advance,
  transcript: unknown[],
  parsed: z.infer<typeof requestSchema>,
): Promise<AdvanceResult | Response> {
  try {
    return await advance({
      messages: transcript,
      ...(parsed.answer === undefined
        ? {}
        : { answer: parsed.answer as SessionAnswer }),
    });
  } catch (error) {
    if (
      error instanceof Error &&
      error.message.includes("does not match the pending question")
    ) {
      return json(HTTP_BAD_REQUEST, { error: "answer mismatch" });
    }
    throw error;
  }
}

/**
 * The stateless session endpoint: the client echoes the signed transcript and
 * its widget answer; the server advances to the next question or the entry.
 * Signature-first: nothing reaches the model unless this server produced it.
 */
export function createAdvanceSessionHandler(deps: {
  secret: string;
  advance: Advance;
}) {
  return async (request: Request): Promise<Response> => {
    if (request.method !== "POST") {
      return json(HTTP_METHOD_NOT_ALLOWED, { error: "POST only" });
    }
    let parsed: z.infer<typeof requestSchema>;
    try {
      parsed = requestSchema.parse(await request.json());
    } catch {
      return json(HTTP_BAD_REQUEST, { error: "malformed request" });
    }
    // A fresh session must not smuggle an oversized answer either.
    if (
      parsed.answer !== undefined &&
      JSON.stringify(parsed.answer.value).length > MAX_ANSWER_BYTES
    ) {
      return json(HTTP_BAD_REQUEST, { error: "answer too large" });
    }
    const checked = validate(parsed, deps.secret);
    if (checked.error) {
      return checked.error;
    }

    const outcome = await runAdvance(deps.advance, checked.transcript, parsed);
    if (outcome instanceof Response) {
      return outcome;
    }
    const result = outcome;

    const base = {
      transcript: result.messages,
      signature: signTranscript(result.messages, deps.secret),
      promptId: result.promptId,
    };
    if (result.status === "completed") {
      return json(HTTP_OK, {
        status: "completed",
        ...base,
        entry: result.entry,
      });
    }
    return json(HTTP_OK, {
      status: "awaiting_answer",
      ...base,
      pending: {
        toolCallId: result.pending.toolCallId,
        question: result.pending.input,
      },
    });
  };
}
