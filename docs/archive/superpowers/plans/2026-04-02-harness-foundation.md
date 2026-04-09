# Harness Foundation Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** bootstrap `my-agent-harness` as a clean, install-aware foundation for a personal Claude Code + Codex harness.

**Architecture:** the repo is split into shared source content, platform-specific targets, and operational install-state tooling. The first milestone creates structure, contracts, and documentation first, while intentionally deferring advanced workflow content and hooks.

**Tech Stack:** Markdown, JSON, shell scripts, repository documentation

---

## File Structure

### Files to create

- `README.md`
- `AGENTS.md`
- `docs/architecture.md`
- `docs/decisions/0001-harness-scope.md`
- `agents/planner.md`
- `agents/reviewer.md`
- `agents/debugger.md`
- `skills/tdd-workflow/SKILL.md`
- `skills/verification-loop/SKILL.md`
- `skills/research-first/SKILL.md`
- `commands/plan.md`
- `commands/review.md`
- `commands/verify.md`
- `rules/common/coding-style.md`
- `rules/common/testing.md`
- `rules/common/security.md`
- `rules/typescript/coding-style.md`
- `rules/typescript/testing.md`
- `rules/python/coding-style.md`
- `rules/python/testing.md`
- `platforms/claude/CLAUDE.base.md`
- `platforms/claude/install-map.json`
- `platforms/codex/AGENTS.supplement.md`
- `platforms/codex/config.base.toml`
- `platforms/codex/agents/explorer.toml`
- `platforms/codex/agents/reviewer.toml`
- `platforms/codex/install-map.json`
- `install/components.json`
- `install/modules.json`
- `install/profiles.json`
- `scripts/sync-claude.sh`
- `scripts/sync-codex.sh`
- `scripts/list-installed.sh`
- `scripts/doctor.sh`
- `scripts/repair.sh`
- `state/install-state.schema.json`
- `state/claude-install-state.json`
- `state/codex-install-state.json`

### Files already present and relevant

- `docs/claude-codex-setup-benefits.md`
- `docs/personal-agent-harness-handoff.md`
- `docs/COMPONENT-COORDINATION-REFERENCE.md`

### Milestone outcome

At the end of this plan, the repo should be structurally complete as a harness foundation, even if many content files still contain lightweight starter material.

### Task 1: Initialize the repository shell

**Files:**
- Create: `README.md`
- Create: `AGENTS.md`
- Test: repository root structure exists and is documented

- [ ] **Step 1: Create the top-level directory structure**

Create:

```text
docs/decisions/
agents/
skills/tdd-workflow/
skills/verification-loop/
skills/research-first/
commands/
rules/common/
rules/typescript/
rules/python/
platforms/claude/
platforms/codex/agents/
install/
scripts/
state/
```

- [ ] **Step 2: Write the root README**

Include:

- repo purpose
- non-goals for the first milestone
- top-level tree
- Claude and Codex target directories
- brief explanation of sync/install-state model

- [ ] **Step 3: Write the shared `AGENTS.md`**

Include:

- shared philosophy across both harnesses
- “ECC as reference, not dependency”
- structure ownership rules
- expectation that platform supplements add, not replace, the shared base

- [ ] **Step 4: Sanity-check the visible structure**

Run: `find . -maxdepth 3 | sort`
Expected: top-level folders and starter files are present in the intended locations

- [ ] **Step 5: Commit**

```bash
git add README.md AGENTS.md
git commit -m "chore: bootstrap harness repository shell"
```

### Task 2: Document architecture and decisions

**Files:**
- Create: `docs/architecture.md`
- Create: `docs/decisions/0001-harness-scope.md`
- Test: docs clearly explain source, platform, and state separation

- [ ] **Step 1: Write `docs/architecture.md`**

Cover:

- repository layers
- folder responsibilities
- install flow from source to runtime targets
- what is intentionally deferred

- [ ] **Step 2: Write the first decision record**

`docs/decisions/0001-harness-scope.md` should explain why the first milestone is foundation-only and why hooks/templates are postponed.

- [ ] **Step 3: Verify architectural consistency**

Review the architecture doc against the three existing docs and confirm the repo language matches the chosen direction.

- [ ] **Step 4: Commit**

```bash
git add docs/architecture.md docs/decisions/0001-harness-scope.md
git commit -m "docs: define harness architecture and scope"
```

### Task 3: Create placeholder coordination surfaces

**Files:**
- Create: `agents/planner.md`
- Create: `agents/reviewer.md`
- Create: `agents/debugger.md`
- Create: `skills/tdd-workflow/SKILL.md`
- Create: `skills/verification-loop/SKILL.md`
- Create: `skills/research-first/SKILL.md`
- Create: `commands/plan.md`
- Create: `commands/review.md`
- Create: `commands/verify.md`
- Create: `rules/common/coding-style.md`
- Create: `rules/common/testing.md`
- Create: `rules/common/security.md`
- Create: `rules/typescript/coding-style.md`
- Create: `rules/typescript/testing.md`
- Create: `rules/python/coding-style.md`
- Create: `rules/python/testing.md`
- Test: each file states responsibility and future intended content

- [ ] **Step 1: Add starter files for `agents/`**

Each file should contain:

- purpose
- when to use it
- what it should eventually own

- [ ] **Step 2: Add starter files for `skills/`**

Each skill should contain:

- short description
- inputs and outputs
- placeholder workflow headings

- [ ] **Step 3: Add starter files for `commands/`**

Each command file should explain:

- entrypoint role
- which agents or skills it will coordinate later

- [ ] **Step 4: Add starter rules**

Common rules should define broad policy categories.
Language-specific rules should note where future overrides belong.

- [ ] **Step 5: Review for boundary clarity**

Expected: commands coordinate, agents execute, skills teach method, rules define policy.

- [ ] **Step 6: Commit**

```bash
git add agents skills commands rules
git commit -m "chore: add harness coordination surface placeholders"
```

### Task 4: Define platform targets

**Files:**
- Create: `platforms/claude/CLAUDE.base.md`
- Create: `platforms/claude/install-map.json`
- Create: `platforms/codex/AGENTS.supplement.md`
- Create: `platforms/codex/config.base.toml`
- Create: `platforms/codex/agents/explorer.toml`
- Create: `platforms/codex/agents/reviewer.toml`
- Create: `platforms/codex/install-map.json`
- Test: Claude and Codex platform responsibilities are explicit and non-overlapping

- [ ] **Step 1: Add Claude base placeholders**

`CLAUDE.base.md` should contain only platform-specific supplement concepts, not duplicated shared philosophy.

- [ ] **Step 2: Add Codex base placeholders**

`AGENTS.supplement.md`, `config.base.toml`, and agent TOMLs should define the future Codex-specific surface area.

- [ ] **Step 3: Write install maps**

Each install map should specify how shared assets and platform assets will flow into `~/.claude/` or `~/.codex/`.

- [ ] **Step 4: Review for portability**

Expected: shared logic stays in root-owned files; platform files only adapt runtime behavior.

- [ ] **Step 5: Commit**

```bash
git add platforms
git commit -m "chore: define claude and codex platform targets"
```

### Task 5: Define install metadata and state

**Files:**
- Create: `install/components.json`
- Create: `install/modules.json`
- Create: `install/profiles.json`
- Create: `state/install-state.schema.json`
- Create: `state/claude-install-state.json`
- Create: `state/codex-install-state.json`
- Test: install metadata is internally consistent and state files validate the model shape

- [ ] **Step 1: Define installable components**

`install/components.json` should enumerate discrete assets or asset groups, such as root docs, rules, skills, platform bases, and scripts.

- [ ] **Step 2: Define modules**

`install/modules.json` should group components into meaningful install bundles.

- [ ] **Step 3: Define profiles**

`install/profiles.json` should describe practical installs such as `minimal`, `claude-only`, `codex-only`, and `full`.

- [ ] **Step 4: Add install-state schema**

Include fields such as:

- platform
- installedAt
- profile
- modules
- componentDigests
- targetRoot
- status

- [ ] **Step 5: Add starter state files**

Initialize `claude-install-state.json` and `codex-install-state.json` with empty or not-installed values that match the schema.

- [ ] **Step 6: Validate JSON formatting**

Run: `jq . install/components.json install/modules.json install/profiles.json state/install-state.schema.json state/claude-install-state.json state/codex-install-state.json`
Expected: all files parse successfully

- [ ] **Step 7: Commit**

```bash
git add install state
git commit -m "chore: add install metadata and state scaffolding"
```

### Task 6: Define operations scripts

**Files:**
- Create: `scripts/sync-claude.sh`
- Create: `scripts/sync-codex.sh`
- Create: `scripts/list-installed.sh`
- Create: `scripts/doctor.sh`
- Create: `scripts/repair.sh`
- Test: each script has executable structure, usage help, and a non-destructive stub behavior

- [ ] **Step 1: Add sync script stubs**

Each sync script should:

- declare target runtime path
- declare the metadata files it depends on
- print planned actions without destructive behavior yet

- [ ] **Step 2: Add inventory and health stubs**

`list-installed.sh` should describe how installed modules will be displayed.
`doctor.sh` should describe planned drift and consistency checks.
`repair.sh` should describe safe repair boundaries.

- [ ] **Step 3: Make scripts executable**

Run: `chmod +x scripts/*.sh`
Expected: all shell scripts become runnable

- [ ] **Step 4: Run script help smoke tests**

Run:

```bash
./scripts/sync-claude.sh --help
./scripts/sync-codex.sh --help
./scripts/list-installed.sh --help
./scripts/doctor.sh --help
./scripts/repair.sh --help
```

Expected: each script prints usage text and exits successfully

- [ ] **Step 5: Commit**

```bash
git add scripts
git commit -m "chore: add harness operations script stubs"
```

### Task 7: Final foundation verification

**Files:**
- Review: repository-wide
- Test: structure, docs, JSON validity, and script smoke tests

- [ ] **Step 1: Run a final structure check**

Run: `find . -maxdepth 4 | sort`
Expected: the repo matches the planned foundation layout

- [ ] **Step 2: Re-run JSON validation**

Run: `jq . install/components.json install/modules.json install/profiles.json state/install-state.schema.json state/claude-install-state.json state/codex-install-state.json >/dev/null`
Expected: exit code 0

- [ ] **Step 3: Re-run script smoke tests**

Run the `--help` checks again for all scripts.
Expected: exit code 0 for every script

- [ ] **Step 4: Review docs for consistency**

Check that `README.md`, `AGENTS.md`, `docs/architecture.md`, and the existing notes tell the same story about:

- personal ownership
- ECC as reference
- dual-platform support
- install-first foundation

- [ ] **Step 5: Commit**

```bash
git add .
git commit -m "docs: finalize harness foundation plan baseline"
```

## Execution Notes

- Initialize git before the first commit if the repository is not yet a git repo.
- Keep this milestone intentionally thin; do not fill placeholder files with heavyweight workflow logic yet.
- Record any deviations from the current design in `docs/decisions/`.
- If advanced workflow content starts appearing, stop and split that into a second milestone.
