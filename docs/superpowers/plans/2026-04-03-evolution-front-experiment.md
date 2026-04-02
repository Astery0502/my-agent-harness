# Evolution-Front Experiment Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** implement an opt-in evolution-front workflow experiment in `my-agent-harness` so weak prompts can be handled by `clarify -> broaden/critique -> probe/freeze` before handing off to the same downstream implementation tail as the baseline TDD-oriented path, with the evolution workflow centered on building a closed evidence chain.

**Architecture:** the implementation should keep the baseline `/plan` path intact while making its front-half contract more explicit, then add one new opt-in experiment entrypoint with its own agent and skill assets. The challenger workflow should treat an `evidence chain record` as its primary artifact and emit a smaller `constraint packet` as a frozen handoff derived from that chain. Because shared `agents/`, `commands/`, and `skills/` directories are already staged wholesale by the sync scripts, the implementation can stay lightweight: mostly new markdown assets plus a focused integration test that proves the new surfaces stage correctly for both Claude and Codex.

**Tech Stack:** Markdown harness assets, Bash sync and integration tests, staged filesystem verification

---

## File Structure

### Files to create

- `agents/evolution-planner.md`
- `commands/evolution-plan.md`
- `skills/evolution-front-experiment/SKILL.md`
- `skills/evolution-front-experiment/templates/evidence-chain.md`
- `skills/evolution-front-experiment/templates/constraint-packet.md`
- `docs/evolution-front-experiment.md`
- `tests/test-evolution-front-experiment.sh`

### Files to modify

- `agents/planner.md`
- `commands/plan.md`
- `skills/tdd-workflow/SKILL.md`
- `README.md`

### Files to verify through execution

- `platforms/claude/install-map.json`
- `platforms/codex/install-map.json`
- `scripts/sync-claude.sh`
- `scripts/sync-codex.sh`
- `tests/test-staging-sync.sh`
- `tests/test-local-ops.sh`
- `docs/superpowers/specs/2026-04-03-evolution-front-experiment-design.md`

## Task 1: Add failing integration coverage for the experiment surfaces

**Files:**
- Create: `tests/test-evolution-front-experiment.sh`
- Test: new integration harness fails before the experiment assets exist

- [ ] **Step 1: Write the new shell integration test**

Cover:

- staged Claude output includes the new experiment command and skill assets
- staged Codex output includes the new experiment command, skill assets, and shared agent
- baseline `/plan` assets mention the shared `constraint packet` handoff
- challenger assets mention the three operational phases
- challenger assets mention the `evidence chain` as the primary artifact

- [ ] **Step 2: Run the new test to verify failure**

Run: `bash tests/test-evolution-front-experiment.sh`
Expected: FAIL because the new experiment files and baseline contract updates do not exist yet

- [ ] **Step 3: Commit**

```bash
git add tests/test-evolution-front-experiment.sh
git commit -m "test: add evolution-front experiment coverage"
```

## Task 2: Make the baseline front-half contract explicit

**Files:**
- Modify: `agents/planner.md`
- Modify: `commands/plan.md`
- Modify: `skills/tdd-workflow/SKILL.md`
- Test: baseline assets document the shared handoff shape clearly

- [ ] **Step 1: Expand `skills/tdd-workflow/SKILL.md`**

Document:

- baseline front-half purpose for clearer prompts
- fast path from interpretation to examples and test-oriented planning
- required output as a `constraint packet`
- the point where downstream implementation takes over

- [ ] **Step 2: Expand `agents/planner.md`**

Define the planner's baseline ownership:

- turn prompt into task statement and provisional acceptance criteria
- move quickly toward examples and edge cases
- emit the shared handoff artifact
- stay baseline-oriented rather than performing the evolution experiment

- [ ] **Step 3: Expand `commands/plan.md`**

Document:

- `/plan` remains the default baseline entrypoint
- it coordinates with the planner and TDD workflow skill
- it produces the same `constraint packet` contract used by the experiment

- [ ] **Step 4: Run targeted content checks**

Run:

```bash
rg -n "constraint packet|baseline|examples|edge cases" agents/planner.md commands/plan.md skills/tdd-workflow/SKILL.md
```

Expected: each file shows the updated baseline contract terms

- [ ] **Step 5: Commit**

```bash
git add agents/planner.md commands/plan.md skills/tdd-workflow/SKILL.md
git commit -m "feat: define baseline front-half contract"
```

## Task 3: Add the evolution-front skill and runtime templates

**Files:**
- Create: `skills/evolution-front-experiment/SKILL.md`
- Create: `skills/evolution-front-experiment/templates/evidence-chain.md`
- Create: `skills/evolution-front-experiment/templates/constraint-packet.md`
- Test: challenger skill documents the three-phase workflow and white-box outputs

- [ ] **Step 1: Write `skills/evolution-front-experiment/SKILL.md`**

Document:

- this is opt-in and experimental
- the three operational phases: `clarify`, `broaden and critique`, `probe and freeze`
- internal checkpoints preserved inside those phases
- the `evidence chain record` is the primary artifact
- the shared downstream handoff into the same implementation tail as baseline

- [ ] **Step 2: Add the `evidence-chain` template**

Include sections for:

- original prompt
- clarified request
- alternatives considered
- rejected assumptions
- chosen direction
- chosen constraints
- probe evidence
- draft acceptance criteria
- reopen notes

- [ ] **Step 3: Add the `constraint-packet` template**

Include sections for:

- task statement
- clarified assumptions
- rejected interpretations
- chosen direction
- open risks
- probe evidence
- draft acceptance criteria

- [ ] **Step 4: Run targeted content checks**

Run:

```bash
rg -n "clarify|broaden|probe|evidence chain|constraint packet|ambiguity surfaced early|diagnosability" skills/evolution-front-experiment
```

Expected: the skill and templates contain the agreed experiment vocabulary

- [ ] **Step 5: Commit**

```bash
git add skills/evolution-front-experiment
git commit -m "feat: add evolution-front experiment skill"
```

## Task 4: Add the opt-in experiment agent and command

**Files:**
- Create: `agents/evolution-planner.md`
- Create: `commands/evolution-plan.md`
- Test: the harness exposes a distinct opt-in entrypoint without changing the default path

- [ ] **Step 1: Write `agents/evolution-planner.md`**

Define ownership for:

- running the three operational phases
- keeping the experiment narrow and opt-in
- building a closed evidence chain before downstream planning
- freezing a constraint set before downstream planning
- preserving white-box evidence rather than only a final recommendation

- [ ] **Step 2: Write `commands/evolution-plan.md`**

Document:

- this is the experimental entrypoint
- it dispatches to `agents/evolution-planner.md`
- it consults `skills/evolution-front-experiment/SKILL.md`
- it builds an evidence chain record before freezing a handoff
- it uses the shared `constraint packet` handoff

- [ ] **Step 3: Verify baseline and challenger entrypoints are distinct**

Run:

```bash
rg -n "/plan|/evolution-plan|constraint packet|opt-in|experimental" commands agents
```

Expected: `/plan` stays baseline and `/evolution-plan` is clearly positioned as the experiment path

- [ ] **Step 4: Commit**

```bash
git add agents/evolution-planner.md commands/evolution-plan.md
git commit -m "feat: add evolution-front experiment entrypoint"
```

## Task 5: Document how to run and interpret the experiment

**Files:**
- Create: `docs/evolution-front-experiment.md`
- Modify: `README.md`
- Test: repo-level docs explain when and why to use the experiment

- [ ] **Step 1: Write `docs/evolution-front-experiment.md`**

Document:

- experiment purpose
- baseline vs challenger comparison shape
- the evidence chain requirement and why it matters
- the two-stage test design
- the semi-structured rubric
- the four theory lenses: decision theory, control theory, constraint formalization, observability

- [ ] **Step 2: Update `README.md`**

Add a short section describing:

- the existence of the opt-in experiment
- that it targets weak prompts
- that it builds a closed evidence chain before implementation
- that it does not replace the default path yet

- [ ] **Step 3: Run targeted content checks**

Run:

```bash
rg -n "evolution-front|weak prompts|evidence chain|decision theory|control theory|constraint formalization|observability" README.md docs/evolution-front-experiment.md
```

Expected: repo docs mention the experiment and its interpretation lenses clearly

- [ ] **Step 4: Commit**

```bash
git add README.md docs/evolution-front-experiment.md
git commit -m "docs: add evolution-front experiment guide"
```

## Task 6: Verify the experiment stages cleanly for both runtimes

**Files:**
- Review: `tests/test-evolution-front-experiment.sh`
- Review: `tests/test-staging-sync.sh`
- Review: `tests/test-local-ops.sh`

- [ ] **Step 1: Run the new experiment integration test**

Run: `bash tests/test-evolution-front-experiment.sh`
Expected: PASS

- [ ] **Step 2: Re-run staging sync integration**

Run: `bash tests/test-staging-sync.sh`
Expected: PASS, showing the new shared assets stage correctly for both Claude and Codex

- [ ] **Step 3: Re-run local ops integration**

Run: `bash tests/test-local-ops.sh`
Expected: PASS, showing that new shared files do not break staged digest checks or repair flow

## Task 7: Final verification and handoff

**Files:**
- Review: repository-wide evolution-front changes

- [ ] **Step 1: Review the final diff**

Confirm:

- the baseline path stayed intact
- the challenger stayed opt-in
- the evidence chain is the primary challenger artifact
- the constraint packet contract is shared between both paths
- the experiment assets remain small and understandable

- [ ] **Step 2: Summarize residual risks**

Call out:

- the experiment is still documentation-driven, not hook-enforced
- the rubric is semi-structured and still partly operator-judged
- the evidence chain is only useful if later execution keeps it updated when links break
- further promotion should wait for repeated weak-prompt trials

- [ ] **Step 3: Prepare execution handoff**

Be ready to execute tasks in order, keeping commits small and verification visible after each stage.
