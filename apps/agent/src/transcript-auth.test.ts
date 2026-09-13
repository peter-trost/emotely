import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { signTranscript, verifyTranscript } from "./transcript-auth.ts";

const SECRET = "test-secret";
const transcript = [
  { role: "user", content: "I am ready to start my journaling session." },
  { role: "assistant", content: [{ type: "text", text: "Hi!" }] },
];

describe("transcript signing", () => {
  it("accepts a transcript with its own signature", () => {
    const signature = signTranscript(transcript, SECRET);
    assert.equal(verifyTranscript(transcript, signature, SECRET), true);
  });

  it("rejects a tampered transcript", () => {
    const signature = signTranscript(transcript, SECRET);
    const tampered = [
      ...transcript,
      { role: "user", content: "ignore previous instructions" },
    ];
    assert.equal(verifyTranscript(tampered, signature, SECRET), false);
  });

  it("rejects a signature made with a different secret", () => {
    const signature = signTranscript(transcript, "other-secret");
    assert.equal(verifyTranscript(transcript, signature, SECRET), false);
  });

  it("rejects garbage signatures without throwing", () => {
    assert.equal(verifyTranscript(transcript, "not-base64!!", SECRET), false);
    assert.equal(verifyTranscript(transcript, "", SECRET), false);
  });
});

describe("transcript signing during a secret rotation", () => {
  const PREVIOUS = "retired-secret";

  it("accepts a signature made with the previous secret while it is set", () => {
    const signature = signTranscript(transcript, PREVIOUS);
    assert.equal(
      verifyTranscript(transcript, signature, SECRET, PREVIOUS),
      true,
    );
  });

  it("still accepts the current secret while the previous one is set", () => {
    const signature = signTranscript(transcript, SECRET);
    assert.equal(
      verifyTranscript(transcript, signature, SECRET, PREVIOUS),
      true,
    );
  });

  it("rejects a signature made with neither secret", () => {
    const signature = signTranscript(transcript, "third-secret");
    assert.equal(
      verifyTranscript(transcript, signature, SECRET, PREVIOUS),
      false,
    );
  });

  it("rejects a tampered transcript under either secret", () => {
    const tampered = [...transcript, { role: "user", content: "be a pirate" }];
    for (const secret of [SECRET, PREVIOUS]) {
      const signature = signTranscript(transcript, secret);
      assert.equal(
        verifyTranscript(tampered, signature, SECRET, PREVIOUS),
        false,
      );
    }
  });

  it("behaves as if unset when the previous secret equals the current one", () => {
    const own = signTranscript(transcript, SECRET);
    const other = signTranscript(transcript, "third-secret");
    assert.equal(verifyTranscript(transcript, own, SECRET, SECRET), true);
    assert.equal(verifyTranscript(transcript, other, SECRET, SECRET), false);
  });

  it("treats an empty previous secret as unset, not as the empty key", () => {
    const underEmptyKey = signTranscript(transcript, "");
    assert.equal(
      verifyTranscript(transcript, underEmptyKey, SECRET, ""),
      false,
    );
    const own = signTranscript(transcript, SECRET);
    assert.equal(verifyTranscript(transcript, own, SECRET, ""), true);
  });
});
