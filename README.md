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

## Checking for Skill Updates

### External Skills (`ops/external-skills.json`)

Skills listed in `ops/external-skills.json` are fetched from GitHub into `.local/external/` at sync time. To check whether any of them have updates available upstream:

```bash
./scripts/check-external-skills-update.sh
```

The script compares each skill's local cache state to its remote ref. Branch-tracked skills (e.g. `"ref": "main"`) report `up-to-date` or `update available` by comparing commit hashes. Release-pinned skills compare local and latest release tags. Run `sync.sh` to pull in any available updates.

### NotebookLM Skill

The NotebookLM skill is kept as harness-owned runtime content at `runtime/skills/notebooklm/SKILL.md`. It is not listed in `ops/external-skills.json`, so normal syncs and tests do not clone the full upstream `notebooklm-py` repository just to deploy the skill.

The skill file records the upstream package version in an HTML comment near the top. To check whether PyPI has a newer package release:

```bash
./scripts/check-notebooklm-skill-update.sh
```

When an update is available, install the new `notebooklm-py` release, run `notebooklm skill install`, then copy the generated `SKILL.md` back into `runtime/skills/notebooklm/SKILL.md` so the harness remains the source of truth.

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

The repo previously carried a planning-command comparison surface. That baseline has been removed; no planning command is installed from this harness.

The remaining opt-in workflow experiment is `/evolution-plan` when its runtime files are present. The experiment is still evidence-driven and not promoted into shared policy.

See [docs/evolution-front-experiment.md](docs/evolution-front-experiment.md) for the current method, completed trial matrix, and recommendation.

## Guiding Principle

Use ECC as a reference library of ideas, not as a dependency to mirror wholesale. Every adopted pattern should be understandable and maintainable here.
