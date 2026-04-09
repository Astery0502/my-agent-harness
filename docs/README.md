# Docs Index

Use this folder for active lookup first, archive second.

## Active Docs

- `architecture.md`: current repository structure and ownership boundaries
- `reference/component-coordination.md`: how runtime surfaces and ops surfaces fit together
- `evolution-front-experiment.md`: current write-up for the opt-in evolution-front workflow experiment
- `decisions/`: accepted architecture decisions

## Archive

Historical planning notes, specs, and exploratory writeups live under `archive/`.
They are kept for context, but they are not the source of truth for the current
repo layout.

## Local Output

Generated install state and staged runtime output do not live in `docs/`. They
live in ignored `.local/` paths:

- `.local/install-state/`
- `.local/staging/`
