# My Agent Harness

`my-agent-harness` is a personal harness repo for shaping how AI coding tools behave across Claude Code and Codex.

It borrows useful patterns from ECC, but it does not depend on ECC as a base layer. This repo is the source of truth.

## First Milestone

This first milestone is foundation only.

Included:

- repo structure
- shared philosophy
- platform split
- install metadata
- install-state scaffolding
- sync, doctor, and repair script stubs

Not included yet:

- mature workflow content
- hooks and automation
- project starter templates
- deep platform integration

## Repository Shape

```text
my-agent-harness/
├── AGENTS.md
├── README.md
├── runtime/
├── ops/
├── scripts/
├── docs/
├── tests/
└── .local/                # ignored generated output
```

## Lookup Guide

- `AGENTS.md`: project-local guidance for changing this repo
- `runtime/`: installable shared/runtime source, including `runtime/HARNESS.md`
- `ops/`: tracked install metadata and schemas
- `scripts/`: stable shell entrypoints
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
2. install metadata in `ops/install/` declares what can be synced
3. platform install maps in `runtime/platforms/` define where content lands
4. local install-state files in `.local/install-state/` record what was installed and when
5. doctor and repair scripts check for drift later

## Current Sync Workflow

The real sync path currently stages output locally instead of writing into home-directory runtime targets.

- `./scripts/sync-claude.sh` stages Claude output into `.local/staging/claude/`
- `./scripts/sync-codex.sh` stages Codex output into `.local/staging/codex/`
- both scripts accept an optional `--profile <id>` argument
- each successful run updates the matching file in `.local/install-state/`

This milestone is intentionally staging-first so the install logic can be exercised safely before adding writes into `~/.claude/` or `~/.codex/`.

## Local Ops Workflow

The harness now has a local operations layer around staged installs:

- `./scripts/list-installed.sh` shows the current recorded state for Claude and Codex
- `./scripts/doctor.sh` checks whether staged output still matches the recorded digests
- `./scripts/repair.sh` rebuilds staged output by rerunning sync with the recorded profile

These scripts operate only on local repository state in this milestone. They do not modify `~/.claude` or `~/.codex`.

## Guiding Principle

Use ECC as a reference library of ideas, not as a dependency to mirror wholesale. Every adopted pattern should be understandable and maintainable here.
