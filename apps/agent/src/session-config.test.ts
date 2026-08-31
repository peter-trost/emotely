import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { describe, it } from "node:test";
import { DEFAULT_MODEL, resolveSessionConfig } from "./session-config.ts";
import { PROMPT_ID } from "./session-prompt.ts";

const dir = () => mkdtempSync(join(tmpdir(), "emotely-config-"));

describe("resolveSessionConfig", () => {
  it("uses the flag payload and caches it for the next session", async () => {
    const stateDir = dir();
    const config = await resolveSessionConfig({
      stateDir,
      fetchPayload: async () => ({
        model: "test/flag-model",
        promptId: "session/v9",
      }),
    });
    assert.equal(config.model, "test/flag-model");
    assert.equal(config.promptId, "session/v9");
    const cached = JSON.parse(
      readFileSync(join(stateDir, "agent-model.json"), "utf8"),
    );
    assert.equal(cached.model, "test/flag-model");
    assert.equal(cached.promptId, "session/v9");
  });

  it("falls back to the hardcoded default when PostHog is unreachable", async () => {
    const config = await resolveSessionConfig({
      stateDir: dir(),
      fetchPayload: async () => {
        throw new Error("connect ECONNREFUSED");
      },
    });
    assert.equal(config.model, DEFAULT_MODEL);
    assert.equal(config.promptId, PROMPT_ID);
  });

  it("falls back to the default when the fetch exceeds the timeout", async () => {
    const config = await resolveSessionConfig({
      stateDir: dir(),
      timeoutMs: 20,
      fetchPayload: () =>
        new Promise((resolve) =>
          setTimeout(() => resolve({ model: "too/late", promptId: "x" }), 200),
        ),
    });
    assert.equal(config.model, DEFAULT_MODEL);
    assert.equal(config.promptId, PROMPT_ID);
  });

  it("serves the cached payload when the current fetch fails", async () => {
    const stateDir = dir();
    writeFileSync(
      join(stateDir, "agent-model.json"),
      JSON.stringify({ model: "test/cached-model", promptId: "session/v8" }),
    );
    const config = await resolveSessionConfig({
      stateDir,
      fetchPayload: async () => {
        throw new Error("offline");
      },
    });
    assert.equal(config.model, "test/cached-model");
    assert.equal(config.promptId, "session/v8");
  });

  it("ignores malformed payloads", async () => {
    const config = await resolveSessionConfig({
      stateDir: dir(),
      fetchPayload: async () => ({ model: 42 }),
    });
    assert.equal(config.model, DEFAULT_MODEL);
    assert.equal(config.promptId, PROMPT_ID);
  });

  it("generates a stable anonymous distinct id per state dir", async () => {
    const stateDir = dir();
    const fetchPayload = async () => undefined;
    const a = await resolveSessionConfig({ stateDir, fetchPayload });
    const b = await resolveSessionConfig({ stateDir, fetchPayload });
    assert.equal(a.distinctId, b.distinctId);
    assert.ok(a.distinctId.length >= 16);
    const other = await resolveSessionConfig({ stateDir: dir(), fetchPayload });
    assert.notEqual(a.distinctId, other.distinctId);
  });
});
