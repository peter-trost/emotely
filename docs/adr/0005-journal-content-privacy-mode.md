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

