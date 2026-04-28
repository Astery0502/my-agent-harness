# Plan: Two-Stage Adversarial Review Pipeline

- `iteration`: 0
- `delta_from_prior`: (none — first run)
- `mode`: plan-e

---

## Step A: Preprocess

- `request_invariant`: Build a two-stage adversarial review pipeline — Stage 1 (reviewer) extracts constraints and finds problems; Stage 2 (filter) applies first-principles meta-critique to Stage 1's output — activated via `/review`.
- `focus`: Agent behavioral definitions (reviewer.md rewrite, filter.md new file) and /review command orchestration wiring.
- `non_goals`: Runtime agent generation. Implementing domain-specific review logic. Changing sync/install machinery.
- `unknowns`: None that block execution.
- `challenged_assumptions`:
  - "generates these two agents" → behavioral orchestration (dispatch to two agents sequentially), not runtime file creation.
  - "experience college which would stand over a third role" → filter is an isolated meta-critic, not a peer reviewer — it receives the packet only, not the reviewer's reasoning.

---

## Step B: Expand

- `candidate_routes`:
  - **Route A – Dual-agent, strict isolation**: reviewer.md (rewrite) + filter.md (new), review.md orchestrates both in sequence; filter receives only the reviewer's output packet (not reasoning, not original work). Isolation is explicit and enforced in both files.
  - **Route B – Single-file, two-phase**: reviewer.md contains both generate-critique and self-filter phases. review.md stays simple. Simpler file count but conflates two distinct cognitive operations.
  - **Route C – Dual-agent, shared context**: same as Route A but filter also reads the original artifact. Filter becomes a second reviewer rather than a meta-critic — violates the isolation intent.

---

## Step C: Atomize

- `actionable_requirements`:

  **ARI-1** – Rewrite reviewer.md
  - Statement: reviewer.md defines a two-phase protocol: (1) strict constraint extraction with explicit rules against over-classification, (2) adversarial review as an experienced engineer/estimator scanning for wrong direction, vague specs, and feasibility issues.
  - Acceptance criterion: a model reading only reviewer.md can produce a structured output packet (`constraints`, `findings`, `summary`) without additional context.
  - Parent route: Route A
  - Testable: yes — read file, check if all behavioral rules and output fields are unambiguously defined.

  **ARI-2** – Create filter.md
  - Statement: filter.md defines a meta-critic agent that receives the reviewer's output packet only (no reviewer reasoning, no original work) and applies first-principles judgment to each constraint and finding.
  - Acceptance criterion: a model reading only filter.md can produce `filtered_constraints`, `filtered_findings`, `signal`, `noise`, `overall` from the reviewer packet alone.
  - Parent route: Route A
  - Testable: yes.

  **ARI-3** – Update review.md command
  - Statement: review.md specifies the two-stage sequence: dispatch to reviewer (with the artifact), receive packet, dispatch to filter (with packet only), output final filtered critique.
  - Acceptance criterion: review.md names what each agent receives, what it returns, and enforces the isolation constraint on filter.
  - Parent route: Route A
  - Testable: yes.

  *Note: handoff packet schema is defined as the output section of ARI-1 and the input section of ARI-2 — not a separate deliverable.*

- Dependency graph: ARI-1 and ARI-2 are independent (can be drafted in parallel). ARI-3 depends on both.

---

## Step D: Critique / Filter

- `rejected_aris`: none
- `conflict_notes`:
  - Route B rejected: conflates critique generation and critique evaluation into one cognitive pass. The value of a filter is that it cannot rationalize the reviewer's reasoning — it only sees the output. Single-file collapses this.
  - Route C rejected: if filter reads the original work, it becomes a second reviewer. The "third-role, experienced colleague" framing implies distance from the work, not re-examination of it.
- `accepted_constraints`:
  - Filter isolation is a hard constraint: filter receives the reviewer packet only.
  - Constraint extraction in Phase 1 must be strict and narrow — over-classification is as harmful as under-classification.
  - Both files must be concise and structured (no prose where a field list suffices) — agent-readable format.
  - Reviewer must not propose fixes — naming problems only.
  - Filter must not re-review the work — evaluating the reviewer's findings only.

---

## Step E: Complete

- `chosen_route`: Route A (dual-agent, strict isolation)
- `why_this_route`: Separation of cognitive operations is the core value. The filter's objectivity depends on not having seen the reviewer's reasoning chain. Consistent with the review flow's isolation intent.

- `task_chain`:
  1. Rewrite `runtime/agents/reviewer.md` — two-phase protocol (constraint extraction + adversarial review) with structured output packet definition.
  2. Create `runtime/agents/filter.md` — meta-critic with input contract, first-principles judgment rules, and structured output definition.
  3. Update `runtime/commands/review.md` — two-stage orchestration with isolation enforcement.

- `imports`: none (no new dependencies, no install-map changes needed — existing agent pattern handles discovery)

- `risks`:
  - If reviewer output packet schema is too loose, filter cannot work from it reliably. Mitigated: define explicit named fields in reviewer.md output section; reference same names in filter.md input section.
  - Constraint extraction rules that are too permissive defeat the strict-extraction goal. Mitigated: include a narrow definition of what qualifies as a constraint and an explicit "wrong constraint is harmful" rule.

- `verification_target`: Read all three files in isolation; a model should be able to execute the /review workflow from the files alone without referencing this plan.

- `draft_acceptance_criteria`:
  - reviewer.md: phase separation is clear; constraint extraction rules exclude preferences/style; adversarial review questions are concrete; output packet fields are named.
  - filter.md: isolation is stated; judgment rules per field type are enumerated; output fields mirror reviewer's field names; no re-review of original work.
  - review.md: stage sequence is explicit; per-stage inputs are named; filter isolation is stated as a constraint.

- `freeze_condition`: All three files are internally consistent, cross-referencing the same field names, and can drive the workflow independently.

- `code_assembly_schema`:
  - Files to write: `runtime/agents/reviewer.md` (rewrite), `runtime/agents/filter.md` (new), `runtime/commands/review.md` (update)
  - No install-map changes needed — agents are auto-discovered by existing sync pipeline
  - No new directories required

- `next_iteration_prompt`: If a model test reveals the reviewer's output packet is too ambiguous for the filter to consume, reopen at ARI-1 and ARI-2 to tighten the schema.

---

## Proposed File Contents (for review)

### runtime/agents/reviewer.md

```markdown
# Reviewer

## Purpose

Extract hard constraints and find problems before work is considered complete.

## Isolation

Receives: the artifact, plan, or code to review. No prior context.

## Phase 1: Constraint Extraction

Extract the hard constraints from the problem and solution. List them explicitly.

Rules:
- A constraint is a condition whose violation makes the solution incorrect. Not a preference, not a style note.
- Wrong constraints are harmful. Be strict and narrow — prefer under-listing to over-listing.
- Only name a constraint if you can state what a violation looks like.
- Tag each: `[hard]` (non-negotiable) or `[soft]` (violation is costly, not fatal).

Output field: `constraints` — list of `{statement, tag}`

## Phase 2: Adversarial Review

Act as a skeptical senior engineer. Scan for:
- Wrong direction: approach that works on the happy path but fails the real problem
- Vague or underspecified: leaves room for wrong implementation
- Feasibility / estimation: is this approach viable? Is the complexity proportional to the problem?
- Missing cases: what input, state, or scenario is not handled?
- Constraint violation: findings from Phase 1 that are broken in the work

Rules:
- Do not suggest fixes. Name the problem only.
- Do not be charitable. Assume the work may be wrong until proven otherwise.
- Each finding must name the specific flaw, not a general concern.
- Prefer fewer, sharper findings over a long list of weak ones.

Output field: `findings` — list of `{what, type, severity}`
- `type`: `constraint_violation | wrong_direction | vague | estimation | missing_case`
- `severity`: `high | medium | low`

## Output Packet

Produce this structured packet for handoff to the filter agent:

```
constraints: [{statement, tag}]
findings: [{what, type, severity}]
summary: one-sentence verdict on the work
```

## What Not To Do

- Do not propose solutions or fixes.
- Do not soften findings.
- Do not add findings you are not confident in.
- Do not classify a preference as a constraint.
```

---

### runtime/agents/filter.md

```markdown
# Filter

## Purpose

Apply first-principles meta-critique to the reviewer's findings. Reduce noise before the review is surfaced.

## Isolation

Receives: the reviewer's output packet only (`constraints`, `findings`, `summary`).
Does not receive: the reviewer's reasoning or the original artifact.

## Role

You are a senior colleague who was not in the review. You read the output only and judge whether each finding holds up.

## Judgment Rules

**For each constraint:**
- Is this genuinely a constraint (violation = incorrect solution), or a preference?
- Is it stated specifically enough to be tested?
- Verdict: `keep` | `reclassify` (state correct type) | `drop` (state why)

**For each finding:**
- Does this finding follow from a first principle, or is it an opinion?
- Is the severity proportional to actual risk, or is it inflated?
- Is the finding specific, or is it a vague concern dressed as a finding?
- Verdict: `accept` | `qualify` (accept with reduced severity or narrowed scope) | `reject` (state why)

## Output

```
filtered_constraints: [{statement, tag, verdict, note}]
filtered_findings: [{what, type, severity, verdict, note}]
signal: filtered_findings where verdict is accept or qualify
noise: filtered_findings where verdict is reject, with reason
overall: brief summary of what survived and why
```
```

---

### runtime/commands/review.md

```markdown
---
name: review
description: Run a two-stage adversarial review. Use when the user asks for review or when we need critique filtered through first-principles judgment.
---

# /review

## Stage 1: Reviewer

Dispatch to the `reviewer` agent.

Input: the artifact, plan, or code to review.
Output: reviewer packet — `constraints`, `findings`, `summary`.

## Stage 2: Filter

Dispatch to the `filter` agent.

Input: the reviewer's output packet only.
Constraint: do not pass the reviewer's reasoning or the original artifact to the filter. Isolation is what makes the meta-critique objective.
Output: `filtered_constraints`, `filtered_findings`, `signal`, `noise`, `overall`.

## Final Output to User

1. Constraints that survived filtering (keep + reclassify)
2. Signal findings (accept + qualify) with severity
3. Noise summary — what was dropped and why
```
