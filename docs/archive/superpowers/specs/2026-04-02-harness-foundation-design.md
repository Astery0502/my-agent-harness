# My Agent Harness Foundation Design

**Goal:** define the first foundational milestone for `my-agent-harness` so the repo can grow into a personal Claude Code + Codex harness without inheriting ECC wholesale.

## Scope

This design covers the harness foundation only.

Included:

- repo identity and top-level documentation
- coordination surface directories
- platform split for Claude and Codex
- install metadata
- install-state and drift-tracking scaffolding
- sync, doctor, and repair script contracts
- architecture and decision documentation

Excluded:

- full workflow content in `skills/`, `agents/`, `commands/`, or `rules/`
- hooks and automation
- project starter templates
- ECC compatibility beyond pattern borrowing

## Design Summary

`my-agent-harness` should be organized around three layers:

1. shared source-of-truth content you own
2. platform-specific install targets for Claude and Codex
3. state and scripts that explain what is installed and whether it has drifted

The repo should stay intentionally small. The first milestone is not about shipping sophisticated agent workflows. It is about making future additions safe, understandable, and reversible.

## Architecture

### Shared source layer

These folders express the harness model and should be edited directly:

- `AGENTS.md`
- `agents/`
- `skills/`
- `commands/`
- `rules/`
- `docs/`
- `install/`

This layer captures philosophy, reusable assets, standards, and declarative install metadata.

### Platform layer

These folders define how shared source maps into each runtime:

- `platforms/claude/`
- `platforms/codex/`

Each platform folder should contain only the minimal files needed to express platform-specific supplements, base configuration, and install mapping.

### State and operations layer

These folders track what has been installed and how to operate the harness:

- `scripts/`
- `state/`

This layer makes the repo operational. It should answer:

- what can be installed
- where it gets installed
- what was last installed
- how to detect drift
- how to repair drift

## Design Decisions

### 1. Install-first foundation

The first milestone should include `install/`, `state/`, and `scripts/` immediately rather than adding them later.

Reason:

- it preserves the distinction between source and installed outputs from day one
- it avoids future restructuring when sync logic appears
- it matches the ECC lessons with much less surface area

### 2. Shared philosophy, split runtime targets

The harness should have one shared philosophy file and platform supplements instead of separate duplicated philosophies.

Reason:

- keeps Claude and Codex aligned
- reduces copy-paste drift
- makes platform differences explicit rather than accidental

### 3. Placeholder workflow surfaces are acceptable in v1

`agents/`, `skills/`, `commands/`, and `rules/` should exist even if they initially contain only starter placeholders.

Reason:

- the architecture becomes visible early
- future content can land without directory churn
- documentation can reference stable locations

### 4. No hooks in the first milestone

Hooks should be deferred until the harness foundation is stable.

Reason:

- hooks add enforcement before the repo has enough policy content
- a smaller bootstrap reduces risk and maintenance cost

## Initial Deliverables

The foundation milestone should produce:

- initialized repo layout
- `README.md` with purpose, structure, and install targets
- `AGENTS.md` with shared philosophy
- `docs/architecture.md`
- `docs/decisions/` for ADR-style notes
- starter placeholders in coordination-surface folders
- declarative install metadata in `install/`
- install-state schema plus per-platform state files in `state/`
- script stubs in `scripts/`
- Claude and Codex platform placeholders and install maps

## Risks and Guardrails

### Risk: overdesign before usage

Mitigation:

- keep the foundation small
- add only directories and contracts needed for future growth
- avoid implementing real workflows in this milestone

### Risk: platform drift

Mitigation:

- install maps must be explicit
- state files must be per-platform
- doctor and repair responsibilities must be documented early

### Risk: ECC cargo-culting

Mitigation:

- record each adoption as a local decision in `docs/decisions/`
- treat ECC as reference material, not a dependency

## Validation

The foundation design is successful if:

- a new collaborator can understand the repo structure from docs alone
- Claude and Codex targets are both represented explicitly
- installable components are declared, not implied
- sync and drift concepts exist before content complexity increases
- future workflow additions can fit without reorganizing the repo
