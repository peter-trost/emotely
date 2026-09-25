/// The longest answer the agent accepts, as the agent measures it: the
/// length of `JSON.stringify(value)` in UTF-16 code units, so escapes, the
/// quotes around a string and a list's brackets and commas all count, and an
/// emoji counts twice. Mirrors `maxAnswerLength` in `packages/contract`,
/// pinned against its generated JSON Schema in the app's contract test.
const maxAnswerLength = 4096;
