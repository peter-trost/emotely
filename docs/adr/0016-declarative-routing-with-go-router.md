# Declarative routing with go_router, typed routes, nothing as `extra`

The Flutter client navigates with `go_router` (18.0.1) and routes generated
by `go_router_builder` (4.5.0) from typed declarations in one file,
`apps/mobile/app/lib/app/routes.dart`. The signed-in/out decision is the
router's `redirect`, re-evaluated when — and only when — whether someone is
signed in changes. A route carries only what its location can say: no
object ever travels as `extra`.

## Why a router

Screens were pushed imperatively (`Navigator.push(MaterialPageRoute(...))`)
and the signed-in/out root was a `BlocBuilder` swap (#62). With four screens
that already meant every pushed screen was handed the object it showed,
which is the one thing a deep link or a share link can never do; and a
sign-out from the account screen had to pop itself while the root swapped
underneath it, two places agreeing by convention. A route table makes every
screen reachable from a location, and one redirect replaces the convention.

## go_router over auto_route

Both were considered (#62). go_router won on facts that do not depend on
taste:

- **It resolves in the workspace.** `auto_route_generator` 10.6.0 caps the
  analyzer below 14; the workspace locks 14.4.0 for freezed 4. Adding
  auto_route would have pulled the analyzer back to 13.3 across every
  package and capped future freezed upgrades. The "support analyzer 14"
  issue had been open for five weeks without a maintainer reply.
- **It is maintained in flutter/packages** and had already moved to the
  `material_ui` / `cupertino_ui` split the app is on; auto_route's request
  to do the same was open with no comments.
- **It stays out of the feature packages.** go_router's routes are declared
  where the pages are composed — the app. auto_route's `@RoutePage()` goes
  on every page widget, so every feature package takes the dependency.
- **The toolchain assumes it.** The VGV navigation skill and its reviewers
  are written for go_router.

auto_route's genuine advantages — arbitrary typed objects as route
arguments, and tab stacks with independent histories — are exactly what the
`extra` ban forgoes and what `StatefulShellRoute` provides.

## Decisions

1. **The route table is the app's.** Features never import go_router. A
   feature reaches another feature's screen — or one of its own, now that
   routes exist — through its navigator (ADR 0015), which the app implements
   with a route. `JournalNavigator.openEntry` is a method on the seam even
   though `EntryPage` is the journal's own widget: the widget is the
   feature's, the route is the app's.

2. **Navigator seams take the `NavigatorState`**, as before. The app's
   implementation reaches the router through `navigator.context`, which
   outlives any screen: the journal captures the navigator before it awaits
   the server and must not reach back into a page that may have gone.
   `InheritedGoRouter` sits above the navigator, so the lookup is exact.

3. **No `extra`.** A route carries path and query parameters only, so every
   screen can be reached from its location alone. Where a screen used to be
   handed an object it now reads it back by id, and the objects moved to
   where they can be read:
   - `/entries/:id` — `EntryPage` reads the entry with a bloc of its own
     (`JournalRepository.entry`).
   - `/session?resume=<id>` — `SessionBloc` reads that stored session back
     itself (`JournalRepository.session`). A session discarded or finished
     on another device in the meantime starts fresh, which is more honest
     than resuming the journal's copy. The journal holds one session in
     progress at a time, but the route names which, so the location says
     what it does.
   - `/consent` — the route owns the `ConsentBloc` and pops with a
     `ConsentOutcome` (granted, declined, write failed; nothing when left
     unanswered), so the journal can still say why no session started
     without reading a bloc it no longer shares.

4. **The auth guard is a redirect over the live bloc state.** `authRedirect`
   is a pure function of "signed in?" and the location being entered:
   signed out, every location leads to sign-in, which remembers it as
   `?from=`; signed in, sign-in leads there — a deep link opened while
   signed out, or the screen the user was on when the session ended under
   them — or to the journal when there was nowhere in particular. Only a
   location of this app's that is not sign-in is honoured. Besides the
   pure tests, the router is tested for real: a deep link delivered the way
   the platform delivers it (`handlePushRoute`), then a sign-in through the
   screen. It reads `AuthBloc.state` when it runs, not a value captured
   earlier, and `refreshListenable` is a `ChangeNotifier` over the bloc's
   stream mapped to that one boolean and `distinct()`ed — the bloc moves
   through several states while a code is typed, none of which changes
   where the user may be. A sign-out from anywhere (the account screen, an
   expired token, an account deleted elsewhere — all of which the auth bloc
   mirrors from Supabase) lands on sign-in and replaces the whole stack.

5. **Typed routes are generated**, not hand-written. ADR 0015 declined
   injectable's codegen as ceremony; here the generator is what makes a
   route's parameters part of its type — `EntryRoute(id: ...)` cannot be
   built without one — and the workspace already runs freezed through the
   same build_runner pass, so the tripwire (`melos run codegen:check`)
   covers `routes.g.dart` for free. Routes use primary constructors like
   every other class; the generator reads them.

6. **`push` where the caller awaits an answer, `go` otherwise.** The
   session (the journal reloads when it pops) and the consent screen (its
   outcome) are pushed; the account and entry screens are gone to, as
   sub-routes of their tab so the back button leads to it.

7. **Two tabs, one `StatefulShellRoute`.** Signed in, the user lives in
   the journal tab (the journal, its entries) and the More tab (the
   account, consent, the legal documents, feedback, and signing out last
   — `feature_account`'s `MorePage`, in sections with a heading each).
   Each tab keeps its own stack. The session and the consent screen are
   declared outside the shell, at the root of the table, so pushing them
   covers the tab bar: a session is not something to switch away from.
   The journal's app bar lost its account and sign-out buttons to the
   More tab, and `JournalNavigator` lost the two methods with them.

## Consequences

- The startup gate (`ConfigGate`) and the PostHog survey host moved into
  `MaterialApp.router`'s `builder`, over the router's navigator: nothing
  below the gate is built until the server has said this build may run,
  exactly as before.
- `PosthogObserver` is handed to the router, which owns the navigator; the
  survey test asks the navigator for its observers rather than
  `MaterialApp`.
- Adding a screen is: a route class in `routes.dart`, a method on the
  owning feature's navigator if another feature reaches it, `dart run
  build_runner build` in the app. `apps/mobile/app/AGENTS.md` carries the
  rules.
- The premise of #62 aged: #51 moved to native ID-token sign-in, so there
  is no OAuth callback deep link, and sign-in is a one-time code rather
  than a magic link. There are no deep links today; the router makes them
  a matter of registering a scheme when one is wanted.

Decided on #62, 2026-09-20.
