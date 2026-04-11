# CLAUDE.md

Personal harness repo that syncs runtime content (agents, skills, commands, rules) into `~/.claude/` and `~/.codex/`. Source of truth for how AI coding tools behave. Not an ECC fork.

## Structure

```text
ops/manifest.json                        # components + profiles
runtime/platforms/*/install-map.json     # per-platform source→target mappings (tagged by component)
runtime/{agents,skills,commands,rules}/  # shared installable content
runtime/platforms/{claude,codex}/        # platform-specific content
scripts/sync.sh                          # unified sync entry point
scripts/{doctor,repair,list-installed}.sh
scripts/lib/{layout,sync,ops}-common.sh  # shared libraries
tests/lib/test-helpers.sh                # shared test helpers
tests/ops/test-sync-*.sh                 # integration tests
.local/                                  # gitignored: install-state, staging, backups
```

## Key commands

```bash
./scripts/sync.sh --platform claude [--profile claude-only] [--target live|staging] [--dry-run]
./scripts/doctor.sh [--target live|staging]
./scripts/repair.sh [--target live|staging]
./scripts/list-installed.sh [--target live|staging]
for t in tests/ops/test-sync-*.sh; do bash "$t"; done   # run all tests
```

## Where to look

- **What gets installed**: `ops/manifest.json` → profiles → components → paths
- **How it maps per platform**: `runtime/platforms/*/install-map.json`
- **Sync pipeline logic**: `scripts/lib/sync-common.sh` (resolve → build → digest → deploy → record)
- **Drift detection**: `scripts/lib/ops-common.sh` → `ops_compute_actual_digests` (reads state, no re-resolution)
- **Layout/paths**: `scripts/lib/layout-common.sh`
- **How to extend**: `docs/architecture.md` § Extension Points
- **Component coordination**: `docs/reference/component-coordination.md`

## Working rules

- Edit source in `runtime/`, never in `.local/` or `~/.*` outputs
- Keep docs aligned when changing sync behavior
- New platforms auto-discover from `runtime/platforms/*/install-map.json`
- Tests run in isolated temp dirs; never touch live environment
