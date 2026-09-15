import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { gunzipSync } from "node:zlib";
import { PostHog } from "posthog-node";
import {
  classifyModelFailure,
  createErrorReporter,
  FORWARDED_ERROR_TYPES,
  WithheldError,
} from "./error-tracking.ts";

// ADR 0005: an exception must never carry journal content to PostHog. The
// server has no `beforeSend` to scrub with — posthog-node removes it from
// PostHogOptions — so the rule is applied by construction, at the call site.
const NEEDLE = "NEEDLE_JOURNAL_TEXT_7b2c";

/**
 * A stand-in for the real gateway rejection, shaped from the live error
 * measured on 2026-09-15 (see error-tracking.ts): a GatewayError whose
 * `cause` is the APICallError, whose `requestBodyValues` hold the prompt.
 * PostHog walks `cause` into `$exception_list`, so the cause is the leak
 * path this test exists to close.
 */
function gatewayRejection(message: string): Error {
  const cause = Object.assign(new Error(`upstream said: ${NEEDLE}`), {
    name: "AI_APICallError",
    statusCode: 400,
    requestBodyValues: { prompt: [{ content: [{ text: NEEDLE }] }] },
    responseBody: JSON.stringify({ error: { message: NEEDLE } }),
  });
  return Object.assign(new Error(message), {
    name: "GatewayInternalServerError",
    type: "internal_server_error",
    statusCode: 400,
    isRetryable: false,
    cause,
  });
}

/** Captures what posthog-node actually puts on the wire, gzip included. */
function recordingClient(): { client: PostHog; wire: () => string } {
  const bodies: unknown[] = [];
  const client = new PostHog("phc_test_token", {
    host: "http://127.0.0.1:1/never",
    flushAt: 1,
    fetch: async (_url, options) => {
      bodies.push((options as { body?: unknown }).body);
      return {
        status: 200,
        text: async () => "ok",
        json: async () => ({ status: 1 }),
      } as never;
    },
  });
  return {
    client,
    wire: () =>
      bodies
        .map((body) => {
          if (typeof body === "string") {
            return body;
          }
          const buf = Buffer.from(body as Uint8Array);
          try {
            return gunzipSync(buf).toString("utf8");
          } catch {
            return buf.toString("utf8");
          }
        })
        .join("\n"),
  };
}

describe("classifyModelFailure", () => {
  it("names a privacy-filter rejection as its own signal", () => {
    const failure = classifyModelFailure(
      gatewayRejection(
        "No ZDR (Zero Data Retention) providers or ZDR-attested BYOK credentials available for model: moonshotai/kimi-k2. Providers considered: novita",
      ),
    );
    assert.equal(failure?.kind, "provider_ineligible");
    assert.equal(failure?.status, 502);
  });

  it("separates an ordinary gateway failure from a provider-eligibility one", () => {
    const rateLimited = Object.assign(new Error("Rate limit exceeded"), {
      name: "GatewayRateLimitError",
      type: "rate_limit_exceeded",
      statusCode: 429,
    });
    const failure = classifyModelFailure(rateLimited);
    assert.equal(failure?.kind, "gateway_error");
    assert.equal(failure?.status, 502);
  });

  it("leaves a non-gateway error unclassified so it 500s loudly", () => {
    assert.equal(classifyModelFailure(new Error("boom")), undefined);
  });
});

describe("content-free error reporting", () => {
  it("never puts journal content on the wire for a gateway rejection", async () => {
    const { client, wire } = recordingClient();
    const report = createErrorReporter(client);

    report(
      gatewayRejection(
        "No ZDR providers available for model: moonshotai/kimi-k2",
      ),
      { step: "session_round", userId: "user-1", model: "moonshotai/kimi-k2" },
    );
    await client.shutdown();

    const sent = wire();
    assert.ok(sent.length > 0, "nothing was sent — the reporter is a no-op");
    assert.ok(
      !sent.includes(NEEDLE),
      "journal content reached PostHog via the exception",
    );
  });

  it("withholds the message of an error type that is not allowlisted", async () => {
    const { client, wire } = recordingClient();
    const report = createErrorReporter(client);

    report(new Error(`postgres refused row: ${NEEDLE}`), {
      step: "session_round",
      userId: "user-1",
    });
    await client.shutdown();

    const sent = wire();
    assert.ok(!sent.includes(NEEDLE), "an unknown error leaked its message");
    assert.ok(
      sent.includes("message withheld"),
      "the withheld stand-in did not reach PostHog",
    );
  });

  it("keeps the diagnostic properties that carry no content", async () => {
    const { client, wire } = recordingClient();
    const report = createErrorReporter(client);

    report(gatewayRejection("No ZDR providers available"), {
      step: "session_round",
      userId: "user-1",
      model: "moonshotai/kimi-k2",
    });
    await client.shutdown();

    const sent = wire();
    assert.ok(sent.includes("session_round"), "the step is missing");
    assert.ok(sent.includes("moonshotai/kimi-k2"), "the model id is missing");
    assert.ok(
      sent.includes("provider_ineligible"),
      "the failure kind is missing",
    );
  });

  it("forwards only types whose text is the gateway's own words", () => {
    // The allowlist is the whole rule; anything outside it is withheld.
    assert.ok(FORWARDED_ERROR_TYPES.has("GatewayInternalServerError"));
    assert.ok(!FORWARDED_ERROR_TYPES.has("AI_APICallError"));
    assert.ok(!FORWARDED_ERROR_TYPES.has("Error"));
  });

  it("sends no source context, which the SDK reads off disk unbidden", async () => {
    // posthog-node opens the file each stack frame names and uploads the
    // surrounding lines (addSourceContext, context-lines.node), with no
    // option to disable it. A frame that points at nothing has nothing to
    // read — this asserts the frames stay bare.
    const { client, wire } = recordingClient();
    const report = createErrorReporter(client);

    report(gatewayRejection("No ZDR providers available"), {
      step: "session_round",
      userId: "user-1",
    });
    await client.shutdown();

    const sent = wire();
    assert.ok(
      !sent.includes("pre_context"),
      "the SDK attached source lines to the exception",
    );
    assert.ok(
      !sent.includes("context_line"),
      "the SDK attached the throwing source line",
    );
  });

  it("drops the cause chain, which is where the prompt lives", async () => {
    const { client, wire } = recordingClient();
    const report = createErrorReporter(client);

    report(gatewayRejection("No ZDR providers available"), {
      step: "session_round",
      userId: "user-1",
    });
    await client.shutdown();

    const sent = wire();
    assert.ok(
      !sent.includes("AI_APICallError"),
      "the APICallError cause reached PostHog — it carries the request body",
    );
  });
});

describe("WithheldError", () => {
  it("says what failed without saying what it choked on", () => {
    const withheld = new WithheldError("PostgresError", { statusCode: 500 });
    const text = withheld.toString();
    assert.ok(text.includes("PostgresError"));
    assert.ok(text.includes("500"));
    assert.ok(text.includes("message withheld"));
  });
});
