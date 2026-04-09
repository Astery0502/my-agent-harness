# Personal Agent Harness Handoff

This document distills a planning conversation into a single Markdown brief that can be shared with a fresh AI workspace to bootstrap a personal Claude Code + Codex configuration repo.

The goal is not to install or fork ECC wholesale. The goal is to build a smaller, personal, manageable repo that borrows ECC's good structural ideas while keeping every tool and workflow under your direct control.

## Main Goal

Build a personal harness repo that:

- supports both Claude Code and Codex equally
- keeps shared logic in one repo you own
- lets you add tools one by one
- stays understandable without inheriting all of ECC
- uses sync scripts and install-state tracking from the beginning

## Final Direction Chosen

The chosen direction is:

- create a new personal harness repo from scratch
- keep ECC nearby only as a reference repo
- include these directories from day one:
  - `agents/`
  - `skills/`
  - `commands/`
  - `rules/`
- support both Claude Code and Codex equally in v1
- keep the repo small, but include sync scripts and drift/install-state tracking early

## Q&A Summary

### Q: What kind of shared things can ECC provide?

A: ECC can provide the shared base:

- common instructions and philosophy
- reusable agents
- reusable skills
- workflow commands/prompts
- rules and policy
- Claude/Codex platform config
- hooks and automation
- install/update machinery

ECC should not own:

- your personal style
- your private secrets
- repo-specific architecture facts
- company-specific workflows

### Q: I do not want to pull ECC wholesale into my repo. I want something similar, but under my control.

A: Treat ECC as a library of patterns, not as a base dependency.

Use ECC to learn:

- layered ownership
- shared vs platform-specific files
- common vs language-specific rules
- sync/update discipline
- install-state and drift checks

But implement your own smaller version in your own repo.

### Q: What does "project starter templates/installers" mean?

A: It means a repo that not only manages your own `~/.claude` and `~/.codex`, but can also stamp a default AI/project structure into new software projects.

Recommendation from the conversation:

- do not start with project templates
- start with a personal harness repo only

### Q: What does "starter pack" mean?

A: It means actual first-version files, not just an architecture description.

Examples:

- `AGENTS.md`
- `HARNESS.md`
- `platforms/codex/config.base.toml`
- `platforms/claude/CLAUDE.base.md`
- `scripts/sync-claude.sh`
- `scripts/sync-codex.sh`
- `scripts/doctor.sh`
- `install/modules.json`
- `install/profiles.json`

### Q: How should the repo be created and modified, with ECC nearby as a reference?

A: Keep two repos side by side:

- `ecc-reference` for reading only
- `my-agent-harness` for editing

Workflow:

1. identify one problem
2. inspect only the relevant ECC files
3. extract the principle
4. implement a smaller version in your own repo
5. test locally
6. document the decision

## Recommended Workspace Layout

Create a fresh workspace like this:

```text
~/src/ai/
├── ecc-reference
└── my-agent-harness
```

Meaning:

- `ecc-reference` is read-only and used for studying patterns
- `my-agent-harness` is your source of truth

## What To Study In ECC First

Read these files in this order:

1. Layering and install model
   - `docs/SELECTIVE-INSTALL-ARCHITECTURE.md`

2. Separation of system parts
   - `docs/COMPONENT-COORDINATION-REFERENCE.md`

3. Rule layering
   - `rules/README.md`

4. Claude/Codex platform split
   - `.codex/config.toml`
   - `.codex/AGENTS.md`
   - `examples/user-CLAUDE.md`

5. Sync/update discipline
   - `scripts/sync-ecc-to-codex.sh`
   - `scripts/doctor.js`
   - `scripts/repair.js`
   - `scripts/lib/install-state.js`

These are the main lessons to learn:

- source vs installed vs runtime state
- policy vs workflow vs role vs method
- common rules plus language overrides
- shared base plus platform supplements
- sync scripts that preserve user-owned data
- install-state and drift checks

Do not try to learn all of ECC at once.

## Repo To Build

Create this structure in `my-agent-harness`:

```text
my-agent-harness/
├── README.md
├── AGENTS.md
├── HARNESS.md
├── docs/
│   ├── architecture.md
│   └── decisions/
├── agents/
│   ├── planner.md
│   ├── reviewer.md
│   └── debugger.md
├── skills/
│   ├── tdd-workflow/
│   │   └── SKILL.md
│   ├── verification-loop/
│   │   └── SKILL.md
│   └── research-first/
│       └── SKILL.md
├── commands/
│   ├── plan.md
│   ├── review.md
│   └── verify.md
├── rules/
│   ├── common/
│   │   ├── coding-style.md
│   │   ├── testing.md
│   │   └── security.md
│   ├── typescript/
│   │   ├── coding-style.md
│   │   └── testing.md
│   └── python/
│       ├── coding-style.md
│       └── testing.md
├── platforms/
│   ├── claude/
│   │   ├── CLAUDE.base.md
│   │   └── install-map.json
│   └── codex/
│       ├── AGENTS.supplement.md
│       ├── config.base.toml
│       ├── agents/
│       │   ├── explorer.toml
│       │   └── reviewer.toml
│       └── install-map.json
├── install/
│   ├── profiles.json
│   ├── modules.json
│   └── components.json
├── scripts/
│   ├── sync-claude.sh
│   ├── sync-codex.sh
│   ├── list-installed.sh
│   ├── doctor.sh
│   └── repair.sh
└── state/
    ├── claude-install-state.json
    ├── codex-install-state.json
    └── install-state.schema.json
```

## Folder Responsibilities

- `AGENTS.md`
  Project-local guidance for working on the harness repo itself.

- `HARNESS.md`
  Shared installable baseline for Claude Code, Codex, and future runtimes.

- `agents/`
  Reusable specialist roles.

- `skills/`
  Reusable long-form methods.

- `commands/`
  Reusable workflow prompts and entry points.

- `rules/`
  Policy and standards.

- `platforms/claude/`
  Claude-specific generated or merged outputs.

- `platforms/codex/`
  Codex-specific generated or merged outputs.

- `install/`
  Declarative install and module selection.

- `scripts/`
  Sync, doctor, and repair scripts.

- `state/`
  Install-state and drift metadata.

## Runtime Targets

This repo should sync into:

```text
~/.claude/
~/.codex/
```

### Claude runtime target

Expected installed shape:

```text
~/.claude/
├── CLAUDE.md
├── agents/
├── commands/
├── skills/
└── rules/
```

### Codex runtime target

Expected installed shape:

```text
~/.codex/
├── AGENTS.md
├── config.toml
├── prompts/
└── agents/
```

## Sync Model

### `sync-claude.sh`

Should:

- create `~/.claude` if needed
- copy `agents/`, `commands/`, `skills/`, and `rules/`
- generate `~/.claude/CLAUDE.md` from:
  - repo `HARNESS.md`
  - `platforms/claude/CLAUDE.base.md`
- write `state/claude-install-state.json`

### `sync-codex.sh`

Should:

- create `~/.codex` if needed
- generate `~/.codex/AGENTS.md` from:
  - repo `HARNESS.md`
  - `platforms/codex/AGENTS.supplement.md`
- copy `platforms/codex/config.base.toml` to `~/.codex/config.toml`
- generate prompt files from `commands/*.md` into `~/.codex/prompts/`
- write `state/codex-install-state.json`

## Minimal v1 Modules

Start with only these modules:

- `core-instructions`
- `agents-core`
- `skills-core`
- `commands-core`
- `rules-core`
- `platform-configs`

Suggested `install/modules.json`:

```json
{
  "modules": {
    "core-instructions": ["AGENTS.md"],
    "agents-core": ["agents"],
    "skills-core": ["skills"],
    "commands-core": ["commands"],
    "rules-core": ["rules"],
    "platform-configs": ["platforms"]
  }
}
```

Suggested `install/profiles.json`:

```json
{
  "profiles": {
    "core": [
      "core-instructions",
      "agents-core",
      "skills-core",
      "commands-core",
      "rules-core",
      "platform-configs"
    ]
  }
}
```

## Recommended v1 Content

### Agents

- `planner.md`
- `reviewer.md`
- `debugger.md`

### Skills

- `tdd-workflow`
- `verification-loop`
- `research-first`

### Commands

- `plan`
- `review`
- `verify`

### Common rules

- `coding-style.md`
- `testing.md`
- `security.md`

### Platform files

- `platforms/claude/CLAUDE.base.md`
- `platforms/codex/AGENTS.supplement.md`
- `platforms/codex/config.base.toml`
- `platforms/codex/agents/explorer.toml`
- `platforms/codex/agents/reviewer.toml`

## Install-State Tracking

Track installs from v1 onward.

Each target state file should record:

- target name
- profile
- install timestamp
- list of copied/generated files
- simple file hash

Example shape:

```json
{
  "target": "codex",
  "profile": "core",
  "installedAt": "2026-04-02T12:00:00Z",
  "modules": [
    "core-instructions",
    "agents-core",
    "skills-core",
    "commands-core",
    "rules-core",
    "platform-configs"
  ],
  "files": [
    {
      "source": "platforms/codex/config.base.toml",
      "destination": "~/.codex/config.toml",
      "hash": "..."
    }
  ]
}
```

## Script Build Order

Build scripts in this order:

1. `sync-claude.sh`
2. `sync-codex.sh`
3. `doctor.sh`
4. `list-installed.sh`
5. `repair.sh`

Important guidance:

- write `doctor.sh` before `repair.sh`
- verify drift detection first
- only add repair once state and doctor are trustworthy

## Ownership Rules

Edit only the source files in `my-agent-harness`.

Do not casually hand-edit:

- generated prompt files in `~/.codex/prompts/`
- generated runtime outputs in `~/.claude/` or `~/.codex/`
- install-state files except for debugging

Keep these boundaries:

- personal repo owns the source
- sync scripts own generated outputs
- runtime folders are deployment targets
- project-specific facts belong in each project repo, not here

## What To Copy From ECC vs What Not To Copy

### Copy these ideas

- shared base plus platform supplement
- common plus language-specific rules
- sync/update scripts
- install-state tracking
- doctor/repair lifecycle
- commands as reusable workflows
- separate layers for agents, skills, commands, and rules

### Do not copy yet

- large hook system
- heavy MCP integration
- continuous learning loops
- complex orchestration runtime
- many profiles and many modules
- project starter templates

## Recommended Weekly Workflow

1. keep ECC updated nearby
2. when you notice a useful pattern, open a small issue in your own repo
3. implement one pattern at a time
4. test against a temp home first
5. document the decision briefly
6. commit

Suggested decision-note filenames:

- `docs/decisions/2026-04-02-rule-layering.md`
- `docs/decisions/2026-04-02-codex-prompt-generation.md`
- `docs/decisions/2026-04-03-install-state.md`

## First Week Plan

### Day 1

- create repo
- add `README.md`
- add `docs/architecture.md`
- add `AGENTS.md`
- add `HARNESS.md`

### Day 2

- add `rules/common/`
- add Claude and Codex base platform files

### Day 3

- add `sync-claude.sh`
- add `sync-codex.sh`

### Day 4

- add `planner`, `reviewer`, and `debugger`
- add 3 basic skills

### Day 5

- add `plan`, `review`, and `verify`
- generate Codex prompts from commands

### Day 6

- add install-state files
- add `doctor.sh`

### Day 7

- test on your machine
- clean naming and docs
- write 2-3 short decision notes

## Safe Testing Advice

Do not test the first script versions directly against your real home directory.

Use a temp target first, for example:

```bash
export TEST_HOME="$PWD/.tmp-home"
mkdir -p "$TEST_HOME"
```

Then make sync scripts support a custom target root during testing.

That keeps experimentation safe and reversible.

## Final Summary

The intended model is:

- ECC is a nearby reference repo
- your own repo is the only source of truth
- both Claude Code and Codex are first-class targets
- v1 stays small, explicit, and understandable
- every new capability gets added intentionally, one by one

If this document is handed to a fresh AI workspace, the next good task is:

1. create `my-agent-harness`
2. scaffold the directory tree above
3. write the first core files:
   - `README.md`
   - `docs/architecture.md`
   - `AGENTS.md`
   - `HARNESS.md`
   - `platforms/claude/CLAUDE.base.md`
   - `platforms/codex/AGENTS.supplement.md`
   - `platforms/codex/config.base.toml`
4. then implement `sync-claude.sh` and `sync-codex.sh`
