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
