import process from "node:process";
import { createConfigHandler } from "../src/http-config.ts";
import {
  MIN_APP_VERSION,
  STORE_URL,
  STORE_URL_ANDROID,
  STORE_URL_IOS,
} from "../src/session-config.ts";

// No secrets, no Supabase, no telemetry: this endpoint answers from constants
// and is cached at the edge, so a cold start here must stay cheap. The
// `EMOTELY_STORE_URL*` variables correct a link without an app release, which
// matters because the users who follow it cannot install one.
const handler = createConfigHandler({
  minAppVersion: MIN_APP_VERSION,
  storeUrl: process.env["EMOTELY_STORE_URL"] ?? STORE_URL,
  storeUrlIos: process.env["EMOTELY_STORE_URL_IOS"] ?? STORE_URL_IOS,
  storeUrlAndroid:
    process.env["EMOTELY_STORE_URL_ANDROID"] ?? STORE_URL_ANDROID,
});

export function GET(request: Request): Promise<Response> {
  return handler(request);
}

export { GET as HEAD };
