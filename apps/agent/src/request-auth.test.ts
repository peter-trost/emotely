import assert from "node:assert/strict";
import { describe, it } from "node:test";
import {
  createLocalJWKSet,
  exportJWK,
  generateKeyPair,
  type JWTPayload,
  SignJWT,
} from "jose";
import { createCallerVerifier } from "./request-auth.ts";

const ISSUER = "https://project.supabase.co/auth/v1";
const USER = "00000000-0000-0000-0000-00000000000a";

// A stand-in for the project's signing key: Supabase issues ES256 tokens and
// publishes the public half at /auth/v1/.well-known/jwks.json.
async function keyPair() {
  const { publicKey, privateKey } = await generateKeyPair("ES256");
  const jwk = { ...(await exportJWK(publicKey)), kid: "k1", alg: "ES256" };
  return { privateKey, keys: createLocalJWKSet({ keys: [jwk] }) };
}

const supabaseClaims: JWTPayload = {
  role: "authenticated",
  is_anonymous: false,
};

async function token(
  privateKey: CryptoKey,
  overrides: {
    claims?: JWTPayload;
    issuer?: string;
    audience?: string;
    expiresIn?: string;
  } = {},
): Promise<string> {
  return new SignJWT({ ...supabaseClaims, ...overrides.claims })
    .setProtectedHeader({ alg: "ES256", kid: "k1" })
    .setIssuer(overrides.issuer ?? ISSUER)
    .setAudience(overrides.audience ?? "authenticated")
    .setSubject(USER)
    .setIssuedAt()
    .setExpirationTime(overrides.expiresIn ?? "1h")
    .sign(privateKey);
}

function request(authorization?: string): Request {
  return new Request("http://x/api/advance-session", {
    method: "POST",
    headers: authorization === undefined ? {} : { authorization },
  });
}

describe("caller verification", () => {
  it("identifies a signed-in Supabase user by the sub claim", async () => {
    const { privateKey, keys } = await keyPair();
    const verify = createCallerVerifier({ keys, issuer: ISSUER });
    const caller = await verify(request(`Bearer ${await token(privateKey)}`));
    assert.deepEqual(caller, { userId: USER });
  });

  it("refuses requests without a bearer token", async () => {
    const { keys } = await keyPair();
    const verify = createCallerVerifier({ keys, issuer: ISSUER });
    assert.equal(await verify(request()), undefined);
    assert.equal(await verify(request("Basic abc")), undefined);
    assert.equal(await verify(request("Bearer ")), undefined);
    assert.equal(await verify(request("Bearer not.a.jwt")), undefined);
  });

  it("refuses a token signed by another key", async () => {
    const { keys } = await keyPair();
    const other = await keyPair();
    const verify = createCallerVerifier({ keys, issuer: ISSUER });
    const forged = await token(other.privateKey);
    assert.equal(await verify(request(`Bearer ${forged}`)), undefined);
  });

  it("refuses an expired token", async () => {
    const { privateKey, keys } = await keyPair();
    const verify = createCallerVerifier({ keys, issuer: ISSUER });
    const expired = await token(privateKey, { expiresIn: "-1s" });
    assert.equal(await verify(request(`Bearer ${expired}`)), undefined);
  });

  it("refuses a token from another issuer or for another audience", async () => {
    const { privateKey, keys } = await keyPair();
    const verify = createCallerVerifier({ keys, issuer: ISSUER });
    const elsewhere = await token(privateKey, {
      issuer: "https://other.supabase.co/auth/v1",
    });
    assert.equal(await verify(request(`Bearer ${elsewhere}`)), undefined);
    const someoneElse = await token(privateKey, { audience: "service" });
    assert.equal(await verify(request(`Bearer ${someoneElse}`)), undefined);
  });

  it("refuses anonymous users and non-user roles", async () => {
    const { privateKey, keys } = await keyPair();
    const verify = createCallerVerifier({ keys, issuer: ISSUER });
    const anonymous = await token(privateKey, {
      claims: { is_anonymous: true },
    });
    assert.equal(await verify(request(`Bearer ${anonymous}`)), undefined);
    const service = await token(privateKey, {
      claims: { role: "service_role" },
    });
    assert.equal(await verify(request(`Bearer ${service}`)), undefined);
  });
});
