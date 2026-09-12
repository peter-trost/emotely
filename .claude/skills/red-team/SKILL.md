---
name: red-team
description: Red-team artifacts using two Opus subagents and fix what they find. Use when user says "red-team", "/red-team", "attack this", or wants an adversarial review of a plan, doc, design, or code, or before creating a PR as a review step.
---

# Red Team

Use 2 Opus subagents **in parallel** (dispatch both in a single message) to red-team the artifacts the user specifies. If no artifacts are specified, ask them which to red team.

Give each subagent a distinct angle:

- **Agent 1 — break it:** failure modes, edge cases, where it falls apart under pressure.
- **Agent 2 — what's missing:** unstated assumptions, gaps, things not considered.

Merge and dedup their findings, then fix any issues the red team finds. For anything that is hard to reverse or has a real, not-yet-decided-on tradeoff, discuss with the user before updating the artifact.
