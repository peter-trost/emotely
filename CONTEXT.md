# Context

The language of this project. Glossary only — decisions live in
[`docs/adr/`](docs/adr/), architecture in [`README.md`](README.md).

## Session

One complete run of the Journaling Assistant: the assistant walks the user
through up to ten **topics** and ends by producing a **journal entry**. A session
is the unit the cost ceiling is measured against (~30 sessions/month for a daily
poweruser).

## Topic

One thing the assistant asks about within a session. A topic is asked via
`ask_topic` and answered via `record_answer` — the pair is what makes a topic
distinct from a free-form chat turn.

## Input type

How a topic is answered, and therefore which native widget the client renders:
`text`, `color_picker`, `mood_slider`, `multi_select`. This is the surface of the
generative UI — the model chooses the input type, the client renders it.

## Journal entry

The durable artifact a session produces: the summary passed to
`complete_session`, persisted for the user. Distinct from the session itself,
which is the conversation that produced it.

## Contract

The tool-call schema in `packages/contract` — the single source of truth shared
by the agent (producer) and the app (consumer). "Contract drift" means the two
sides disagreeing about it, which the monorepo exists to prevent.

## Agent

Ambiguous by default; always qualify:

- **the agent** (`apps/agent`) — the deployed TypeScript service running the
  tool-calling loop.
- **an autonomous agent** — an AI coding agent that writes to this repository.
  These are the actors [ADR 0007](docs/adr/0007-protected-main-for-autonomous-agents.md)
  protects `main` against.

## Gate

A check that must pass *before* a change lands. Distinct from a **rollback**,
which is a correction *after*. The CI gate is a precondition; rollback is the
second line of defence. See [ADR 0007](docs/adr/0007-protected-main-for-autonomous-agents.md).

## Evals

Two distinct layers, never used interchangeably:

- **Offline evals** (`apps/agent/evals/`) — deterministic fixtures replayed
  against candidate models. A CI gate. Proves *correct and cheap in the lab*.
- **Online experiment** (PostHog) — real sessions, live variant comparison.
  Proves *cheap and retained in the wild*.
