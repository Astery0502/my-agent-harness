# AGENTS.md

Codex guidance for working on `my-agent-harness`.

This repository is the source of truth for runtime content that syncs into `~/.claude/` and `~/.codex/`. It is not an ECC fork.

See [CONTEXT.md](CONTEXT.md) for the repository map and where to look. See [PIPELINE.md](PIPELINE.md) for commands and sync workflows.

## Working Rules

- Edit source files in this repository, especially under `runtime/`.
- Do not edit generated `.local/` content or live runtime outputs in `~/.*`.
- Keep docs aligned when changing sync behavior, install behavior, or user-facing commands.
- New platforms should be discovered through `runtime/platforms/*/install-map.json`.
- Tests must use isolated temp directories and must not touch live runtime state.
- In tests, prefer behavior, durable state, semantic structure, and state transitions over brittle raw text or file-existence assertions unless that path or text is the contract.
- Keep changes surgical: do not refactor unrelated code, rewrite adjacent docs, or remove pre-existing dead code unless asked.
