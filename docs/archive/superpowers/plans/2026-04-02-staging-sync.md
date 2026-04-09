# Staging Sync Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** implement a real staging-based sync pipeline for Claude and Codex that resolves install metadata, stages mapped files locally, and records install state without touching home-directory targets.

**Architecture:** thin platform wrappers call one shared sync engine. The engine resolves profiles into modules, modules into components, components into allowed source paths, applies the platform install map, rebuilds a local staging tree, computes digests, and updates per-platform install-state files.

**Tech Stack:** Bash, `jq`, JSON metadata, filesystem staging, shell-based integration verification

---

## File Structure

### Files to create

- `scripts/lib/sync-common.sh`
- `tests/test-staging-sync.sh`

### Files to modify

- `scripts/sync-claude.sh`
- `scripts/sync-codex.sh`
- `README.md`

### Files to verify through execution

- `install/components.json`
- `install/modules.json`
- `install/profiles.json`
- `platforms/claude/install-map.json`
- `platforms/codex/install-map.json`
- `state/claude-install-state.json`
- `state/codex-install-state.json`

## Task 1: Add failing staging-sync integration tests

**Files:**
- Create: `tests/test-staging-sync.sh`
- Test: integration test fails before implementation

- [ ] **Step 1: Write a shell integration test harness**

Cover:

- Claude sync with default profile
- Codex sync with explicit profile
- creation of `state/staging/<platform>/`
- install-state updates
- stale-file cleanup on rerun

- [ ] **Step 2: Run the test harness to verify failure**

Run: `bash tests/test-staging-sync.sh`
Expected: FAIL because the sync scripts are still stubs and do not stage files or update state

- [ ] **Step 3: Commit**

```bash
git add tests/test-staging-sync.sh
git commit -m "test: add failing staging sync integration coverage"
```

## Task 2: Implement the shared sync engine

**Files:**
- Create: `scripts/lib/sync-common.sh`
- Test: integration test progresses from failure to partial success as behaviors land

- [ ] **Step 1: Add shared argument and path helpers**

Implement helpers for:

- repository root discovery
- path validation
- staging directory setup
- error reporting

- [ ] **Step 2: Add metadata resolution helpers**

Implement helpers that:

- resolve a profile into modules
- resolve modules into components
- resolve components into allowed source paths

- [ ] **Step 3: Add install-map application logic**

Implement logic to:

- read the platform install map
- validate each mapping source
- ensure the source is allowed by the resolved component set
- detect target collisions

- [ ] **Step 4: Add staging write logic**

Implement logic to:

- rebuild `state/staging/<platform>/`
- copy files and directories to mapped targets
- preserve relative content layout beneath each mapped target

- [ ] **Step 5: Add digest and state update logic**

Implement logic to:

- compute digests from staged output
- update the matching platform install-state JSON
- write installed timestamp, profile, modules, target root, and status

- [ ] **Step 6: Run integration test**

Run: `bash tests/test-staging-sync.sh`
Expected: either PASS or fail with only wrapper-related issues left

- [ ] **Step 7: Commit**

```bash
git add scripts/lib/sync-common.sh
git commit -m "feat: add shared staging sync engine"
```

## Task 3: Convert wrapper scripts to real entrypoints

**Files:**
- Modify: `scripts/sync-claude.sh`
- Modify: `scripts/sync-codex.sh`
- Test: wrappers support help text and real sync execution

- [ ] **Step 1: Update wrapper argument parsing**

Support:

- `--help`
- optional `--profile <id>`

- [ ] **Step 2: Call the shared sync engine**

Claude wrapper should pass:

- platform `claude`
- install map `platforms/claude/install-map.json`
- state file `state/claude-install-state.json`
- staging root `state/staging/claude`

Codex wrapper should pass:

- platform `codex`
- install map `platforms/codex/install-map.json`
- state file `state/codex-install-state.json`
- staging root `state/staging/codex`

- [ ] **Step 3: Update help text to reflect staging behavior**

Describe local staging instead of home-directory sync.

- [ ] **Step 4: Re-run wrapper smoke tests**

Run:

```bash
./scripts/sync-claude.sh --help
./scripts/sync-codex.sh --help
```

Expected: both commands exit successfully and describe the real staging-based workflow

- [ ] **Step 5: Commit**

```bash
git add scripts/sync-claude.sh scripts/sync-codex.sh
git commit -m "feat: wire staging sync entrypoints"
```

## Task 4: Validate end-to-end staging behavior

**Files:**
- Review: `state/staging/`
- Review: `state/claude-install-state.json`
- Review: `state/codex-install-state.json`
- Modify: `README.md`

- [ ] **Step 1: Run the full integration test**

Run: `bash tests/test-staging-sync.sh`
Expected: PASS

- [ ] **Step 2: Manually inspect staged output**

Run:

```bash
find state/staging -maxdepth 4 | sort
```

Expected: Claude and Codex staging trees contain the mapped files and directories

- [ ] **Step 3: Validate state files**

Run:

```bash
jq . state/claude-install-state.json state/codex-install-state.json >/dev/null
```

Expected: exit code 0 and values reflect installed staging state

- [ ] **Step 4: Update `README.md`**

Document:

- that sync currently stages locally
- how to run each wrapper
- where staged output is written

- [ ] **Step 5: Re-run the integration test after README update**

Run: `bash tests/test-staging-sync.sh`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add README.md state/claude-install-state.json state/codex-install-state.json
git commit -m "docs: document staging sync workflow"
```

## Task 5: Final verification

**Files:**
- Review: repository-wide staging sync changes

- [ ] **Step 1: Run final help and integration checks**

Run:

```bash
./scripts/sync-claude.sh --help
./scripts/sync-codex.sh --help
bash tests/test-staging-sync.sh
```

Expected: all commands exit successfully

- [ ] **Step 2: Run final JSON validation**

Run:

```bash
jq . install/components.json install/modules.json install/profiles.json \
  platforms/claude/install-map.json platforms/codex/install-map.json \
  state/install-state.schema.json state/claude-install-state.json state/codex-install-state.json >/dev/null
```

Expected: exit code 0

- [ ] **Step 3: Confirm clean working tree**

Run: `git status --short`
Expected: no unstaged surprises before completion handling

- [ ] **Step 4: Commit**

```bash
git add .
git commit -m "test: finalize staging sync verification"
```

## Execution Notes

- keep all writes inside the repository for this milestone
- prefer one shared sync implementation instead of platform duplication
- fail fast on ambiguous mappings and invalid metadata
- do not add runtime home-directory writes yet
