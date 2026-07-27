# PostHog for the full observability stack; no Sentry

We adopt PostHog from day one as the single observability and experimentation
platform, and deliberately do **not** add Sentry.

Adopted day one (all within PostHog's free tier at our scale):

- **Product analytics** — `posthog_flutter` (app) + `posthog-node` (agent).
- **LLM observability** — `@posthog/ai` on the AI SDK calls → `$ai_generation`
  events (tokens, cost, latency, traces per model). This is the cost/quality
  benchmark surface.
- **Feature flags + experiments** — a flag payload `{model, prompt}` drives
  server-side model selection with no deploy; PostHog LLM prompt experiments
  auto-attribute cost + quality per variant.
- **Error tracking** — native PostHog exception tracking. This is why we skip
  Sentry: one fewer vendor and SDK for a solo build; add Sentry later only if we
  outgrow PostHog's error tracking (unlikely soon).
- **Max AI + anomaly alerts** — the "self-driving" watchdog: watches AI-cost-per-
  user and session-completion and pings on drift instead of us dashboard-staring.

Deferred: session replay (only with mask-all-text, given sensitive journal content)
and surveys. Skipped for now: the data warehouse (Supabase is our source of truth;
revisit only to join Stripe subscription data).

Set billing limits / spike protection per product on day one so an agent retry
storm cannot surprise-bill.

## The self-driving loop

PostHog flag hands the agent `{model, prompt}` → `@posthog/ai` emits cost/latency
per variant → LLM prompt experiment attributes cost + quality per variant → Max AI
/ anomaly alerts flag drift. The product tunes its own model choice.
