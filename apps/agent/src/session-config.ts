import { randomUUID } from "node:crypto";
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import { z } from "zod";
import { PROMPT_ID } from "./session-prompt.ts";

// The benchmark winner (#4); the 'agent-model' PostHog flag overrides it.
export const DEFAULT_MODEL = "openai/gpt-oss-120b";
const FLAG_TIMEOUT_MS = 800;
const CACHE_FILE = "agent-model.json";
const ID_FILE = "distinct-id";

const payloadSchema = z.object({ model: z.string(), promptId: z.string() });
type FlagPayload = z.infer<typeof payloadSchema>;

export type SessionConfig = FlagPayload & { distinctId: string };

function readText(path: string): string | undefined {
  return existsSync(path) ? readFileSync(path, "utf8") : undefined;
}

function readJson(path: string): unknown {
  const raw = readText(path);
  try {
    return raw === undefined ? undefined : JSON.parse(raw);
  } catch {
    return null; // malformed cache — schema validation rejects null downstream
  }
}

function stableDistinctId(stateDir: string): string {
  const path = join(stateDir, ID_FILE);
  const existing = readText(path)?.trim();
  if (existing) {
    return existing;
  }
  const id = randomUUID();
  writeFileSync(path, `${id}\n`);
  return id;
}

async function fetchWithTimeout(
  fetchPayload: (distinctId: string) => Promise<unknown>,
  distinctId: string,
  timeoutMs: number,
): Promise<unknown> {
  let timer: NodeJS.Timeout | undefined;
  try {
    return await Promise.race([
      fetchPayload(distinctId),
      new Promise((_, reject) => {
        timer = setTimeout(() => reject(new Error("flag timeout")), timeoutMs);
      }),
    ]);
  } finally {
    clearTimeout(timer);
  }
}

/**
 * Model + prompt come from the 'agent-model' flag payload, cached on disk so a
 * session never waits on PostHog twice and never fails because of it:
 * fresh payload → cached payload → hardcoded default, in that order.
 */
export async function resolveSessionConfig(opts: {
  fetchPayload: (distinctId: string) => Promise<unknown>;
  stateDir?: string;
  timeoutMs?: number;
}): Promise<SessionConfig> {
  const stateDir = opts.stateDir ?? join(homedir(), ".config", "emotely");
  mkdirSync(stateDir, { recursive: true });
  const distinctId = stableDistinctId(stateDir);
  const cachePath = join(stateDir, CACHE_FILE);

  let payload: FlagPayload | undefined;
  try {
    const raw = await fetchWithTimeout(
      opts.fetchPayload,
      distinctId,
      opts.timeoutMs ?? FLAG_TIMEOUT_MS,
    );
    const parsed = payloadSchema.safeParse(raw);
    if (parsed.success) {
      payload = parsed.data;
      writeFileSync(cachePath, JSON.stringify(payload));
    }
  } catch {
    // unreachable / timed out — fall through to cache, then default
  }

  if (!payload) {
    const cached = payloadSchema.safeParse(readJson(cachePath));
    payload = cached.success
      ? cached.data
      : { model: DEFAULT_MODEL, promptId: PROMPT_ID };
  }
  return { ...payload, distinctId };
}
