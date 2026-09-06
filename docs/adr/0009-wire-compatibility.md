# The server serves every app version still in use, so merging is deploying

`main` deploys `apps/agent` to production on merge (Vercel Git integration,
gated only by `ci-ok`; the Ignored Build Step in `apps/agent/scripts/vercel-ignore.sh`
skips commits that touch no agent build input). The app cannot deploy that way:
a store release takes days to review and weeks to reach every device, and users
never all update. So at any moment the production server talks to several app
versions at once, and a merge that breaks one of them breaks it for everyone on
it, instantly, with no CI run in between. The rules below make that merge safe
by construction. They were drafted in #37 and hold for every wire change from
here on.

## Rules

1. **Wire changes are additive.** New fields are optional on the way in and
   nullable on the way out; nothing is renamed, removed, or retyped. The client
   is a tolerant reader: unknown keys are ignored, absent optional keys mean
   "no such thing". `app_version` and `min_app_version` were added this way.
2. **A real incompatibility is a new endpoint** (`/api/v2/advance-session`, or a
   new path), never a changed one. The old endpoint stays until PostHog shows no
   traffic from app versions that use it, then it is deleted, not kept.
3. **Server before app.** One PR may change both sides, but the server side
   must be compatible with the app already in stores, because it goes live
   first and the app release follows whenever the store lets it.
4. **The app reports its version, the server names its minimum.** Every request
   carries `app_version` (bare semver from `pubspec.yaml`); every response
   carries `min_app_version`. Below the minimum the app blocks with a
   force-update screen. This is what allows rule 2's deletion: raising the
   minimum past a version is the moment its endpoints can go.
5. **Signing-secret rotation keeps in-flight sessions alive.** When
   `SESSION_SIGNING_SECRET` is rotated the server must accept the previous
   secret for a grace window as long as the transcript cap makes a session
   plausible. *Not implemented yet*: rotation has not happened, and the
   verifier accepts one secret. Implement it before the first rotation, never
   during.

## How the rules are enforced, not just written down

- **One contract, two pins.** The envelope of `POST /api/advance-session` and
  the tool payloads are zod schemas in `packages/contract`, emitted into
  `contract.schema.json`. CI regenerates the file and fails on a diff. The
  agent handler parses requests with the contract schema and every response
  literal must `satisfies` the contract type, so an envelope change that skips
  the contract fails `tsc`. The Dart side pins what `AgentClient` posts and
  every key its freezed decoders need against the emitted schema, read through
  the real serialization path. Drift fails one CI run on whichever side forgot.
- **Nullable on the Dart side is the additive escape hatch.** The Dart pin
  treats a nullable field as optional, so a server field can be required in
  the schema (the server always sends it) and still nullable in the app (a
  rollback to a build without it imposes nothing). `min_app_version` is the
  worked example.
- **The minimum is code, not configuration.** `MIN_APP_VERSION` in
  `apps/agent/src/session-config.ts` is `1.0.0`: nothing is blocked. Raising it
  is a PR like any other, reviewed, deployed on merge, and reversible by
  rollback. A PostHog flag would let it change without a deploy, but it would
  also put a network dependency on a field that must never be missing; a
  constant cannot fail to load.

### Raising the minimum

1. Check PostHog: `posthog_flutter` stamps `$app_version` on every event, so
   the share of sessions on versions below the candidate minimum is one
   breakdown away. Raise only when that share is zero or accepted.
2. Bump `MIN_APP_VERSION`, merge. From that deploy on, those users see the
   force-update screen and PostHog receives `update_required` with both
   versions, so the effect is measurable the same hour.
3. Only then delete the endpoints or wire shapes the blocked versions needed.

The force-update screen sends users to `EMOTELY_STORE_URL` (dart-define;
the releases page until the store listings exist, #9).

## Rollback is the recovery path

The gate is `ci-ok` before merge; when something still reaches production
broken, the correction is Vercel Instant Rollback, not a revert PR racing
through CI. Because of rule 3 the server can always be rolled back on its own:
the app in stores was compatible with the previous deployment by construction.

From `apps/agent` (the linked project directory):

```bash
vercel rollback <deployment-url-or-id>
```

`vercel ls` lists deployments; the dashboard's production tile has the same
button. What to know before pressing it, from Vercel's docs
([instant-rollback](https://vercel.com/docs/instant-rollback), read 2026-09-06):

- **Hobby can only roll back to the immediately previous production
  deployment.** Pro allows any deployment that was ever aliased to production.
  Two bad merges in a row therefore need a fix-forward PR, or Pro (which is on
  the release path anyway, see `AGENTS.md` § Billing).
- **A rollback freezes production.** Vercel turns off auto-assignment of the
  production domain, so later merges to `main` build but do not go live until
  the rollback is undone with `vercel promote <deployment-url-or-id>` (or the
  dashboard's **Undo Rollback**). Undo it as soon as the fix is merged, or
  `main` silently stops deploying.
- **Environment variables are not rolled back.** The restored deployment runs
  with the variables it was built with; a variable changed since then stays
  changed for new builds only.
- **The Ignored Build Step is unaffected**: it decides which commits build,
  the rollback decides which build serves traffic.

The app has no rollback. A broken app release is fixed by a new release, and
until it lands the server keeps serving the broken version whatever it sends,
which is exactly what rules 1 and 4 guarantee it can do.

## What follows from it

- **#7 (Supabase auth and persistence) will add fields, not change them.**
  Session ids, user ids and entry ids arrive as new optional keys; the
  anonymous flow keeps working until the minimum version says otherwise.
- **The nightly live smoke** exercises production with the current contract
  and would catch a server that stopped honouring an older shape only if it
  sent one. It does not; cross-version coverage comes from rule 1 and the
  contract pins, not from the smoke.
- **Reviewers check one thing on wire PRs**: is every change additive, and if
  not, is there a new endpoint. The pins catch the accidental cases; the
  rule is for the deliberate ones.
