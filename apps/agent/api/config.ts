import process from "node:process";
import { createConfigHandler } from "../src/http-config.ts";
import { MIN_APP_VERSION, STORE_URL } from "../src/session-config.ts";

// No secrets, no Supabase, no telemetry: this endpoint answers from two
// constants and is cached at the edge, so a cold start here must stay cheap.
// `EMOTELY_STORE_URL` overrides the default without a deploy of the app.
const handler = createConfigHandler({
  minAppVersion: MIN_APP_VERSION,
  storeUrl: process.env["EMOTELY_STORE_URL"] ?? STORE_URL,
});

export function GET(request: Request): Promise<Response> {
  return handler(request);
}

export { GET as HEAD };
