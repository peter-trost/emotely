import assert from "node:assert/strict";
import { describe, it } from "node:test";
import type { QuestionSet } from "./session.ts";
import { PROMPT_ID, PROMPTS, resolvePrompt } from "./session-prompt.ts";

const set: QuestionSet = {
  id: "s",
  name: "s",
  questions: [{ id: "q", text: "Q?", answer_type: "longtext" }],
};

describe("resolvePrompt", () => {
  it("returns the requested version when the registry ships it", () => {
    const fake = {
      "session/v1": () => "prompt one",
      "session/v2": () => "prompt two",
    };
    const resolved = resolvePrompt("session/v2", fake);
    assert.equal(resolved.id, "session/v2");
    assert.equal(resolved.build(set), "prompt two");
  });

  it("falls back to the current prompt for unknown versions", () => {
    const resolved = resolvePrompt("session/v999");
    assert.equal(resolved.id, PROMPT_ID);
    assert.ok(resolved.build(set).includes("journaling assistant"));
  });

  it("defaults to the current prompt when no version is requested", () => {
    const resolved = resolvePrompt(undefined);
    assert.equal(resolved.id, PROMPT_ID);
  });

  it("ships the current PROMPT_ID in the registry", () => {
    assert.ok(PROMPT_ID in PROMPTS);
  });
});
