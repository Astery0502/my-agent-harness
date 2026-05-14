# Pipeline

Commands, workflows, and extension procedures for `my-agent-harness`.

## Key Commands

```bash
# Sync
./scripts/sync.sh --platform claude [--profile claude-only] [--target live|staging] [--dry-run]
./scripts/sync.sh --platform codex  [--profile codex-only]  [--target live|staging] [--dry-run]

# Maintenance
./scripts/doctor.sh [--target live|staging]
./scripts/repair.sh [--target live|staging]
./scripts/list-installed.sh [--target live|staging]

# Tests (run in parallel, ~27s vs ~39s sequential)
for t in tests/ops/test-sync-*.sh; do bash "$t" & done; wait
```

## Sync Pipeline

Five explicit steps:

```
resolve(manifest, install-map, profile) -> action list
build(repo, actions)                    -> build tree
digest(build tree, actions)             -> component digests
deploy(build tree, target)              -> report
record(state file, digests, targets)    -> installed state
```

Doctor reads `componentTargets` and `componentDigests` from the state file and re-hashes deployed paths. No manifest or install-map resolution needed for drift detection.

## Install Flow

1. Author shared and platform content in `runtime/`
2. Describe components and profiles in `ops/manifest.json`
3. Tag install-map mappings with their component in `runtime/platforms/*/install-map.json`
4. Run `scripts/sync.sh --platform <name>` to install or update runtime files on the selected target
5. Results are recorded in `.local/install-state/<target>/*.json`
6. Staging installs are available under `.local/staging/`
7. Use `doctor.sh` and `repair.sh` to detect drift and restore consistency

## Extension Points

### Adding a new platform

1. Create `runtime/platforms/<name>/install-map.json` with `platform`, `defaultProfile`, `targetRoot`, and `mappings`
2. Add any platform-specific content under `runtime/platforms/<name>/`
3. Add a component for it in `ops/manifest.json` and reference it from a profile
4. The platform is auto-discovered by all scripts

### Adding a new component

1. Add the component and its paths to `ops/manifest.json`
2. Reference it from one or more profiles
3. Add mappings for it in the relevant install-map files

### Adding workflow tests

1. Create `tests/workflow/<workflow-name>/README.md` — explains the trials and links to the results doc
2. Add one trial file per target behavior: `tests/workflow/<workflow-name>/t<n>-<name>.md`
3. Create `docs/<workflow-name>-trials.md` as the living results record
4. Add `tests/ops/test-workflow-content.sh` assertions for any new structural contracts the workflow encodes
