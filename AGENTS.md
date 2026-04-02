# My Agent Harness Guidance

This repository defines a shared harness philosophy for both Claude Code and Codex.

## Core Position

- this repo is the source of truth
- ECC is a reference, not a dependency
- shared philosophy belongs here once, not duplicated per platform
- platform supplements should adapt runtime behavior without replacing the shared base

## Ownership Boundaries

- `AGENTS.md`, `agents/`, `skills/`, `commands/`, `rules/`, and `install/` define shared source content
- `platforms/claude/` and `platforms/codex/` define platform-specific adaptations
- `scripts/` and `state/` define operational behavior and installation status

## Expectations

- prefer small, understandable building blocks
- add capabilities incrementally
- document why a new pattern exists before expanding it
- preserve user-owned runtime data during future sync work

## Early Milestone Constraint

The first milestone is only for repository foundation. Do not treat placeholder files as fully implemented workflows.
