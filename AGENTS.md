# AGENTS.md

Codex guidance for working on `my-agent-harness`.

This repository is the source of truth for runtime content that syncs into
`~/.claude/` and `~/.codex/`. It is not an ECC fork.

## Repository Map

```text
ops/manifest.json                        # components and profiles
runtime/platforms/*/install-map.json     # per-platform source-to-target maps
runtime/{agents,skills,commands,rules}/  # shared installable content
runtime/platforms/{claude,codex}/        # platform-specific content
scripts/sync.sh                          # unified sync entry point
scripts/{doctor,repair,list-installed}.sh
scripts/lib/{layout,sync,ops}-common.sh  # shared shell libraries
tests/lib/test-helpers.sh                # shared test helpers
tests/ops/test-sync-*.sh                 # integration tests
.local/                                  # ignored state, staging, backups
```

## Commands

```bash
./scripts/sync.sh --platform claude [--profile claude-only] [--target live|staging] [--dry-run]
./scripts/sync.sh --platform codex [--profile codex-only] [--target live|staging] [--dry-run]
./scripts/doctor.sh [--target live|staging]
./scripts/repair.sh [--target live|staging]
./scripts/list-installed.sh [--target live|staging]
for t in tests/ops/test-sync-*.sh; do bash "$t" & done; wait
```

## Where to Look

- Installed components and profiles: `ops/manifest.json`
- Platform mappings: `runtime/platforms/*/install-map.json`
- Sync pipeline: `scripts/lib/sync-common.sh`
- Drift detection: `scripts/lib/ops-common.sh`
- Path helpers: `scripts/lib/layout-common.sh`
- Architecture and extension notes: `docs/architecture.md`

## Working Rules

- Edit source files in this repository, especially under `runtime/`.
- Do not edit generated `.local/` content or live runtime outputs in `~/.*`.
- Keep docs aligned when changing sync behavior, install behavior, or user-facing commands.
- New platforms should be discovered through `runtime/platforms/*/install-map.json`.
- Tests must use isolated temp directories and must not touch live runtime state.
- In tests, prefer behavior, durable state, semantic structure, and state transitions over brittle raw text or file-existence assertions unless that path or text is the contract.
- Keep changes surgical: do not refactor unrelated code, rewrite adjacent docs, or remove pre-existing dead code unless asked.
