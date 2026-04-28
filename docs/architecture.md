# Harness Architecture

This document explains how `my-agent-harness` is organized and how it should evolve.

## Layer Model

The repository is split into four lookup-oriented layers:

1. project guidance
2. runtime source
3. ops and local state
4. docs and tests

## Project Guidance

- `AGENTS.md`
- `README.md`

`AGENTS.md` is the project-local contract for editing `my-agent-harness`
itself. `README.md` is the high-level orientation entry point.

## Runtime Source

`runtime/` holds the installable source surface:

- `runtime/HARNESS.md`
- `runtime/agents/`
- `runtime/skills/`
- `runtime/commands/`
- `runtime/rules/`
- `runtime/platforms/`

This layer answers:

- what reusable runtime content exists
- what the cross-platform baseline is
- how Claude- and Codex-specific overlays differ

## Ops And Local State

Tracked operational definitions live in:

- `ops/manifest.json` — component and profile definitions
- `runtime/platforms/*/install-map.json` — per-platform source-to-target mappings
- `scripts/` — operational entrypoints

Ignored generated local output lives in:

- `.local/install-state/live/`
- `.local/install-state/staging/`
- `.local/staging/`
- `.local/backups/`
- `.local/external/`

External skills in `ops/external-skills.json` are fetched into `.local/external/` and injected into the sync action list. Skills that need local edits or expensive upstream repositories should instead live under `runtime/skills/`; `runtime/skills/notebooklm/` follows this model and records its upstream `notebooklm-py` version in the skill file. Use `scripts/check-external-skills-update.sh` to check whether any registered external skills have upstream updates available.

This layer answers:

- what components and profiles exist
- how sources map to per-platform targets
- how sync, doctor, repair, and listing operate
- where mutable local output is stored

## Install Flow

The intended install flow is:

1. author shared and platform content in `runtime/`
2. describe components and profiles in `ops/manifest.json`
3. tag install-map mappings with their component in `runtime/platforms/*/install-map.json`
4. run `scripts/sync.sh --platform <name>` to install or update runtime files on the selected target
5. record results in `.local/install-state/<target>/*.json`
6. keep staging installs available under `.local/staging/`
7. use doctor and repair scripts to detect drift and restore consistency

## Pipeline

The sync pipeline follows five explicit steps:

```
resolve(manifest, install-map, profile) -> action list
build(repo, actions)                    -> build tree
digest(build tree, actions)             -> component digests
deploy(build tree, target)              -> report
record(state file, digests, targets)    -> installed state
```

Doctor reads stored `componentTargets` and `componentDigests` from the state file and re-hashes the deployed paths. No manifest or install-map resolution is needed for drift detection.

## Folder Responsibilities

- `runtime/agents/`: specialist roles the harness may expose
- `runtime/skills/`: reusable methods and workflows
- `runtime/commands/`: entrypoints that coordinate workflows
- `runtime/rules/`: policy and quality expectations
- `runtime/platforms/`: Claude- and Codex-specific runtime files and install maps
- `ops/manifest.json`: component and profile declarations
- `scripts/`: operational entrypoints (`sync.sh`, `doctor.sh`, `repair.sh`, `list-installed.sh`, `check-external-skills-update.sh`, `check-notebooklm-skill-update.sh`)
- `scripts/lib/`: shared libraries (`layout-common.sh`, `sync-common.sh`, `ops-common.sh`)
- `tests/lib/`: shared test helpers
- `tests/ops/`: integration test suites (sync pipeline, workflow structural contracts)
- `tests/workflow/`: behavioral trial prompts for runtime workflows, one subdirectory per workflow
- `.local/install-state/`: ignored target-scoped install status
- `.local/staging/`: ignored staging runtime output
- `.local/backups/`: ignored backups of overwritten managed live targets
- `docs/reference/`: evergreen lookup docs
- `docs/archive/`: historical plans and exploratory notes
- `docs/decisions/`: local architecture decisions

## Extension Points

Adding a new platform:

1. create `runtime/platforms/<name>/install-map.json` with `platform`, `defaultProfile`, `targetRoot`, and `mappings`
2. add any platform-specific content under `runtime/platforms/<name>/`
3. add a component for it in `ops/manifest.json` and reference it from a profile
4. the platform is auto-discovered by all scripts

Adding a new component:

1. add the component and its paths to `ops/manifest.json`
2. reference it from one or more profiles
3. add mappings for it in the relevant install-map files

Adding workflow tests for a new command/skill:

1. create `tests/workflow/<workflow-name>/README.md` — explains the trials and links to the results doc
2. add one trial file per target behavior: `tests/workflow/<workflow-name>/t<n>-<name>.md`
3. create `docs/<workflow-name>-trials.md` as the living results record
4. add `tests/ops/test-workflow-content.sh` assertions for any new structural contracts the workflow encodes

## Deferred Work

The first milestone intentionally defers:

- hooks and runtime enforcement
- project starter templates
- deep workflow implementation
- automatic merge or generation logic

That keeps the repository understandable while still establishing the right long-term boundaries.
