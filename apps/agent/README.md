# apps/agent

The deployed TypeScript service that runs the tool-calling session loop
(`POST /api/advance-session`) on Vercel. Architecture and the reasons behind
it live in the root [`README.md`](../../README.md) and [`docs/adr/`](../../docs/adr/);
this file holds what is specific to operating the service.

## Environment variables

Read once per cold start in [`api/advance-session.ts`](api/advance-session.ts).
Values are set on the `emotely-agent` Vercel project by a human, never
committed (see the root [`AGENTS.md`](../../AGENTS.md)).

| Variable | Required | Purpose |
| --- | --- | --- |
| `SESSION_SIGNING_SECRET` | yes | HMAC key that signs every transcript the server returns; only transcripts it signed advance ([ADR 0008](../../docs/adr/0008-public-endpoint-abuse-controls.md)). |
| `SESSION_SIGNING_SECRET_PREVIOUS` | no | The secret being retired. Set only for the grace window of a rotation (below); unset in normal operation. An empty value counts as unset. |
| `SUPABASE_URL` | yes | The Supabase project whose users may call ([ADR 0010](../../docs/adr/0010-supabase-data-layer.md)). |
| `AI_GATEWAY_API_KEY` | yes | Vercel AI Gateway key ([ADR 0003](../../docs/adr/0003-model-gateway-and-cost-ceiling.md)). |
| `EMOTELY_MODEL` | no | Overrides `DEFAULT_MODEL` in `src/session-config.ts`. |
| `POSTHOG_KEY`, `POSTHOG_HOST` | no | LLM observability; both or neither ([ADR 0004](../../docs/adr/0004-posthog-observability-stack.md)). |

## Rotating the signing secret

The session is stateless: the client holds the transcript and its signature and
posts both back every round. A rotation that only swapped
`SESSION_SIGNING_SECRET` would therefore turn every in-flight session into a
401 on its next round. ADR 0009 rule 5 says that must not happen, and the
verifier implements it: it accepts a signature made with **either** the current
secret or the previous one, while signing always uses the current one. A
transcript signed under the old secret is accepted once and comes back signed
with the new one, so sessions migrate by themselves within one round.

The grace window is exactly the time `SESSION_SIGNING_SECRET_PREVIOUS` is set.
A session is at most 200 messages ([ADR 0008](../../docs/adr/0008-public-endpoint-abuse-controls.md)),
so a day is plenty; sessions abandoned for longer than that fail their next
round with a 401 and start over, which is the same outcome as today.

Secret values are handled by a human and never enter a terminal transcript or
a chat: generate them out of band and pipe them in blind. Run the CLI from
`apps/agent`, the linked project directory.

1. **Stage the old secret as the previous one.** Copy the current value of
   `SESSION_SIGNING_SECRET` from the project's environment variables (Vercel
   dashboard → `emotely-agent` → Settings → Environment Variables) into a
   temporary file, then:

   ```bash
   vercel env add SESSION_SIGNING_SECRET_PREVIOUS production < /path/to/old-secret.txt
   ```

2. **Set the new secret.** Generate a fresh value (e.g. `openssl rand -base64 48`
   straight into a file) and update the current secret:

   ```bash
   vercel env update SESSION_SIGNING_SECRET production < /path/to/new-secret.txt
   ```

   Delete both temporary files.

3. **Deploy.** Environment variables apply to the next deployment, and the
   Ignored Build Step skips commits that touch no agent input, so rebuild the
   current production deployment explicitly:

   ```bash
   vercel redeploy <current-production-deployment-url>
   ```

   From here every response is signed with the new secret and transcripts
   signed with the old one are still accepted.

4. **Wait a day**, then close the window:

   ```bash
   vercel env rm SESSION_SIGNING_SECRET_PREVIOUS production
   vercel redeploy <current-production-deployment-url>
   ```

Things worth knowing:

- **Order matters.** Steps 1 and 2 must both be in place before step 3; a
  deploy between them serves neither the old secret as previous nor the new
  one as current, so only one of the two is accepted during that deploy.
- **Setting `PREVIOUS` to the new value** (instead of the old one) is harmless
  but useless: the verifier then accepts only the new secret, exactly as if
  the variable were unset, and in-flight sessions fail. The old value goes in
  `PREVIOUS`, the new one in `SESSION_SIGNING_SECRET`.
- **Never leave `PREVIOUS` set.** While it is set, two secrets open the
  endpoint instead of one; step 4 is part of the rotation, not optional
  cleanup.
- **Do not rotate to recover from a leak without both steps.** Removing a
  compromised secret needs the window closed immediately: skip the wait in
  step 4 and accept the failed rounds.

## Scripts

`package.json` is the reference; the ones that matter in CI are `lint`
(repo root), `typecheck`, `test`, and `eval` (live-model protocol eval,
needs `AI_GATEWAY_API_KEY`). `smoke` is the nightly live probe against
production.
