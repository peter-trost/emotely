import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { configResponse } from "@emotely/contract";
import { ZodError } from "zod";
import { CONFIG_CACHE_CONTROL, createConfigHandler } from "./http-config.ts";

const CONFIG = {
  minAppVersion: "1.0.0",
  storeUrl: "https://github.com/peter-trost/emotely/releases",
  storeUrlIos: "https://apps.apple.com/app/emotely",
  storeUrlAndroid: "https://play.google.com/store/apps/details?id=com.emotely",
};

function get(method = "GET", platform?: string): Request {
  const url = new URL("http://x/api/config");
  if (platform !== undefined) {
    url.searchParams.set("platform", platform);
  }
  return new Request(url, { method });
}

describe("config handler", () => {
  it("names the minimum app version and where to get a newer one", async () => {
    const res = await createConfigHandler(CONFIG)(get());
    assert.equal(res.status, 200);
    const body = await res.json();
    assert.deepEqual(body, {
      min_app_version: "1.0.0",
      store_url: "https://github.com/peter-trost/emotely/releases",
    });
    // The app pins against this schema; the server must satisfy it.
    assert.equal(configResponse.safeParse(body).success, true);
  });

  it("sends each platform to its own store", async () => {
    const handler = createConfigHandler(CONFIG);
    for (const [platform, expected] of [
      ["ios", CONFIG.storeUrlIos],
      ["android", CONFIG.storeUrlAndroid],
    ] as const) {
      const body = (await handler(get("GET", platform)).then((r) =>
        r.json(),
      )) as { store_url: string };
      assert.equal(body.store_url, expected, platform);
    }
  });

  it("falls back to the neutral store url for anything else", async () => {
    // An unknown, absent or malformed platform must still get a usable link:
    // a blocked user who cannot be identified still has to reach an update.
    const handler = createConfigHandler(CONFIG);
    for (const platform of [undefined, "", "web", "IOS ", "../etc"]) {
      const body = (await handler(get("GET", platform)).then((r) =>
        r.json(),
      )) as { store_url: string };
      assert.equal(body.store_url, CONFIG.storeUrl, String(platform));
    }
  });

  it("varies the cache on the platform, so one platform's link is not served to the other", async () => {
    // The response differs per platform, so a shared cache must key on it.
    const res = await createConfigHandler(CONFIG)(get("GET", "ios"));
    assert.match(res.headers.get("vary") ?? "", /platform/i);
  });

  it("answers without auth: the version gate runs before sign-in", async () => {
    // A blocked app must be told so even though it never signs in, so unlike
    // the session endpoint (ADR 0010) this one takes no Authorization header
    // into account at all.
    const res = await createConfigHandler(CONFIG)(get());
    assert.equal(res.status, 200);
  });

  it("is cacheable at the edge and identical for every caller", async () => {
    const res = await createConfigHandler(CONFIG)(get());
    assert.equal(res.headers.get("cache-control"), CONFIG_CACHE_CONTROL);
    // Shared cache, so it must not be keyed to one caller.
    assert.equal(res.headers.get("set-cookie"), null);
    assert.match(res.headers.get("content-type") ?? "", /application\/json/);
  });

  it("serves HEAD like GET and refuses anything that could change state", async () => {
    assert.equal((await createConfigHandler(CONFIG)(get("HEAD"))).status, 200);
    for (const method of ["POST", "PUT", "PATCH", "DELETE"]) {
      const res = await createConfigHandler(CONFIG)(get(method));
      assert.equal(res.status, 405, method);
      assert.deepEqual(await res.json(), {
        code: "method_not_allowed",
        error: "GET only",
      });
    }
  });

  it("refuses to serve a minimum or store url it cannot stand behind", async () => {
    // A typo in the constant must fail here, at the boundary, rather than
    // reach an app that would block every user on an unparseable version.
    for (const bad of [
      { ...CONFIG, minAppVersion: "1.0" },
      { ...CONFIG, minAppVersion: "v1.0.0" },
      { ...CONFIG, storeUrl: "/releases" },
      { ...CONFIG, storeUrl: "" },
      { ...CONFIG, storeUrlIos: "not-a-url" },
      { ...CONFIG, storeUrlAndroid: "market://details?id=x" },
    ]) {
      assert.throws(() => createConfigHandler(bad), ZodError);
    }
  });
});
