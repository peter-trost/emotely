import { createHmac, timingSafeEqual } from "node:crypto";

/**
 * The transcript is client-held but server-authoritative: every response is
 * signed, and only transcripts carrying a valid signature advance. This is
 * what keeps an open, unauthenticated endpoint from being a generic LLM
 * proxy — the only client-authored content in a session is the widget
 * answer, which enters as a tool result (data, never instructions).
 */
export function signTranscript(transcript: unknown, secret: string): string {
  return createHmac("sha256", secret)
    .update(JSON.stringify(transcript))
    .digest("base64url");
}

/** Constant-time verification; malformed signatures are false, never throws. */
export function verifyTranscript(
  transcript: unknown,
  signature: string,
  secret: string,
): boolean {
  const expected = Buffer.from(signTranscript(transcript, secret));
  const provided = Buffer.from(signature);
  return (
    expected.length === provided.length && timingSafeEqual(expected, provided)
  );
}
