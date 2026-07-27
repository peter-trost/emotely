# Monorepo for agent + app + shared contract

The agent (`apps/agent`, TypeScript) and the client (`apps/app`, Flutter) are two
halves of one product joined by a single contract: the agent emits tool calls, the
app renders a native widget per call. That tool-call schema lives in
`packages/contract` and must never drift between producer and consumer.

We chose a monorepo over two separate repos so a schema change plus both sides move
in one atomic, CI-verified commit — cross-repo, that same change is two PRs with a
drift window in between. As a solo founder this also means one CI, one release
story, one front door. Both apps are public (MIT) anyway, so the usual "keep one
half private" argument for splitting doesn't apply.

Tooling stays deliberately boring: pnpm workspaces for the TS side, Flutter's own
tooling for `apps/app`, path-filtered GitHub Actions. No Nx/Turbo/Bazel — the repo
is small and mixed-language dirs don't interfere.
