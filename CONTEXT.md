# Context

Structural reference for `my-agent-harness`. Not runtime guidance — see `CLAUDE.md` or `AGENTS.md` for working rules, `PIPELINE.md` for commands.

## Repository Map

```text
ops/manifest.json                        # components + profiles
ops/external-skills.json                 # remote skills registry (fetched separately)
runtime/platforms/*/install-map.json     # per-platform source→target mappings (tagged by component)
runtime/{agents,skills,commands,rules}/  # shared installable content
runtime/platforms/{claude,codex}/        # platform-specific content
scripts/sync.sh                          # unified sync entry point
scripts/{doctor,repair,list-installed}.sh
scripts/lib/{layout,sync,ops}-common.sh  # shared libraries
tests/lib/test-helpers.sh                # shared test helpers
tests/ops/test-sync-*.sh                 # integration tests
.local/                                  # gitignored: install-state, staging, backups, external
```

## Where to Look

- **What gets installed**: `ops/manifest.json` → profiles → components → paths
- **How it maps per platform**: `runtime/platforms/*/install-map.json`
- **Sync pipeline logic**: `scripts/lib/sync-common.sh` (resolve → build → digest → deploy → record)
- **Drift detection**: `scripts/lib/ops-common.sh` → `ops_compute_actual_digests`
- **Layout/paths**: `scripts/lib/layout-common.sh`
- **Remote skills**: `ops/external-skills.json` — sync warns if upstream changed; install via the skill's own entrypoint
- **Extension procedures**: `PIPELINE.md` § Extension Points

## Layer Model

The repository is organized into four layers:

1. **Project guidance** — `CLAUDE.md`, `AGENTS.md`, `CONTEXT.md`, `PIPELINE.md`
2. **Runtime source** — `runtime/` (installable content)
3. **Ops and local state** — `ops/`, `scripts/`, `.local/`
4. **Docs and tests** — `docs/`, `tests/`

## Folder Responsibilities

- `runtime/agents/`: specialist roles the harness may expose
- `runtime/skills/`: reusable methods and workflows
- `runtime/commands/`: entrypoints that coordinate workflows
- `runtime/rules/`: policy and quality expectations
- `runtime/platforms/`: Claude- and Codex-specific runtime files and install maps
- `ops/manifest.json`: component and profile declarations
- `scripts/`: operational entrypoints (`sync.sh`, `doctor.sh`, `repair.sh`, `list-installed.sh`)
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

## Deferred Work

The first milestone intentionally defers:

- hooks and runtime enforcement
- project starter templates
- deep workflow implementation
- automatic merge or generation logic
