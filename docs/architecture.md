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

- `ops/install/`
- `ops/schema/`
- `scripts/`

Ignored generated local output lives in:

- `.local/install-state/`
- `.local/staging/`

This layer answers:

- what can be installed
- how install state is shaped
- how sync, doctor, repair, and listing operate
- where mutable local output is stored

## Install Flow

The intended install flow is:

1. author shared and platform content in `runtime/`
2. describe installable units in `ops/install/`
3. map repository assets to runtime targets with `runtime/platforms/*/install-map.json`
4. run sync scripts to install or update runtime files
5. record results in `.local/install-state/*.json`
6. use doctor and repair scripts to detect drift and restore consistency

## Folder Responsibilities

- `runtime/agents/`: specialist roles the harness may expose
- `runtime/skills/`: reusable methods and workflows
- `runtime/commands/`: entrypoints that coordinate workflows
- `runtime/rules/`: policy and quality expectations
- `runtime/platforms/`: Claude- and Codex-specific runtime files
- `ops/install/`: declarative install definitions
- `ops/schema/`: tracked JSON schema and other static ops contracts
- `scripts/`: operational entrypoints
- `.local/`: ignored install status and staged runtime output
- `docs/reference/`: evergreen lookup docs
- `docs/archive/`: historical plans and exploratory notes
- `docs/decisions/`: local architecture decisions

## Deferred Work

The first milestone intentionally defers:

- hooks and runtime enforcement
- project starter templates
- deep workflow implementation
- automatic merge or generation logic

That keeps the repository understandable while still establishing the right long-term boundaries.
