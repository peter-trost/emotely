---
name: web
description: How to run, test, build and deploy the landing page (apps/web, Jaspr/Dart, getemotely.com), including the headless-Chrome form tests and the Vercel project wiring. Use whenever touching apps/web, the waitlist form, the site copy, or the site's Vercel deployment.
---

# The landing page (apps/web)

A static [Jaspr](https://jaspr.site) site in Dart: `lib/main.server.dart`
renders every route to HTML at build time, `lib/main.client.dart` mounts the
one `@client` island (`components/waitlist_form.dart`) in the browser. Plain
CSS in `web/styles.css`. No Node anywhere in this app.

Everything below is agent-executable; run from `apps/web`.

## Run

```bash
dart pub get
dart pub global activate jaspr_cli 0.23.4   # tracks the jaspr version in pubspec.yaml
jaspr serve                                  # http://localhost:8080, hot reload
```

## Check (what CI runs, in this order)

```bash
dart format --set-exit-if-changed .
dart analyze --fatal-infos
dart test                                    # VM: pages + the HTTP call
dart test -p chrome test/client              # headless Chrome: the form island
jaspr build --sitemap-domain https://getemotely.com   # → build/jaspr
git diff --exit-code -- lib                  # generated *.options.dart must not drift
```

Rules the lints enforce beyond `apps/app`: `jaspr_lints` (HTML helpers over
`Component.element`, children last, styles ordered). `@client` files must
use classic constructors — `jaspr_builder` parses them with analyzer 12,
which cannot read primary constructors; the per-file ignore in
`waitlist_form.dart` says so.

## Testing the island

`@client` components only take serialisable parameters, so the HTTP client
is not injected. The form calls `http.Client()`, which honours
`http.runWithClient`; tests wrap pump + interaction in it with a
`MockClient` (`package:http/testing.dart`). Drive the DOM with
`tester.input(find.byKey(...), value: ...)` and `tester.click(...)`, then
`await pumpEventQueue()`. `testComponents` (VM) cannot fire input events —
its `web.Event` has no target — so anything that reads an input runs under
`testClient` in Chrome.

## What the form talks to

`lib/waitlist.dart` posts to `public.waitlist` with the publishable key and
`Prefer: return=minimal`. The table (`supabase/migrations/*_waitlist.sql`,
ADR 0011) owns validation, silent de-duplication and rate limits and answers
201 / 429 (`PT429`) / 400. To exercise it locally, `supabase start` and pass
`--dart-define=EMOTELY_SUPABASE_URL=http://127.0.0.1:54321` plus the local
anon key to `jaspr serve` (see `lib/environment.dart`).

## Deploy

Vercel project `emotely-web` (`prj_Pd7GyDWACqua2yHuQFUbY6f8AQFn`), root
directory `apps/web`, GitHub integration on `peter-trost/emotely`.
Production: `getemotely.com`; `www.getemotely.com` redirects (308) to it.
`vercel.json` names the steps:

- `scripts/vercel-install.sh` — fetches Dart 3.13.3 (pinned, sha256 checked)
  because the build image has none, `dart pub get`, activates `jaspr_cli`.
- `scripts/vercel-build.sh` — `jaspr build` with the sitemap, then prunes the
  package assets `build_web_compilers` copies next to the JS.
- `scripts/vercel-ignore.sh` — exit 0 (skip) unless `apps/web` changed, so
  agent- or app-only PRs never build or preview the site. The agent project
  has the mirror image.

Bumping Dart: change `DART_VERSION` and `DART_SHA256` in the install script
(checksum from `…/sdk/dartsdk-linux-x64-release.zip.sha256sum` on the Dart
archive), the `sdk:` in `.github/workflows/ci.yml`, and the constraint in
`pubspec.yaml`.

Preview deployments are SSO-protected (Vercel default); production is
public. Inspect a build with `vercel inspect <url> --logs`.
