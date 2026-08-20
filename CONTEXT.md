# Context

The language of this project. Glossary only — decisions live in
[`docs/adr/`](docs/adr/), architecture in [`README.md`](README.md).

## Session

One complete run of the Journaling Assistant: the assistant walks the user
through the **questions** of a chosen **question set** and ends by producing a
**journal entry**. A session is the unit the cost ceiling is measured against
(~30 sessions/month for a daily poweruser).

## Question

One thing the assistant asks about within a session — a concrete question text
(e.g. "What are you grateful for today?"), not an abstract theme. Asked via
`ask_question`, answered via `record_answer` — the pair is what makes a question
distinct from a free-form chat turn. One `record_answer` per question carries
the complete answer; a repeated call for the same question overwrites.
("Topic" is not a term in this project; the legacy app used it only in prompts.)

## Question set

An ordered list of questions the user picks before a session starts; the session
walks exactly that set. Sets are predefined for now; user-created sets are an
intended future capability (the legacy app built the storage for this but never
shipped the UI).

## Answer type

How a question is answered, and therefore which native widget the client renders
and what shape the answer value has: `text_list` (several short texts),
`longtext` (one text), `rating` (one integer, 1–10), `emoji` (several emojis),
`color` (several hex colors). This is the surface of the generative UI — the
answer type comes from the question, the client renders the matching widget.
For list-shaped types, multiplicity lives inside the value, never in repeated
calls; `minAnswers` on a question is the only cardinality constraint.

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
