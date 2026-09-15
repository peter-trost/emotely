import assert from "node:assert/strict";
import { describe, it } from "node:test";
import {
  describeQualification,
  measureQualification,
  qualificationFromError,
  qualificationFromMetadata,
  qualificationReason,
} from "./provider-qualification.ts";

// The fixtures below are verbatim `providerMetadata.gateway` shapes captured
// from the live gateway on 2026-09-15 (issue #98). They are the contract this
// module parses, so they are copied rather than hand-written.

/** openai/gpt-oss-120b — the current default: all 8 providers qualify. */
const GPT_OSS_120B = {
  routing: {
    originalModelId: "openai/gpt-oss-120b",
    resolvedProvider: "baseten",
    fallbacksAvailable: [
      "fireworks",
      "bedrock",
      "togetherai",
      "nebius",
      "parasail",
      "groq",
      "cerebras",
    ],
    planningReasoning:
      "System credentials planned for: baseten, fireworks, bedrock, togetherai, nebius, parasail, groq, cerebras. ZDR requested: all 8 attempts support ZDR. Execution order: baseten(system). Disallow prompt training requested: all 8 attempts disallow prompt training",
  },
  enabledZeroDataRetention: true,
  enabledDisallowPromptTraining: true,
};

/** nvidia/nemotron-3.5-lightning — serves, but one provider is filtered out. */
const NEMOTRON = {
  routing: {
    originalModelId: "nvidia/nemotron-3.5-lightning",
    resolvedProvider: "fireworks",
    fallbacksAvailable: ["deepinfra", "runinfra"],
    planningReasoning:
      "System credentials planned for: fireworks, deepinfra, runinfra. ZDR requested: 3 attempts → 2 ZDR attempts.",
    skippedProviderAttempts: [
      {
        credentialType: "system",
        provider: "runinfra",
        reason: "zdr_not_supported",
      },
    ],
  },
  enabledZeroDataRetention: true,
  enabledDisallowPromptTraining: true,
};

/** A model whose single qualifying provider leaves no fallback headroom. */
const SINGLE_PROVIDER = {
  routing: {
    originalModelId: "google/gemini-3.7-flash",
    resolvedProvider: "vertex",
    fallbacksAvailable: ["google"],
    planningReasoning: "ZDR requested: 2 attempts → 1 ZDR attempts.",
    skippedProviderAttempts: [
      {
        credentialType: "system",
        provider: "google",
        reason: "zdr_not_supported",
      },
    ],
  },
  enabledZeroDataRetention: true,
  enabledDisallowPromptTraining: true,
};

describe("qualificationFromMetadata", () => {
  it("reports every provider qualifying when none was filtered out", () => {
    const q = qualificationFromMetadata(GPT_OSS_120B);
    assert.equal(q.served, true);
    assert.equal(q.zeroDataRetention, true);
    assert.equal(q.disallowPromptTraining, true);
    assert.equal(q.qualifyingProviders, 8);
    assert.equal(q.consideredProviders, 8);
    assert.deepEqual(q.disqualified, []);
  });

  it("counts the providers the privacy filters removed", () => {
    // 3 considered (fireworks, deepinfra, runinfra) − 1 skipped = 2 qualifying.
    const q = qualificationFromMetadata(NEMOTRON);
    assert.equal(q.served, true);
    assert.equal(q.qualifyingProviders, 2);
    assert.equal(q.consideredProviders, 3);
    assert.deepEqual(q.disqualified, ["runinfra:zdr_not_supported"]);
  });

  it("treats a request the gateway never confirmed the flags on as unqualified", () => {
    // Missing enabled* booleans means the filters were not applied — a typo in
    // the option keys forwards verbatim and is ignored silently (session-core).
    const q = qualificationFromMetadata({ routing: GPT_OSS_120B.routing });
    assert.equal(q.zeroDataRetention, false);
    assert.equal(q.disallowPromptTraining, false);
  });

  it("survives a gateway response with no routing metadata at all", () => {
    const q = qualificationFromMetadata(undefined);
    assert.equal(q.served, true);
    assert.equal(q.qualifyingProviders, 0);
    assert.equal(q.zeroDataRetention, false);
  });
});

describe("qualificationFromError", () => {
  it("classifies a model the gateway refuses under ZDR as not served", () => {
    const q = qualificationFromError(
      new Error(
        "GatewayInternalServerError: No ZDR (Zero Data Retention) providers or ZDR-attested BYOK credentials available for model: arcee-ai/trinity-large-thinking. Providers considered: arcee-ai",
      ),
    );
    assert.ok(q);
    assert.equal(q.served, false);
    assert.equal(q.qualifyingProviders, 0);
  });

  it("classifies a model that is itself ZDR-ineligible as not served", () => {
    const q = qualificationFromError(
      new Error(
        "GatewayInternalServerError: anthropic/claude-fable-5 is ineligible for Zero Data Retention (ZDR). This model retains data and cannot be used with ZDR configurations.",
      ),
    );
    assert.ok(q);
    assert.equal(q.served, false);
  });

  it("leaves an unrelated failure unclassified, so it stays a crash", () => {
    // A 503 or a malformed tool call must not be misreported as a privacy
    // rejection — those are retried as infrastructure blips.
    assert.equal(qualificationFromError(new Error("fetch failed")), undefined);
    assert.equal(
      qualificationFromError(new Error("rate limit exceeded")),
      undefined,
    );
  });
});

describe("qualificationReason", () => {
  it("has no complaint about a model every provider can serve", () => {
    assert.equal(
      qualificationReason(qualificationFromMetadata(GPT_OSS_120B)),
      undefined,
    );
  });

  it("rejects a model the privacy filters refuse outright", () => {
    const q = qualificationFromError(
      new Error(
        "No ZDR (Zero Data Retention) providers available for model: x",
      ),
    );
    assert.ok(q);
    assert.equal(
      qualificationReason(q),
      "no provider qualifies under ZDR + no-prompt-training",
    );
  });

  it("rejects a model left with a single qualifying provider", () => {
    // Fail-closed + one provider = every session fails if that provider drops
    // its agreement or has an outage. Too fragile to be the default.
    assert.equal(
      qualificationReason(qualificationFromMetadata(SINGLE_PROVIDER)),
      "only 1 of 2 providers qualify (no fallback headroom)",
    );
  });

  it("accepts a model that keeps fallback headroom after filtering", () => {
    assert.equal(
      qualificationReason(qualificationFromMetadata(NEMOTRON)),
      undefined,
    );
  });

  it("rejects a round the gateway did not confirm the flags on", () => {
    assert.equal(
      qualificationReason(
        qualificationFromMetadata({ routing: GPT_OSS_120B.routing }),
      ),
      "gateway did not confirm ZDR + no-prompt-training",
    );
  });
});

describe("measureQualification", () => {
  it("sends the same privacy options the product sends", async () => {
    // A probe under different options measures nothing about production.
    let seen: unknown;
    await measureQualification("openai/gpt-oss-120b", async (opts) => {
      seen = opts.providerOptions;
      return { providerMetadata: { gateway: GPT_OSS_120B } };
    });
    assert.deepEqual(seen, {
      gateway: { disallowPromptTraining: true, zeroDataRetention: true },
    });
  });

  it("reads the qualification out of a successful probe", async () => {
    const q = await measureQualification("openai/gpt-oss-120b", async () => ({
      providerMetadata: { gateway: GPT_OSS_120B },
    }));
    assert.equal(q.served, true);
    assert.equal(q.qualifyingProviders, 8);
  });

  it("turns a privacy rejection into a not-served verdict", async () => {
    const q = await measureQualification("arcee-ai/trinity-large", async () => {
      throw new Error(
        "No ZDR (Zero Data Retention) providers available for model: arcee-ai/trinity-large",
      );
    });
    assert.equal(q.served, false);
    assert.equal(
      qualificationReason(q),
      "no provider qualifies under ZDR + no-prompt-training",
    );
  });

  it("rethrows an unrelated failure instead of blaming privacy", async () => {
    await assert.rejects(
      measureQualification("openai/gpt-oss-120b", async () => {
        throw new Error("fetch failed");
      }),
      /fetch failed/,
    );
  });
});

describe("describeQualification", () => {
  it("renders the qualifying share for the report table", () => {
    assert.equal(
      describeQualification(qualificationFromMetadata(GPT_OSS_120B)),
      "8/8",
    );
    assert.equal(
      describeQualification(qualificationFromMetadata(NEMOTRON)),
      "2/3",
    );
  });

  it("renders a refused model as none", () => {
    const q = qualificationFromError(
      new Error(
        "No ZDR (Zero Data Retention) providers available for model: x",
      ),
    );
    assert.ok(q);
    assert.equal(describeQualification(q), "none");
  });

  it("renders an unmeasured model as a dash", () => {
    assert.equal(describeQualification(undefined), "—");
  });
});
