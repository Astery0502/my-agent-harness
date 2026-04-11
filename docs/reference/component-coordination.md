# Component Coordination Reference

This document explains how the active surfaces in `my-agent-harness` fit
together today.

- `runtime/commands/`
- `runtime/agents/`
- `runtime/skills/`
- `runtime/rules/`
- `runtime/platforms/`
- `ops/manifest.json`
- `scripts/`

Use it as a quick reference when you need to understand where a behavior lives
and which surface to inspect first.

## Lookup Order

- Start with `runtime/commands/` when you want to understand workflow entrypoints.
- Check `runtime/agents/` for specialist execution behavior.
- Check `runtime/skills/` for deeper reusable method guidance.
- Check `runtime/rules/` for policy and quality expectations.
- Check `runtime/platforms/` for Claude- or Codex-specific runtime differences.
- Check `ops/manifest.json` and `runtime/platforms/*/install-map.json` for sync scope and mapping.
- Check `scripts/` for operational flow.
- Check `tests/ops/` for automated structural contract tests (sync content, workflow contract encoding).
- Check `tests/workflow/<name>/` for behavioral trial prompts for a specific workflow.
- Check `docs/<name>-trials.md` for recorded trial results for a specific workflow.
- Check `.local/` only for generated local output, never as a source of truth.

## Coordination Table

| Surface | Main role | First look when | Related surfaces |
|---|---|---|---|
| `runtime/commands/` | Workflow entrypoints | A task starts in the wrong place | `runtime/agents/`, `runtime/skills/`, `runtime/rules/` |
| `runtime/agents/` | Specialist execution roles | A workflow starts correctly but behaves incorrectly | `runtime/skills/`, `runtime/rules/` |
| `runtime/skills/` | Reusable methods | A workflow lacks depth or concrete method | `runtime/commands/`, `runtime/agents/` |
| `runtime/rules/` | Policy and readiness expectations | Standards or escalation are unclear | `runtime/commands/`, `runtime/agents/` |
| `runtime/platforms/` | Runtime overlays and install maps | Behavior differs by target platform | `runtime/HARNESS.md`, `ops/manifest.json` |
| `ops/manifest.json` | Component and profile definitions | Sync scope or profile resolution looks wrong | `runtime/platforms/*/install-map.json`, `scripts/lib/` |
| `scripts/` | Operational entrypoints | Sync, drift detection, or repair is broken | `ops/manifest.json`, `.local/` |
| `tests/ops/` | Automated structural tests | A content assertion or contract check is failing | `runtime/`, `scripts/lib/` |
| `tests/workflow/<name>/` | Behavioral trial prompts | A workflow's LLM behavior needs verification | `docs/<name>-trials.md` |
| `docs/<name>-trials.md` | Trial results record | Checking whether a workflow behaves as designed | `tests/workflow/<name>/` |

## Practical Examples

- A planning prompt starts in `runtime/commands/plan.md`, dispatches to `runtime/agents/planner.md`, and should stay aligned with `runtime/rules/`.
- A review flow starts in `runtime/commands/review.md`, dispatches to `runtime/agents/reviewer.md`, and often leans on verification skills.
- Claude and Codex divergence should be explained under `runtime/platforms/`, not copied into shared runtime surfaces.
- If sync includes or omits the wrong files, inspect `ops/manifest.json` and `runtime/platforms/*/install-map.json` before changing script logic.
- To test whether a workflow's contracts are encoded correctly, run `tests/ops/test-workflow-content.sh`.
- To run behavioral trials for the plan workflow, use prompts in `tests/workflow/plan-workflow/` and record results in `docs/plan-workflow-trials.md`.
- To add behavioral tests for a new workflow, create `tests/workflow/<name>/` with trial files and `docs/<name>-trials.md` for results.

## Current Constraint

There is no hooks layer yet in this repo. If behavior looks automatic today,
check `scripts/` and `.local/`, not a nonexistent hook system.
