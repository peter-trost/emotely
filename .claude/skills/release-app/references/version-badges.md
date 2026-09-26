# Version badges (README)

The README shows what each channel last received, e.g. `TestFlight internal |
2.0.0 (1042)`. It is pushed, not polled: a lane calls `report_shipped` after
its upload, which writes `version` and `build` to the step's `$GITHUB_OUTPUT`;
the internal jobs expose them as job outputs; the workflow's `status` job runs
`scripts/release-status.sh` on `status.json` and commits it to the orphan
**`status`** branch through the git data API. shields.io's dynamic JSON badge
reads `raw.githubusercontent.com/.../status/status.json` (about 5-10 min of
caching end to end).

- **What a badge means:** uploaded to that channel, not processed or reviewed.
  A failed job leaves its badge on the last good build.
- **History:** `gh api 'repos/trost-systems/emotely/commits?sha=status'`. The
  ruleset `status branch: append-only` blocks force pushes and deletion.
- **Adding a channel** (the beta lanes, later a store lane): call
  `report_shipped` at the end of that lane with what it actually promoted,
  give its job `outputs` and an `id: lane` step, add it to `needs` and the
  script of the `status` job, widen the allowlist in `release-status.sh` with
  a test, and add a README badge with the query `$.<platform>.<track>.label`.
- **Keep `status` bare:** it is the only job with `contents: write`, so never
  give it the `release` environment, a build, or a checkout beyond the script.
