# Tools-first agent harness (not prompted JSON)

The Journaling Assistant is built as a tool-calling agent (Vercel AI SDK loop), not
as a prompt that asks the model to emit parseable JSON.

The original emotely ran on the Firebase GenAI Chatbot extension: a ~2KB context
prompt begged the model to return `{response, summary}` as JSON, with a "recovery
prompt" retry whenever the output failed to parse. That fights the model and is
fragile.

Instead the model is given tools whose arguments are validated by the SDK:

- `ask_topic(topic, input_type)` — `input_type ∈ text | color_picker | mood_slider | multi_select`; the client renders the matching native widget. This is also how generative UI is delivered.
- `record_answer(topic, value)` — structured, validated answer capture.
- `complete_session(summary)` — the summary is a validated tool argument, not parsed prose.

Consequence: no JSON-recovery hack, and the tool schema (in `packages/contract`)
becomes the single source of truth the Flutter client renders against. The old
`ColorText` feature reduces to one `input_type` (`color_picker`).
