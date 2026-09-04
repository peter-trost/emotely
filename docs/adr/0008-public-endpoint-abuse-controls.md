# The agent endpoint is public, so it must be structurally unabusable

`POST /api/advance-session` is reachable by anyone: the app has no user accounts
yet (they arrive with #7), and the repository that describes the endpoint byte for
byte is public. An unauthenticated, open-source, LLM-backed endpoint is a free LLM
proxy unless the design makes it not one. The controls below are layered so that
no single one has to hold.

## Server-signed transcripts

The session is stateless: the client holds the whole transcript and posts it back
each round. Every response signs that transcript (HMAC-SHA256 over the JSON,
verified in constant time); only server-signed transcripts advance. Nobody can
inject, edit, or fabricate messages, so the model never sees client-authored
text as anything but the widget answer — and that enters as a size-capped,
schema-typed **tool result**: data, never instructions.

The alternative we rejected was storing sessions server-side and handing the
client an id. It would also close the injection hole, but it needs a database
before #7 delivers one, and a per-id store is itself an abuse surface (unbounded
session creation). Signing costs nothing and moves the state to the party that
already has it. Server-side resume comes with #7, on top of the same signing.

## Caps before compute

Validation runs in cost order, cheapest first, and every failure returns before a
model call: signature (401), transcript length ≤ 200 messages (413), answer ≤ 4 KB
(400), answer must match the pending question (400), non-POST (405). The
transcript-shape parse sits *behind* the signature check on purpose — a failure
there is a server bug and should 500 loudly, not be silently absorbed as bad
input.

## Cost backstops

- A per-round output-token cap and a round guard derived from the transcript
  (the model cannot loop forever on one signed state).
- The gateway key's monthly budget ([ADR 0003](0003-model-gateway-and-cost-ceiling.md))
  is the hard ceiling: exhaustion degrades the product, never the bank account.

## Rate limiting lives in the Vercel WAF, not in code

Starting a session is deliberately free — an empty transcript needs no signature —
so the one thing signing cannot bound is *how many* sessions one source starts.
That is what the firewall rule is for:

| Rule | Value |
| --- | --- |
| Project | `emotely-agent` → Firewall → Rules |
| Match | Request Path equals `/api/advance-session` |
| Limit | 30 requests / 60 s, fixed window, keyed by IP |
| Action | 429 Too Many Requests |

A real session is roughly one request per question, so 30/min is an order of
magnitude above legitimate use. Counters are per Vercel region, so the effective
global limit for a distributed attacker is higher — acceptable, because the
budget backstop above catches what the rule lets through.

We chose the WAF over an in-function limiter because the rule rejects at the
edge, before a function invocation is billed, and because a Hobby project gets
one rate-limit rule at no cost. The cost of that choice is that the rule is
**dashboard configuration, not code**: it is not in this repository, not in CI,
and will not survive a project re-creation. This ADR is the record; re-apply it
by hand if the project is ever rebuilt. Verified live on 2026-09-04: the 31st
request inside a minute from one IP gets a 429.

## What follows from it

- **The nightly live smoke** (`pnpm smoke`) makes about a dozen requests from one
  runner IP — safely under the limit. Any future probe that fires more must
  stay under 30/min or expect 429s.
- **User auth (#7) replaces none of this.** It adds a per-user key for the rate
  limit and the ability to refuse anonymous sessions; signing, caps, and budget
  stay as they are.
- **The Hobby plan allows one rate-limit rule per project.** Adding a second
  (e.g. a tighter cap on empty-transcript session starts) needs Pro, which is on
  the release path anyway (see `CLAUDE.md` § Billing).
