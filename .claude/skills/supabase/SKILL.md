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

Rules: grant privileges explicitly (nothing inherits from defaults), enable
RLS on every table, `(select auth.uid())` in policies, never a service-role
path. A mutation check is cheap and worth it for policies:
`docker exec supabase_db_emotely psql -U postgres -c "alter table public.x disable row level security"`,
run the suite, watch it fail, `supabase db reset --local`.

## Auth configuration

`supabase/config.toml` `[auth]` sections are pushed to the hosted project by
CI (`supabase config push`). The sign-in code email is
`supabase/templates/sign_in_code.html`, wired under
`[auth.email.template.magic_link]`. That block is commented out until custom
SMTP exists (#52): the hosted free tier refuses template changes on the
built-in mailer and `config push` fails on it, and Supabase's default
magic-link mail carries no code, so hosted email-code sign-in does not work
before #52. The local stack has no such limit: uncomment the block locally to
see the code in Inbucket, never commit it uncommented before #52.
Anything with a secret uses `env(VAR)` and is never committed.

## Deploying

A merge to `main` that touches `supabase/**` runs `supabase-deploy` in CI:
`supabase link` → `supabase db push` → `supabase config push`. It needs, in
the GitHub `ci` environment: secrets `SUPABASE_ACCESS_TOKEN` and
`SUPABASE_DB_PASSWORD` (set blind, never printed), variable
`SUPABASE_PROJECT_REF`.

By hand only for recovery, from the repo root, with the same three values in
the environment: `supabase link --project-ref "$SUPABASE_PROJECT_REF" && supabase db push`.
Check what would change first with `supabase db diff --linked`.
