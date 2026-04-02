# Staging Sync Design

**Goal:** implement the first real sync pipeline for `my-agent-harness` by staging resolved Claude and Codex installs into local directories instead of writing directly to home-directory runtime targets.

## Scope

This design covers the first operational sync pass only.

Included:

- a shared sync engine
- per-platform wrapper scripts
- profile resolution from install metadata
- install-map-driven staging
- per-platform staging directories under `state/`
- install-state updates after successful sync
- verification for repeatable staged outputs

Excluded:

- writing into `~/.claude/` or `~/.codex/`
- drift detection against user runtime directories
- repair logic beyond future contracts
- manifest generation as a separate step
- merge behavior for conflicting mapped targets

## Chosen Direction

Use a shared sync engine with thin per-platform wrappers.

The shared engine should own profile resolution, install-map evaluation, safe staging writes, and state updates. The Claude and Codex entrypoint scripts should stay small and pass only platform-specific inputs such as platform name, install map, and destination staging directory.

## Alternatives Considered

### 1. Thin shell copier per platform

This would be fastest to start, but it would duplicate profile resolution and copying logic in both sync scripts.

Why rejected:

- duplicated logic would drift quickly
- future features like digests and doctor checks would need to be implemented twice

### 2. Manifest generator first

This would resolve the install set into a separate generated manifest before applying it.

Why rejected for now:

- good long-term pattern, but too heavy for the first real sync pass
- adds another layer before the harness has basic end-to-end behavior

## Architecture

### Entry points

- `scripts/sync-claude.sh`
- `scripts/sync-codex.sh`

These remain user-facing commands. Their job is to parse simple arguments and call the shared engine with platform-specific defaults.

### Shared engine

Add a shared sync helper under `scripts/` that performs the actual work.

Responsibilities:

- resolve the selected profile
- resolve modules into components
- resolve components into source paths
- load the platform install map
- validate mapped source paths
- stage the resolved output into a local platform staging directory
- compute staged digests
- update the matching install-state file

### Data sources

The engine reads:

- `install/profiles.json`
- `install/modules.json`
- `install/components.json`
- `platforms/<platform>/install-map.json`

### Outputs

The engine writes:

- `state/staging/claude/` or `state/staging/codex/`
- `state/claude-install-state.json` or `state/codex-install-state.json`

## Data Flow

### 1. Select platform and profile

The wrapper chooses the platform. The default profile is `minimal`, with an optional `--profile <id>` override.

### 2. Resolve install scope

Resolution order:

1. profile -> modules
2. modules -> components
3. components -> source paths

This creates the allowed source set for the current run.

### 3. Apply platform install map

The install map determines which repository paths stage into which destination paths.

Only mapped items whose source paths are allowed by the resolved component set should be copied.

### 4. Rebuild staging output

The platform staging directory should be replaced on each run so stale files cannot linger between syncs.

### 5. Record install state

After a successful sync, the platform state file should be updated with:

- platform
- installed timestamp
- selected profile
- resolved modules
- target root set to the staging directory
- status set to `installed`
- component digests derived from staged output

## Safety Rules

- do not write to `~/.claude/` or `~/.codex/` in this milestone
- fail on unknown profile, module, component, or install-map source
- fail if an install-map source falls outside the repository root
- fail if two mappings target the same staged path
- rebuild the full staging directory each run instead of trying to merge with previous output

## File And Directory Expectations

Expected staging roots:

- `state/staging/claude/`
- `state/staging/codex/`

Expected state files:

- `state/claude-install-state.json`
- `state/codex-install-state.json`

Expected wrapper behavior:

- `./scripts/sync-claude.sh`
- `./scripts/sync-codex.sh`

Each script should support:

- `--help`
- optional `--profile <id>`

## Verification Plan

Verification should prove real end-to-end staging behavior.

Required checks:

- `--help` works for both wrapper scripts
- a real Claude sync stages files into `state/staging/claude/`
- a real Codex sync stages files into `state/staging/codex/`
- install-state files update with profile, modules, target root, and timestamp
- rerunning the same sync produces a clean, repeatable staged tree with no stale leftovers

## Risks And Guardrails

### Risk: copying too much

Guardrail:

- stage only install-map entries whose sources are allowed by resolved components

### Risk: platform drift in sync logic

Guardrail:

- keep real logic in one shared engine
- keep wrapper scripts thin

### Risk: ambiguous target collisions

Guardrail:

- fail immediately when two mappings resolve to the same target path

## Success Criteria

The design is successful if:

- both platforms can be staged from the same shared engine
- staging output is local and repeatable
- install metadata actually drives the sync behavior
- install-state files reflect the last successful staged sync
- the code can later be extended to home-directory sync without redesigning the pipeline
