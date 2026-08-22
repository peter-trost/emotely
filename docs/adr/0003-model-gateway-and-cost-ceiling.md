# Route models through a gateway, under a hard cost ceiling

The agent calls its LLM through a **provider-agnostic gateway**, not a direct
provider SDK. This lets us swap models with a config/flag change and benchmark
candidates on real sessions. The gateway pattern is settled; the specific vendor is
deferred (see below).

## The constraint that drives model choice

A daily poweruser (~30 sessions/month, ~10 topics each) must cost **well under
50¢/month**, ideally a few cents, inside a 5€/month subscription with high margins.

- Frontier models (Claude Sonnet/Opus): out — blow the budget per session.
- Haiku-class: borderline (~$1.50–2.70/mo).
- Gemini Flash-Lite / GLM-4.x-class: a few cents to ~60¢/mo — the only tier that
  reliably hits "a few cents."
- Prompt caching on the static context prompt cuts session cost 3–5× and matters
  more than the exact model.

The task is narrow and well-specified (10 fixed topics, extract → summarize), so a
cheap model with good tool-calling is sufficient; no frontier reasoning is needed.
The final model is chosen **empirically** via the offline eval harness plus a
PostHog LLM prompt experiment — never pinned from memory.

## Deferred: which gateway

OpenRouter vs Vercel AI Gateway. Both work with the Vercel AI SDK and with PostHog
LLM observability. Deciding criterion: integration cleanliness — OpenRouter has a
*dedicated* PostHog install path; Vercel AI Gateway is listed as "supported." The
specific vendor is chosen at build step 3, after understanding the concrete
differences (routing, failover, caching, billing) — not yet decided.

## Amendment 2026-08-22: gateway decided, ceiling revised

**Gateway: Vercel AI Gateway.** The deferral's deciding criterion ("OpenRouter
has a dedicated PostHog install path") did not survive the AI SDK v7 research:
PostHog's supported v7 path is an OpenTelemetry span processor that instruments
the SDK, not the provider, so observability is gateway-agnostic — and the
"dedicated" OpenRouter path is an OpenAI-client wrapper that would force us off
`generateText`. What remains is fees: Vercel AI Gateway charges 0% on tokens and
0% on BYOK; OpenRouter 5.5% on credits and 5% on BYOK. Lock-in is one env var
plus bare `creator/model` strings either way.

**Ceiling: ≤ €1/month per daily poweruser (≈ $0.036/session at 30 sessions),
and within that, the fastest reliable model wins.** Margins inside a €5
subscription are fine at that level, and GenUI latency is what the user feels
between widgets. This replaces "well under 50¢, frontier out": Haiku-class and
the small frontier tiers (e.g. GPT-5.6 Luna at $0.20/M in) are eligible
candidates, ranked by median per-round latency with cost as tiebreak. We start
reliable and fast, and optimize toward cheaper models with real usage data.

**Caching needs no code.** Every gateway candidate is implicitly cached; the
win is the growing conversation prefix across ~25 rounds, not just the static
prompt. Measured, not assumed: the first live reading for glm-4.7-flash was
`cached=0` despite its catalog tag.

Selection is re-run monthly by a scheduled benchmark that also lists new
tool-capable models from the live catalog (issue #4).
