---
name: supabase
description: How to run the local Supabase stack, write and test migrations and row-level security with pgTAP, read local sign-in codes, and deploy schema/auth config to the hosted project. Use whenever touching supabase/, the database schema, RLS policies, or auth configuration.
---

# Supabase (supabase/)

Everything here is agent-executable and needs Docker. The hosted project is
`emotely` (Frankfurt); its schema and auth settings only ever change through
`main` (ADR 0010). The CLI is pinned in `.github/workflows/ci.yml`
(`supabase/setup-cli` `version:`); keep the local install on the same version
(`brew upgrade supabase`).

## Local stack

Run from the repo root (that is where `supabase/config.toml` lives):

```bash
supabase start        # first run pulls images (minutes); later runs are seconds
supabase status -o env   # URLs and local keys, e.g. API_URL, ANON_KEY, DB_URL
supabase stop
```

- Studio: http://127.0.0.1:54323. Inbucket (every email the local Auth sends,
  including sign-in codes): http://127.0.0.1:54324.
- Storage, Realtime, Edge Functions and Analytics are disabled in
  `config.toml`; the product does not use them.

## Schema changes, test first

1. Write the assertion in `supabase/tests/*.test.sql` (pgTAP). Impersonate
   with the `pg_temp.login(uid)` / `pg_temp.anon()` / `pg_temp.logout()`
   helpers from `rls.test.sql`; they set the role and `request.jwt.claims`
   the way PostgREST does, so `auth.uid()` behaves as in production. Expect
   `42501` for privilege failures and RLS `with check` violations.
2. Run it red:

   ```bash
   supabase test db --local
   ```

3. Add the migration and apply it from scratch:

   ```bash
   supabase migration new <name>      # supabase/migrations/<timestamp>_<name>.sql
   supabase db reset --local          # drops, replays every migration, seeds
   supabase test db --local
   supabase db lint --local --fail-on warning
   ```

4. Regenerate the app's typed tables from the migrated local database and
   commit the result; CI regenerates from a fresh database and fails on any
   difference:

   ```bash
   (cd apps/mobile && melos run schema:generate)
   ```

   It writes `journal_repository/lib/src/supabase_schema.g.dart` with
   `supabase_typegen` (pinned as that package's dev dependency). `jsonb`
   columns come out as `Object?` and `check` constraints as plain `String`,
   so the freezed models still own those shapes.

Rules: grant privileges explicitly (nothing inherits from defaults), enable
RLS on every table, `(select auth.uid())` in policies, never a service-role
path in the app, the agent, CI or Vercel. The one carve-out is operator-run
and out of band: the release skill's `reviewer-accounts.sh` fetches the
`service_role` key blind through the maintainer's CLI login for one run to
(re)create the two store reviewer accounts (ADR 0010, decision 4). A
mutation check is cheap and worth it for policies:
`docker exec supabase_db_emotely psql -U postgres -c "alter table public.x disable row level security"`,
run the suite, watch it fail, `supabase db reset --local`.

## Auth configuration

`supabase/config.toml` `[auth]` sections are pushed to the hosted project by
CI (`supabase config push`). The sign-in code email is
`supabase/templates/sign_in_code.html`, wired under
`[auth.email.template.magic_link]`; locally it renders into Inbucket.

The hosted project sends through Resend (custom SMTP, #52), configured in
the `[remotes.production]` block at the end of `config.toml`. The CLI applies
that block only when the linked project ref matches its `project_id`, so
`supabase start` never touches it. The SMTP password is a Resend API key
restricted to sending from `getemotely.com`, stored blind as the GitHub `ci`
secret `SMTP_PASS`; the deploy job passes it through and nothing else reads
it. Rotating it: create a new sending-only key in the Resend dashboard
(`resend.com/api-keys`), copy it with the page's Copy button, pipe the
clipboard into `gh secret set SMTP_PASS --env ci`, clear the clipboard, then
re-run the deploy (any push to `main` touching `supabase/**`). Sender and
reply address is `hello@getemotely.com`, a Google Group in the Workspace.
Anything with a secret uses `env(VAR)` and is never committed.

## Google and Apple sign-in (native ID tokens)

The app signs in with Google (iOS, Android) and Apple (iOS only) by handing
the platform's ID token to `signInWithIdToken`; there is no browser
redirect, no callback URL and **no provider secret** anywhere (the ID-token
grant never reads one, and the CLI exempts both providers from requiring
it). `[auth.external.google]` and `[auth.external.apple]` in `config.toml`
carry only public client ids, so they apply locally and on the hosted
project alike.

- **Google** clients live in the Google Cloud project `emotely-sign-in`
  (Google Auth Platform, owned by the maintainer's personal Google account,
  publishing status *In production*, basic scopes only so no verification).
  `client_id` lists the web client first (Android's Credential Manager issues tokens for it; the
  app passes it as `serverClientId`), then the iOS client (the audience of
  iOS tokens). The two Android clients (Play App Signing SHA-1, and the
  maintainer's local debug key) are not audiences; they only let Google
  recognise the calling app. A new signing key (Play key upgrade, a CI debug
  keystore) needs its own Android client there, or Google sign-in fails on
  that build with a `canceled` error the plugin cannot tell apart from the
  user dismissing the sheet.
- **Apple** needs only the bundle id `de.emotely.emotely` as `client_id`.
  The App ID has the Sign in with Apple capability and the match profile
  carries `com.apple.developer.applesignin`; no Services ID, no key.
- **Nonce**: the app sends SHA-256(nonce) to the provider and the raw nonce
  to Auth, so `skip_nonce_check` stays `false`.
- **Identity linking** is automatic: a Google or Apple sign-in whose
  verified email matches an existing account lands in that same
  `auth.users` row. Apple's private relay addresses never match, so such a
  user gets a separate account.
- **After a deploy** that touches these blocks, confirm with
  `supabase config push` again from a linked checkout: it should report the
  auth config up to date (the Management API splits the comma list).

## The waitlist mail (double opt-in)

`public.waitlist` (ADR 0011) sends its own confirmation mail: an
after-insert trigger calls Resend's API through `pg_net`, with the key read
from Vault (`vault.decrypted_secrets`, name `resend_api_key`) at send time.
Nothing outside Postgres holds that key. The link in the mail calls the
anon-executable RPC `confirm_waitlist(token)`; unconfirmed rows are deleted
after a week by the guard trigger.

- **Local stacks have no key** and need none: the insert succeeds, the
  trigger logs `waitlist: no resend_api_key in vault` and sends nothing.
  `supabase/tests/waitlist_confirm.test.sql` creates a throwaway key inside
  its transaction and asserts the queued request instead.
- **Storing or rotating the production key** (agent-executable, value never
  seen): create a sending-only key in the Resend dashboard
  (`resend.com/api-keys`), copy it with the page's Copy button, then
  `pbpaste | sh supabase/scripts/vault-secret.sh resend_api_key "Resend, sending only, waitlist mail"`
  and clear the clipboard. The script writes the value through a 0600 temp
  file and `db query --file`, creating or updating the Vault row.
- **Checking a send** on the hosted project:
  `supabase db query --linked "select status_code, left(content, 120), created from net._http_response order by created desc limit 5"`
  — Resend answers `200 {"id": ...}`; a `401` means the key, a `422` the
  body. Postgres logs carry the warning when the key is missing.

## Deploying

A merge to `main` that touches `supabase/**` runs `supabase-deploy` in CI:
`supabase link` → `supabase db push` → `supabase config push`. It needs, in
the GitHub `ci` environment: secrets `SUPABASE_ACCESS_TOKEN` and
`SUPABASE_DB_PASSWORD` (set blind, never printed), variable
`SUPABASE_PROJECT_REF`.

By hand only for recovery, from the repo root, with the same three values in
the environment: `supabase link --project-ref "$SUPABASE_PROJECT_REF" && supabase db push`.
Check what would change first with `supabase db diff --linked`.
