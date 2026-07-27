# Client is Flutter, iOS + Android only (no web)

The client is a Flutter app targeting iOS and Android only. No web target.

This is deliberate despite the project also being a public showcase (where a web
demo would be the easier thing to share):

- **The app is account-gated anyway.** You need an account to use it, so requiring
  an app download up front adds no real friction over a web sign-up.
- **Focus and simplicity now.** One rendering target for the generative UI (tool
  call → native widget) keeps the build small while the harness is proven.
- **Platform expansion is demand-driven, later.** We'll add a way for users to
  request additional platforms and reactively add them based on demand, rather than
  building web speculatively.

Flutter (not a web framework) also carries the "Flutter GenUI" showcase narrative
for the Flutter/VGV audience, distinct from the AI-engineering narrative that lives
in `apps/agent`.
