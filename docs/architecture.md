# Harness Architecture

This document explains how `my-agent-harness` is organized and how it should evolve.

## Layer Model

The repository is split into three layers:

1. shared source layer
2. platform layer
3. state and operations layer

## Shared Source Layer

These folders define the durable model of the harness:

- `AGENTS.md`
- `agents/`
- `skills/`
- `commands/`
- `rules/`
- `docs/`
- `install/`

This layer answers:

- what philosophy the harness follows
- which reusable assets exist
- which policies and workflows are expected
- what components are installable

## Platform Layer

These folders adapt the shared model to a specific runtime:

- `platforms/claude/`
- `platforms/codex/`

Each platform folder should stay narrow. It should hold only the base files, supplements, and mapping data that differ by platform.

## State And Operations Layer

These folders make the harness operational:

- `scripts/`
- `state/`

This layer answers:

- what was installed
- where it was installed
- what profile or modules were used
- how drift will be detected and repaired

## Install Flow

The intended install flow is:

1. author shared and platform content in the repository
2. describe installable units in `install/`
3. map repository assets to runtime targets with platform install maps
4. run sync scripts to install or update runtime files
5. record results in per-platform install-state files
6. use doctor and repair scripts to detect drift and restore consistency

## Folder Responsibilities

- `agents/`: specialist roles the harness may expose
- `skills/`: reusable methods and workflows
- `commands/`: entrypoints that coordinate workflows
- `rules/`: policy and quality expectations
- `platforms/`: Claude- and Codex-specific files
- `install/`: declarative install definitions
- `scripts/`: operational entrypoints
- `state/`: install status and drift metadata
- `docs/decisions/`: local architecture decisions

## Deferred Work

The first milestone intentionally defers:

- hooks and runtime enforcement
- project starter templates
- deep workflow implementation
- automatic merge or generation logic

That keeps the repository understandable while still establishing the right long-term boundaries.
