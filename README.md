# emotely

A daily journaling app with an AI **Journaling Assistant** that walks you through
a structured reflection — walking a chosen question set — and produces a summarized
journal entry. This is a ground-up rebuild of the original emotely (a shipped
Flutter + Firebase app, sunset in early 2025) around a modern, tools-first AI
harness.

Three goals, held at once:

1. **Personal use** — I journal with it daily.
2. **Public AI-engineering showcase** — the agent service and the Flutter GenUI
   client are both open (MIT) and meant to be read.
3. **Fund spare-time work** — a 5€/month subscription with high margins.

## Decisions

The load-bearing decisions and their rationale live in [`docs/adr/`](docs/adr/):

1. [Monorepo](docs/adr/0001-monorepo.md) — agent + app + shared contract in one repo
2. [Tools-first harness](docs/adr/0002-tools-first-harness.md) — tool calls, not prompted JSON
3. [Model gateway + cost ceiling](docs/adr/0003-model-gateway-and-cost-ceiling.md) — provider-agnostic, cheap-model constraint
4. [PostHog observability stack](docs/adr/0004-posthog-observability-stack.md) — full bundle, no Sentry
5. [Journal content privacy](docs/adr/0005-journal-content-privacy-mode.md) — content never recorded, metadata only (leak-tested)
6. [Flutter iOS + Android only](docs/adr/0006-flutter-ios-android-only.md) — no web, demand-driven expansion
7. [Protected `main`](docs/adr/0007-protected-main-for-autonomous-agents.md) — PR + CI gate, because agents write here
8. [Public endpoint abuse controls](docs/adr/0008-public-endpoint-abuse-controls.md) — signed transcripts, caps, WAF rate limit, budget ceiling

The project's language is defined in [`CONTEXT.md`](CONTEXT.md).

## Architecture

Monorepo. Two apps that share one contract, plus Supabase (data/auth) and
PostHog (analytics + the self-driving loop).

```
emotely/
├─ apps/
│  ├─ agent/      TypeScript · Vercel AI SDK agent loop · deploys to Vercel
│  │             tools: ask_question / record_answer / complete_session
│  │             evals/ — offline fixtures → cost + quality (CI gate)
│  └─ app/        Flutter (iOS + Android) · renders one native widget per tool call
├─ packages/
│  └─ contract/   the tool-call schema — single source of truth for both sides
└─ README.md
```

### Why a monorepo

The agent and the app are two halves of one product joined by **one contract**:
the agent emits tool calls, the app renders a native widget per call. That shared
schema (`packages/contract`) must never drift between producer and consumer — in a
monorepo a schema change plus both sides move in one atomic, CI-verified commit.
Solo founder → one CI, one release story, one front door. Both repos are public
anyway, so the usual "keep one half private" argument doesn't apply.

Tooling stays boring: pnpm workspaces for the TS side, Flutter's own tooling for
`apps/app`, path-filtered GitHub Actions. No Nx/Turbo/Bazel.

### The stack

| Layer | Choice | Why |
|---|---|---|
| **Client** | Flutter, iOS + Android only (no web) | Native GenUI story; VGV/Flutter-community audience |
| **Agent runtime** | TypeScript · Vercel AI SDK · Vercel | Tools-first agent loop, streaming, the AI-eng showcase |
| **Model access** | Vercel AI Gateway | Swap models via config (bare `creator/model` strings); 0% fees; benchmarked monthly |
| **Data + auth** | Supabase (Postgres + Auth) | Fresh schema, no Firebase baggage |
| **Observability** | PostHog (full bundle, see below) | LLM obs, flags, experiments, error tracking, Max AI |
| **Subscriptions** | RevenueCat | Known quantity from the original app |
| **License** | MIT, both apps | Portfolio-friendly, maximally reusable |

### Tool-calling replaces the old JSON hack

The original assistant ran on the Firebase GenAI Chatbot extension: a ~2KB prompt
that *begged* the model to emit parseable JSON (`response` + `summary`), with a
"recovery prompt" retry when the JSON didn't parse. That's fighting the model.

The rebuild gives the model **tools** instead:

- `ask_question(question, answer_type)` — `answer_type ∈ text_list | longtext | rating | emoji | color`; the client renders the matching native widget and supplies the answer as the tool result. **This is the generative UI.**
- `record_answer(question, value)` — structured, validated tool args, typed per answer type. No JSON-parsing prayer.
- `complete_session(summary)` — the summary is a validated tool argument, not parsed prose.

The old `ColorText` / `ColorTextEditingController` feature becomes just one
`answer_type` (`color`).

## PostHog — the "self-driving" layer

Adopted day one (all free at our scale, ~0€ at 1k MAU):

- **Product analytics** — `posthog_flutter` (app) + `posthog-node` (agent).
- **LLM observability** — `@posthog/ai` with `experimental_telemetry` on AI SDK
  calls → `$ai_generation` events (tokens, cost, latency, traces per model).
  **content recording OFF at the source** (`recordInputs`/`recordOutputs`
  false; a CI leak test proves no journal text reaches spans). Only metadata
  is captured. Non-negotiable for a journaling app.
- **Feature flags + experiments** — a flag payload `{ model, prompt }` drives
  **server-side model selection** in the agent, no deploy. PostHog's **LLM prompt
  experiments** auto-attribute cost + quality per variant.
- **Error tracking** — native PostHog exception tracking. **No Sentry.**
- **Max AI + anomaly alerts** — agentic analyst that watches AI-cost-per-user and
  session-completion and pings on drift. This is the self-driving watchdog.
- **Session replay + surveys** — deferred (replay only with mask-all-text, given
  sensitive journal content).

**The self-driving loop:** PostHog flag hands the agent `{model, prompt}` →
`@posthog/ai` emits cost/latency per variant → LLM prompt experiment attributes
cost + quality per variant → Max AI / anomaly alerts flag drift. The product tunes
its own model choice; you get pinged instead of dashboard-staring.

Set **billing limits / spike protection** per product on day one — a retry storm
must not surprise-bill.

## Cost model (the constraint) and model choice

A daily poweruser (~30 sessions/month, ~10 questions each) must cost
**≤ €1/month** (≈ $0.036/session) inside a 5€ subscription — margins are fine at
that level. Within that ceiling, **the fastest reliable model wins**: GenUI
latency is what the user feels between widgets, so models are ranked by median
per-round latency with cost as the tiebreak. We start reliable and fast, and
optimize toward cheaper models with real usage data.

- The cheap tier (Qwen/GLM/DeepSeek flash-class, Gemini Flash-Lite) runs a full
  session for well under a cent — ~10¢/month.
- Haiku-class and small frontier tiers (e.g. GPT-5.6 Luna at $0.20/M input) are
  eligible candidates, not excluded.
- **Prompt caching** needs no code — every gateway candidate is implicitly
  cached, and the win is the growing conversation prefix across ~25 rounds.
  It is measured per model, not assumed.
- The task is narrow and well-specified (a fixed question set, extract →
  summarize) — good tool calling matters more than frontier reasoning.

The model is chosen **empirically** by the benchmark (`pnpm --filter
@emotely/agent benchmark`): eligible = protocol eval 3/3, every behavior
scenario 2-of-3, within budget. A monthly workflow re-runs it and opens an issue
with the ranking plus any new tool-capable models in the gateway catalog. See
[ADR 0003](docs/adr/0003-model-gateway-and-cost-ceiling.md).

## Two layers of evaluation

1. **Offline evals** (`apps/agent/evals/`) — deterministic fixtures replayed
   against each candidate model. The CI gate; catches regressions before ship.
   Seed from the original app's `promptfoo` conversation fixtures.
2. **Online experiment** (PostHog) — real sessions, real cost, live variant
   comparison. The self-driving loop.

Offline proves *correct + cheap in the lab*; online proves *cheap + retained in
the wild*.

## Build order

1. **`apps/agent` skeleton** — Vercel AI SDK loop, the three tools, gateway wired,
   one cheap model hardcoded. Prove a full 10-question session runs end-to-end via
   tool calls. No client yet.
2. **Offline eval harness** — port the original prompt + `promptfoo` conversation
   fixtures into `evals/`. CI gate: replay, assert correctness, measure cost per
   candidate.
3. **Benchmark** — rank candidates on latency within the cost ceiling; pick the
   fastest reliable one. Gateway decided: Vercel AI Gateway (ADR 0003 amendment).
4. **PostHog online** — OTel span processor (content recording off), flag-driven model
   selection, first LLM prompt experiment.
5. **`apps/app`** — Flutter shell rendering a widget per tool call, Supabase auth +
   entry persistence, `posthog_flutter`.
6. **Subscription + polish** — RevenueCat, paywall, ship to TestFlight.

## Verify-at-build-time (do NOT pin from memory)

Per project convention, research the latest before pinning:

- Vercel AI SDK, `@posthog/ai`, `posthog-node`, `posthog_flutter` versions.
- Current GLM and Gemini Flash-Lite model IDs (note: "GLM 5.2" does not exist —
  current is the GLM-4.x line; confirm exact version).

## Legacy

The original app lives at `~/dev/emotely-legacy` (Flutter + Firebase, sunset early
2025). Worth cherry-picking, not migrating: the context/opening/recovery prompt
design, the `promptfoo` conversation fixtures, the `ColorText` idea, and the strong
accessibility bar (a11y tests for every view). Everything else — the Firebase
GenAI extension, the JSON-recovery hack, Firestore, Sentry, the web target — is
gone.
