# ADR 0001: Foundation-Only First Milestone

## Status

Accepted

## Context

`my-agent-harness` starts from a blank repository with only planning notes. The main risk is adopting too much ECC structure before there is enough local usage to justify it.

## Decision

Build the first milestone as a harness foundation only.

Include:

- repository structure
- shared documentation
- platform split
- install metadata
- install-state scaffolding
- script contracts

Defer:

- hooks
- automation
- starter templates
- deep workflow implementations

## Rationale

- a smaller foundation is easier to understand and maintain
- install-state and platform boundaries should exist before richer workflows
- placeholders make future expansion possible without forcing premature complexity
- local decisions should be deliberate instead of copying ECC wholesale

## Consequences

- some files will be intentionally skeletal at first
- future milestones can build on stable structure
- the repository stays easy to audit during early adoption
