# CLAUDE.md

Personal harness repo that syncs runtime content (agents, skills, commands, rules) into `~/.claude/` and `~/.codex/`. Source of truth for how AI coding tools behave. Not an ECC fork.

See [CONTEXT.md](CONTEXT.md) for the repository map and where to look. See [PIPELINE.md](PIPELINE.md) for commands and sync workflows.

## Working rules

- Edit source in `runtime/`, never in `.local/` or `~/.*` outputs
- Keep docs aligned when changing sync behavior
- New platforms auto-discover from `runtime/platforms/*/install-map.json`
- Tests run in isolated temp dirs; never touch live environment
- In `tests/`, avoid brittle explicit file-exists or raw text-exists assertions unless that path or text is the stable contract; prefer behavior, durable state, semantic structure, or state-transition assertions
