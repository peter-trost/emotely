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
