# Tools-first agent harness (not prompted JSON)

The Journaling Assistant is built as a tool-calling agent (Vercel AI SDK loop), not
as a prompt that asks the model to emit parseable JSON.

The original emotely ran on the Firebase GenAI Chatbot extension: a ~2KB context
prompt begged the model to return `{response, summary}` as JSON, with a "recovery
prompt" retry whenever the output failed to parse. That fights the model and is
fragile.

Instead the model is given tools whose arguments are validated by the SDK:

- `ask_question(question, answer_type)` — `answer_type ∈ text_list | longtext | rating | emoji | color`; the client renders the matching native widget and supplies the answer as the tool result (client-executed tool). This is also how generative UI is delivered.
- `record_answer(question, value)` — structured, validated answer capture; `value` is a discriminated union typed per answer type.
- `complete_session(summary)` — the summary is a validated tool argument, not parsed prose.

Consequence: no JSON-recovery hack, and the tool schema (in `packages/contract`)
becomes the single source of truth the Flutter client renders against. The old
`ColorText` feature reduces to one `answer_type` (`color`).

*2026-08-20: tool/argument names and the answer-type list updated to the terms
settled in [CONTEXT.md](../../CONTEXT.md) after researching the legacy app's
actual data model (`JournalQuestionSet`, five answer types). The decision itself
— tools, not prompted JSON — is unchanged.*
