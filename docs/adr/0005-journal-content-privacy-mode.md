# Journal content never leaves the device to PostHog (privacyMode on)

`@posthog/ai` captures LLM prompt inputs and outputs by default — which for a
journaling app is the user's private journal text, the most sensitive data we hold.

We run `@posthog/ai` with **`privacyMode` on**: PostHog receives only metadata
(tokens, cost, latency, traces per model), never the journal content. This keeps
the full cost/benchmark story intact while matching emotely's privacy-first ethos
and keeping users' journals out of a third party.

This is a day-one, non-negotiable decision, not a later toggle: turning content
capture on after the fact would mean sensitive data had already been designed to
flow to a third party. If we ever need content for debugging, the path is redact-
then-capture, decided explicitly — not flipping raw capture on.

**2026-08-24 implementation note:** on the AI SDK v7 OpenTelemetry path — the
only PostHog-supported integration for our stack — no `privacyMode` switch
exists. The mechanism is `recordInputs: false` / `recordOutputs: false` on
every model call, which suppresses all content-bearing span attributes
(messages, tool arguments, tool results) at the source; `runSession` owns the
single call site so no code path can forget it. The decision is enforced by
CI, not convention: a leak test runs a session under a real OTel pipeline
with sentinel journal text and fails if any exported span attribute or event
contains it — covering the happy path, invalid tool input, and client-thrown
errors. Verified live 2026-08-24: zero journal text across all event
properties in PostHog; tokens, cost, latency, traces, promptId and session
attribution all present.

The same rule holds on the client (2026-09-05). `posthog_flutter` events are
built by one class, `SessionAnalytics`, that only ever receives question ids,
answer types, counts and HTTP status codes — it has no access to question text,
answer values or the summary, so a leak would be a type error before it was a
bug. Its CI test walks a whole session with sentinel strings in the question,
the typed answer, the summary and the recorded answers, and asserts none of them
appears in any captured event name or property.

**2026-09-13, error tracking:** exceptions reach PostHog on two paths, and
the rule holds on both. PostHog records an exception's `toString()`, and
many of those quote what they choked on — a Postgres error names the
failing row (the transcript), a JSON error the body it could not parse (a
question, a summary), GoTrue the address it validated (`Unable to validate
email address: …`) and, for a 5xx, gotrue keeps the whole response body.

1. *Handled failures* go through one class, `ErrorReporter` (type, stack
   trace, the step and ids). It forwards the message only for
   `AgentException` (the agent's own error text) and the two transport
   errors that only name a host (`ClientException`, `TimeoutException`);
   every other exception — every `AuthException` and `PostgrestException`
   among them — goes out as its type plus the error code and status with
   the message withheld.
2. *Uncaught errors* are captured by the SDK itself (`FlutterError`,
   platform dispatcher, isolates; release builds only). A `beforeSend`
   hook, `contentFreeExceptions`, applies the same rule on the wire to
   every `$exception` event: each exception item keeps its type and stack
   frames but loses its text unless the type is one of the three above or
   `WithheldException`, the stand-in path 1 substitutes, whose message is
   already withheld — four in `forwardedTypes`, not three;
   and the Flutter error details keep only the library and the silent
   flag (`context`, `information` and `error_summary` can quote a widget's
   content). Exception steps (free-text breadcrumbs in a native buffer)
   stay off.

The needle tests cover the reported exceptions: a non-JSON body, Postgres
refusals and GoTrue refusals (4xx and 5xx) quoting the needle never reach
an outgoing string, and the scrubber is unit-tested with a needle in every
free-text field the SDK emits.

**2026-09-15, the model provider:** this ADR keeps journal content out of
*telemetry*. The other place the content goes is the model itself — the
transcript is the prompt — and that path is now covered too: every round
requests `disallowPromptTraining` and `zeroDataRetention` from the gateway, so
routing is restricted to providers contractually bound not to train on the
prompt or retain it. Recorded in full, with the live measurement and the
fail-closed consequence, in the
[ADR 0003 amendment](0003-model-gateway-and-cost-ceiling.md).

The two controls are **not** independent: Vercel states ZDR is a superset of
the training opt-out, so setting both is defense in depth rather than two
separate guarantees. Nor does either make the content *unseen* — the provider
still processes the transcript to answer it. The claim is bounded: not trained
on, not retained. The privacy notice must say exactly that and no more.

