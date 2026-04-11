# My Agent Harness

`my-agent-harness` is a personal harness repo for shaping how AI coding tools behave across Claude Code and Codex.

It borrows useful patterns from ECC, but it does not depend on ECC as a base layer. This repo is the source of truth.

## Repository Shape

```text
my-agent-harness/
├── AGENTS.md
├── README.md
├── runtime/
├── ops/
├── scripts/
├── tests/
├── docs/
└── .local/                # ignored generated output
```

## Lookup Guide

- `AGENTS.md`: project-local guidance for changing this repo
- `runtime/`: installable shared/runtime source, including `runtime/HARNESS.md`
- `ops/manifest.json`: component and profile definitions
- `runtime/platforms/*/install-map.json`: per-platform source-to-target mappings
- `scripts/`: stable shell entrypoints
- `tests/`: integration tests for the sync and ops pipeline
- `docs/README.md`: index to active architecture, reference docs, decisions, and archive
- `.local/`: ignored install-state and staged runtime output

## Runtime Targets

This repo is intended to sync into:

- `~/.claude/`
- `~/.codex/`

`AGENTS.md` is for this repository as a project. `runtime/HARNESS.md` is the
shared installable runtime baseline. `runtime/platforms/` defines how shared
content maps into each runtime target.

## Install Model

The install model is intentionally explicit:

1. runtime source content is authored in `runtime/`
2. `ops/manifest.json` declares components and profiles
3. platform install maps in `runtime/platforms/*/install-map.json` define where content lands, tagged by component
4. `scripts/sync.sh` resolves the profile, builds a target tree, and deploys it
5. target-scoped install-state files in `.local/install-state/` record what was installed and when
6. doctor and repair scripts check for drift on the selected target

## Sync Workflow

A single sync script handles all platforms. It defaults to the live runtime root and keeps staging as an explicit test target.

```bash
# install claude runtime (uses default profile from install-map)
./scripts/sync.sh --platform claude

# install codex runtime with explicit profile
./scripts/sync.sh --platform codex --profile codex-only

# install to staging for testing
./scripts/sync.sh --platform claude --target staging

# preview what would change without modifying anything
./scripts/sync.sh --platform claude --dry-run
```

Options:

- `--platform <name>` (required): platform to sync, auto-discovered from `runtime/platforms/*/install-map.json`
- `--profile <id>` (optional): profile from `ops/manifest.json`, defaults to the install-map's `defaultProfile`
- `--target live|staging` (optional): defaults to `live`
- `--dry-run` (optional): show what would be installed without making changes

Sync prints a human-readable summary on success, including the active target, target root, applied target count, and backup location when backups were created.

## Local Ops Workflow

The harness has a local operations layer around live and staging installs:

```bash
# show install state for all discovered platforms
./scripts/list-installed.sh

# check whether deployed files match recorded digests
./scripts/doctor.sh

# repair by rerunning sync with recorded profiles
./scripts/repair.sh
```

All three scripts default to `--target live` and also support `--target staging`.

## Running Tests

Tests run in isolated temp directories and never touch your live environment.

```bash
# run all tests
for t in tests/ops/test-sync-*.sh; do echo "--- $t ---"; bash "$t"; done

# run a specific test
bash tests/ops/test-sync-lifecycle.sh
```

Test suites:

| Test | What it covers |
|---|---|
| `test-sync-errors.sh` | Bad platforms, bad profiles, missing components, path validation, duplicate targets |
| `test-sync-dry-run.sh` | Dry-run produces output without side effects |
| `test-sync-lifecycle.sh` | Full live+staging cycle: sync, doctor, drift, repair, backup, state validation |
| `test-sync-content.sh` | File existence, content correctness, no leaked source paths, evolution-front experiment content |

Each test prints `PASS: <name>` on success or `FAIL: <reason>` on failure. A nonzero exit code means failure.

## Evolution-Front Experiment

The repo also contains an opt-in workflow experiment for weak prompts.

- baseline `/plan` remains the default path
- challenger `/evolution-plan` uses an evidence-chain-oriented front half before the same downstream tail
- the experiment is still evidence-driven and not promoted into shared policy

See [docs/evolution-front-experiment.md](docs/evolution-front-experiment.md) for the current method, completed trial matrix, and recommendation.

## Guiding Principle

Use ECC as a reference library of ideas, not as a dependency to mirror wholesale. Every adopted pattern should be understandable and maintainable here.
