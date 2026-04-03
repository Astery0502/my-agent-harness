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
├── agents/
├── commands/
├── docs/
├── install/
├── platforms/
├── rules/
├── scripts/
├── skills/
└── state/
```

## Runtime Targets

This repo is intended to sync into:

- `~/.claude/`
- `~/.codex/`

The shared source files live in this repository. Platform folders define how shared content maps into each runtime target.

## Install Model

The install model is intentionally explicit:

1. source content is authored in this repo
2. install metadata declares what can be synced
3. platform install maps define where content lands
4. state files record what was installed and when
5. doctor and repair scripts check for drift later

## Current Sync Workflow

The real sync path currently stages output locally instead of writing into home-directory runtime targets.

- `./scripts/sync-claude.sh` stages Claude output into `state/staging/claude/`
- `./scripts/sync-codex.sh` stages Codex output into `state/staging/codex/`
- both scripts accept an optional `--profile <id>` argument
- each successful run updates the matching file in `state/`

This milestone is intentionally staging-first so the install logic can be exercised safely before adding writes into `~/.claude/` or `~/.codex/`.

## Local Ops Workflow

The harness now has a local operations layer around staged installs:

- `./scripts/list-installed.sh` shows the current recorded state for Claude and Codex
- `./scripts/doctor.sh` checks whether staged output still matches the recorded digests
- `./scripts/repair.sh` rebuilds staged output by rerunning sync with the recorded profile

These scripts operate only on local repository state in this milestone. They do not modify `~/.claude` or `~/.codex`.

## Evolution-Front Experiment

The repo also contains an opt-in workflow experiment for weak prompts.

- baseline `/plan` remains the default path
- challenger `/evolution-plan` uses an evidence-chain-oriented front half before the same downstream tail
- the experiment is still evidence-driven and not promoted into shared policy

See [docs/evolution-front-experiment.md](/Users/astery/src/ai/my-agent-harness/.worktrees/codex-evolution-front-v1/docs/evolution-front-experiment.md) for the current method, completed trial matrix, and recommendation.

## Guiding Principle

Use ECC as a reference library of ideas, not as a dependency to mirror wholesale. Every adopted pattern should be understandable and maintainable here.
