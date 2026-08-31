import process from "node:process";
import { waitUntil } from "@vercel/functions";
import { modelMessageSchema } from "ai";
import { z } from "zod";
import { defaultQuestionSet } from "../src/default-question-set.ts";
import { createAdvanceSessionHandler } from "../src/http-advance-session.ts";
import { DEFAULT_MODEL } from "../src/session-config.ts";
import { advanceSession } from "../src/session-core.ts";
import { flushTelemetry, initTelemetry } from "../src/telemetry.ts";

const secret = process.env["SESSION_SIGNING_SECRET"];
if (!secret) {
  throw new Error("SESSION_SIGNING_SECRET is required");
}
const posthogKey = process.env["POSTHOG_KEY"];
const posthogHost = process.env["POSTHOG_HOST"];
if (posthogKey && !posthogHost) {
  throw new Error("POSTHOG_KEY is set but POSTHOG_HOST is not — set both.");
}
initTelemetry(
  posthogKey && posthogHost
    ? { posthog: { projectToken: posthogKey, host: posthogHost } }
    : {},
);

const model = process.env["EMOTELY_MODEL"] ?? DEFAULT_MODEL;
const transcriptSchema = z.array(modelMessageSchema);

const handler = createAdvanceSessionHandler({
  secret,
  advance: ({ messages, answer }) =>
    advanceSession({
      questionSet: defaultQuestionSet,
      model,
      // Signature-verified, so a parse failure here is a server bug, not
      // client input — let it 500 loudly.
      messages: transcriptSchema.parse(messages),
      ...(answer === undefined ? {} : { answer }),
    }),
});

export default function advanceSessionEndpoint(
  request: Request,
): Promise<Response> {
  const response = handler(request);
  waitUntil(response.then(() => flushTelemetry()));
  return response;
}
