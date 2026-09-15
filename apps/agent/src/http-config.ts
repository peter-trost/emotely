import { type ConfigResponse, configResponse } from "@emotely/contract";

const HTTP_OK = 200;
const HTTP_METHOD_NOT_ALLOWED = 405;

/**
 * Cached at the edge, so the app's startup call almost never reaches a
 * function: the answer is the same for every caller and changes only on a
 * deploy. `stale-while-revalidate` keeps the gate answering from cache while
 * a new value propagates — the app blocks when this request fails, so serving
 * a few seconds of staleness is strictly better than serving an error.
 */
export const CONFIG_CACHE_CONTROL =
  "public, max-age=0, s-maxage=300, stale-while-revalidate=600";

/**
 * `GET /api/config`: what the app must know before it may run.
 *
 * Deliberately unauthenticated, unlike the session endpoint (ADR 0010). The
 * users this endpoint exists to block are on a version the server no longer
 * serves; making them sign in first to learn that puts the sign-in screen —
 * which may itself have moved on — in front of the force-update screen. The
 * body holds nothing private: a version number and a public store link.
 *
 * No signing, no model call, no user lookup: the cost profile of a static
 * file, which is what lets a public path carry its own rate-limit rule
 * cheaply (ADR 0008).
 */
export function createConfigHandler(config: {
  /** Oldest app version this server still serves; the app blocks below it. */
  minAppVersion: string;
  /** Where the force-update screen sends the user. */
  storeUrl: string;
}) {
  // Validate once per cold start, not per request: a malformed constant is a
  // deploy-time bug, and an app that cannot parse the minimum would block
  // every user. Failing here fails the deploy's first request loudly instead.
  const body: ConfigResponse = configResponse.parse({
    min_app_version: config.minAppVersion,
    store_url: config.storeUrl,
  });
  const payload = JSON.stringify(body);

  return (request: Request): Promise<Response> => {
    // Vercel's method-export routing already rejects anything but GET/HEAD
    // before this runs, so in production this branch is unreachable. Kept
    // because the handler is a plain function the CLI and the tests call
    // directly, and it must not answer a POST there either — the same
    // belt-and-braces check `createAdvanceSessionHandler` makes.
    if (request.method !== "GET" && request.method !== "HEAD") {
      return Promise.resolve(
        new Response(JSON.stringify({ error: "GET only" }), {
          status: HTTP_METHOD_NOT_ALLOWED,
          headers: { "content-type": "application/json" },
        }),
      );
    }
    return Promise.resolve(
      new Response(payload, {
        status: HTTP_OK,
        headers: {
          "content-type": "application/json",
          "cache-control": CONFIG_CACHE_CONTROL,
        },
      }),
    );
  };
}
