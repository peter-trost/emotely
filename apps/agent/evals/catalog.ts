import process from "node:process";
import type { ModelRates } from "../src/cost.ts";

export type CatalogModel = ModelRates & {
  id: string;
  /** Unix seconds */
  released: number;
  tags: string[];
};

const PER_TOKEN_TO_PER_MILLION = 1_000_000;

type RawModel = {
  id: string;
  released?: number;
  tags?: string[];
  pricing?: {
    input?: string;
    output?: string;
    input_cache_read?: string;
  };
};

const perMillion = (perToken: string | undefined): number | undefined =>
  perToken === undefined
    ? undefined
    : Number(perToken) * PER_TOKEN_TO_PER_MILLION;

/** Live gateway catalog: the only source of truth for model prices. */
export async function fetchCatalog(): Promise<Map<string, CatalogModel>> {
  const key = process.env["AI_GATEWAY_API_KEY"];
  if (!key) {
    throw new Error("AI_GATEWAY_API_KEY is required to read the catalog");
  }
  const res = await fetch("https://ai-gateway.vercel.sh/v1/models", {
    headers: { Authorization: `Bearer ${key}` },
  });
  if (!res.ok) {
    throw new Error(`catalog request failed: ${res.status}`);
  }
  const body = (await res.json()) as { data: RawModel[] };
  const catalog = new Map<string, CatalogModel>();
  for (const m of body.data) {
    const inputPerM = perMillion(m.pricing?.input);
    const outputPerM = perMillion(m.pricing?.output);
    if (inputPerM === undefined || outputPerM === undefined) {
      continue;
    }
    const cacheReadPerM = perMillion(m.pricing?.input_cache_read);
    catalog.set(m.id, {
      id: m.id,
      inputPerM,
      outputPerM,
      ...(cacheReadPerM === undefined ? {} : { cacheReadPerM }),
      released: m.released ?? 0,
      tags: m.tags ?? [],
    });
  }
  return catalog;
}
