# Local Ops Design

**Goal:** implement the next harness operations milestone by adding real `list-installed.sh`, `doctor.sh`, and `repair.sh` behavior for local staged installs, without writing into `~/.claude` or `~/.codex`.

## Scope

This design covers local operations on staged installs only.

Included:

- a shared ops helper library under `scripts/lib/`
- human-readable listing of current install state
- local diagnostics for staged installs and recorded digests
- safe repair by rerunning staging sync with recorded profiles
- verification for good state, drifted state, and repaired state

Excluded:

- direct sync into home-directory runtime targets
- repair of user-owned runtime files outside the repo
- non-local drift detection against `~/.claude` or `~/.codex`
- replacing placeholder harness content under `agents/`, `skills/`, `commands/`, or `rules/`

## Chosen Direction

Use a shared ops library with three thin entrypoint scripts.

The shared library should own state loading, safety checks, digest verification, and common formatting. The three top-level scripts should remain small and focused:

- `list-installed.sh` lists current state
- `doctor.sh` diagnoses local staged state
- `repair.sh` restores local staged state by rerunning sync

## Alternatives Considered

### 1. Script-by-script implementation

This would be straightforward at first, but it would duplicate state reading and digest logic.

Why rejected:

- duplication would make output and validation drift over time
- future changes to install-state structure would require touching three scripts

### 2. Doctor-first engine with wrappers

This would centralize diagnostics, then layer listing and repair around that logic.

Why rejected for now:

- listing and repair have different responsibilities and user-facing output
- forcing both to behave like doctor would make the scripts harder to understand

## Architecture

### Entry points

- `scripts/list-installed.sh`
- `scripts/doctor.sh`
- `scripts/repair.sh`

These remain the user-facing commands.

### Shared ops library

Add a shared helper under `scripts/lib/` that provides:

- command checks
- repo-root detection
- state-file loading
- target-root safety validation
- staged digest recomputation
- comparison of recorded vs actual component digests

### Existing dependency

The ops layer should reuse the current sync entrypoints:

- `scripts/sync-claude.sh`
- `scripts/sync-codex.sh`

`repair.sh` should call those scripts instead of reimplementing staging behavior.

## Data Flow

### 1. Listing install state

`list-installed.sh` should:

- read `state/claude-install-state.json`
- read `state/codex-install-state.json`
- print platform, status, profile, modules, target root, and installed timestamp

It should produce output even when a platform is `not-installed`.

### 2. Diagnosing local staged state

`doctor.sh` should:

- parse both state files
- validate required fields exist
- handle each platform independently

Behavior by status:

- `not-installed`
  - report cleanly that no staged install is present
  - skip digest checks
- `installed`
  - verify `targetRoot` exists
  - verify `targetRoot` stays inside the repository
  - recompute component digests from the staged tree
  - compare recomputed digests to recorded `componentDigests`
  - report `ok` or `drifted`
- malformed or unsafe state
  - report failure clearly

Exit behavior:

- exit `0` if all installed platforms are healthy and all non-installed platforms are valid
- exit non-zero if any installed platform is drifted or if any state is malformed or unsafe

### 3. Repairing local staged state

`repair.sh` should:

- read both state files
- for each platform with `status == "installed"`, rerun the matching sync script with the recorded profile
- for `not-installed`, report that nothing is staged yet

Important:

- `repair.sh` should not write JSON directly
- it should let the sync scripts rebuild staging and update state files

## Safety Rules

- do not write to `~/.claude` or `~/.codex`
- only operate on target roots that resolve inside the repository
- if a state file points outside the repo, `doctor.sh` must fail and `repair.sh` must refuse to act
- `doctor.sh` reports only; it does not auto-fix
- `repair.sh` must reuse sync scripts instead of duplicating sync logic

## Verification Plan

Verification should prove the full local ops lifecycle.

Required checks:

- listing works before any local staged install
- after a successful sync, `doctor.sh` reports healthy state
- after staged-file tampering, `doctor.sh` reports drift and exits non-zero
- `repair.sh` reruns sync and restores healthy staged state
- state files remain valid JSON after repair

## Risks And Guardrails

### Risk: operating on unsafe paths

Guardrail:

- validate every recorded target root resolves inside the repository before diagnostics or repair

### Risk: drift logic diverges from sync logic

Guardrail:

- reuse digest and path logic in a shared helper
- reuse sync entrypoints for repair

### Risk: hidden silent fixes

Guardrail:

- keep doctor read-only
- make repair explicit and user-invoked

## Success Criteria

The design is successful if:

- the harness can show current local install state clearly
- it can detect staged drift reliably
- it can repair staged drift safely
- all behavior stays inside the repository
- the ops layer strengthens the foundation without depending on full runtime installs yet
