# Planning Lifecycle

This file defines the normative A–H lifecycle for `/plan`.

## Agent Operating Model

- Treat the constraint packet as the shared context bus. Each step reads the current packet, updates only its named fields, and hands the packet forward.
- Persist the packet in one workspace-local file, `.constraint-packet.md` in the current working directory of the `/plan` run. This file is the live `constraint_packet` for the lifecycle.
- When a different role owns a step, prefer a fresh read of the current packet and that step's local inputs rather than relying on stale conversational memory.
- A reopen is targeted constraint re-entry into the nearest broken upstream step, not a full restart by default.

## File-Backed Operating Rule

- The lifecycle is file-backed by default. Do not forward the packet through memory alone.
- Step start: read `.constraint-packet.md` first. If it does not exist yet, only step A may create it.
- Step work: update only the fields owned by the current step.
- Step end: overwrite `.constraint-packet.md` once before any handoff, stop, or role transfer, even if the step only confirmed or preserved existing fields.
- Ownership transfer: the next role must read `.constraint-packet.md` before continuing; conversational memory is not authoritative.
- Reopen or re-entry: reuse the same `.constraint-packet.md` file. Do not delete it, replace it with a new path, or restart from a blank packet. Increment `iteration`, record `delta_from_prior`, and continue from `reopen_target`.

## Decomposition Hierarchy

The target decomposition unit at step C is **function** — the smallest independently
testable unit. The hierarchy is:

```text
requirement → feature → module → function
```

Actionable Requirement Items (ARIs) produced at step C should be traceable to this
level. The task chain at step E sequences ARIs but does not replace them.

All steps below must follow the File-Backed Operating Rule.

## Step A. Preprocess

- Purpose: treat the request as an input hypothesis rather than final truth. Operating assumption: the user may be inarticulate, incomplete, concealing, or lying.
- Goals: apply two distinct epistemic operations — (1) *requirements as hypotheses*: challenge ambiguity and underspecified points; (2) *requirements as non-truth*: challenge claims that conflict with objective facts. Identify missing information, unstable assumptions, and preserve intent while normalizing the task.
- Ownership: planner.
- Required output: `request_invariant`, `focus`, `non_goals`, `unknowns`, `challenged_assumptions`.
- Constraint packet update: initiate the packet — write `mode`, `request_invariant`, `focus`, `non_goals`, `unknowns`, `challenged_assumptions`. The packet is now open and will be updated forward.
- Stop condition: the request is compressed into a stable, reviewable statement without losing original intent.
- Modes: `plan-e`, `plan-h`.

## Step B. Expand

- Purpose: broaden the possibility space before narrowing it.
- Goals: expose candidate routes, hidden requirements, and blind spots in the user request.
- Ownership: planner.
- Required output: `candidate_routes`, optional hidden requirements, optional route-level assumptions.
- Constraint: keep the route set large enough to be compared without becoming noisy, but do not pre-filter routes — the critic handles reduction at step D.
- Constraint packet update: add `candidate_routes` to the packet.
- Stop condition: the route set is large enough for comparison without becoming noisy.
- Modes: `plan-e`, `plan-h`.

## Step C. Atomize

- Purpose: translate candidate routes into independently evaluable requirement items.
- Goals: break each surviving route into Actionable Requirement Items (ARIs). Each ARI must have: a statement, an acceptance criterion, a parent route, and a testable boolean outcome. ARIs are the leaf nodes of the decomposition hierarchy (requirement → feature → module → function). TDD is the foundational execution paradigm: every ARI must have a corresponding test before it is accepted — an ARI without a testable acceptance criterion is not complete.
- Ownership: planner.
- Required output: `actionable_requirements` (ARI set), `ari_dependency_graph`, `route_to_ari_mapping`.
- Constraint packet update: add `actionable_requirements`, `ari_dependency_graph`, and `route_to_ari_mapping` to the packet.
- Upstream reopen condition: if atomization surfaces a hidden requirement that invalidates the `request_invariant`, reopen A before continuing.
- Stop condition: every surviving route can be expressed as a bounded set of ARIs, each independently evaluable.
- Modes: `plan-e`, `plan-h`.

## Step D. Critique / Filter

- Purpose: reject weak, conflicting, or hallucinated ARIs via an independent observer.
- Goals: remove unreasonable ARIs, resolve requirement conflicts, and reduce noise.
- Ownership: `critic` agent by default. The planner submits the ARI set and steps back — the planner does not run D.
- Critic isolation: the critic agent has no prior context of steps A–C. It receives only the ARI set, the route set, and the `route_to_ari_mapping` when needed for objective filtering. This zero shared-context property is what makes the filtering objective.
- Role discipline: apply orthogonal filtering — reject ARIs that are non-objective, internally contradictory, duplicated, or infeasible from first principles. When two ARIs conflict, prefer the one that supports the broader end-to-end chain. Document the conflict and the resolution rationale.
- Required output: `rejected_aris` (with rejection reason per ARI), `conflict_notes`, surviving ARI set, `accepted_constraints`.
- Constraint packet update: update `actionable_requirements` to the surviving set; add `rejected_aris`, `conflict_notes`, and `accepted_constraints`.
- Upstream reopen condition: if critique reveals the expansion was built on a false premise, reopen B. If it reveals the request itself was misframed, reopen A.
- Stop condition: the surviving ARI set is materially smaller and cleaner than the full set from C.
- Modes: `plan-e`, `plan-h`.

## Step E. Complete

- Purpose: close the reasoning chain so execution can be handed off safely.
- Goals: fill missing links, complete dependencies, and stabilize the task chain over the surviving ARIs.
- Ownership: planner.
- Required output: `chosen_route`, `why_this_route`, `task_chain` (sequencing artifact over surviving ARIs — not defined independently), `imports`, `risks`, `verification_target`, `draft_acceptance_criteria`, `freeze_condition`. Every ARI in the task chain must carry an acceptance criterion that forms a testable outcome — execution is test-driven; test coverage must fully correspond to the surviving feature set.
- Constraint packet update: finalize `chosen_route`, `why_this_route`, `task_chain`, `imports`, `risks`, `verification_target`, `draft_acceptance_criteria`, and `freeze_condition`. The packet is now a stable handoff candidate.
- Upstream reopen condition: if gap-filling reveals a missing dependency that no surviving ARI can satisfy, reopen B. If the gap cannot be resolved locally, surface it as an unresolved unknown for human escalation rather than silently patching.
- Stop condition: the task chain is coherent, proportional, and stable enough that execution could begin.
- Modes: `plan-e`, `plan-h`.

## Step F. Probe

- Purpose: test ARI feasibility cheaply before execution; re-converge requirements on failure.
- Goals: generate the smallest concrete feasibility artifact appropriate to each ARI (for example a validation script, focused test, query, or other runnable check). Discard ARIs that fail feasibility. Re-converge: surviving ARIs form the updated requirement set for freeze. The plan may proceed with a smaller ARI set rather than requiring full reopen if partial survival is sufficient.
- Ownership: probe role if available, otherwise planner.
- Required output: `probes`, `probe_results`, `surviving_requirements` (ARI subset that passed feasibility), `killed_aris` (with failure reason per ARI).
- Constraint: probes must stay minimal and must not become broad implementation. Purely conceptual checks are insufficient; the probe must leave concrete feasibility evidence.
- Constraint packet update: add `surviving_requirements` and `killed_aris` to the packet.
- Stop condition: the surviving requirement set is feasibility-validated. Full reopen is only required if the surviving set is too small to satisfy the request invariant.
- Modes: `plan-h` only.

## Step G. Red-Blue Adversarial

- Purpose: stress the surviving ARIs at likely failure edges with committed Blue judgment.
- Goals: Red attacks with boundary problems; Blue commits to a resolution verdict per attack. If Blue cannot honestly defend an attack as `resolved` or `mitigated`, treat that as reopen evidence rather than silently forcing the chain forward.
- Two sub-roles:
  - **Red:** enumerate boundary problems and failure edges for each surviving ARI. Red has no knowledge of planned mitigations.
  - **Blue:** for each Red attack, commit to a resolution verdict — `resolved` (mitigation fully stated) or `mitigated` (partial, risk accepted). If neither verdict can be supported, emit a `reopen_trigger` entry.
- Ownership: probe role by default (running both Red and Blue sub-roles sequentially).
- Required output: `red_attacks` (per ARI), `blue_verdicts` (per attack with verdict and rationale), `reopen_triggers`.
- Constraint packet update: add `red_attacks`, `blue_verdicts`; update `risks` with accepted `mitigated` edges; add `reopen_triggers` if warranted.
- Stop condition: all surviving ARIs have `resolved` or `mitigated` verdicts, or the chain has been explicitly reopened upstream.
- Modes: `plan-h` only.

## Step H. Review / Freeze

- Purpose: compress the lifecycle into a reviewable decision artifact.
- Goals: decide whether the plan is stable enough to execute, keep the review surface small, and define reopen conditions.
- Ownership: planner assembles the artifact; human approves freeze.
- Required output: `review_decision`, `frozen_task_chain`, `execution_ready`, `reopen_conditions`, `reopen_target`.
- Constraint packet update: freeze the packet — write `review_decision`, `frozen_task_chain`, `execution_ready`, `reopen_conditions`, and `reopen_target` for each reopen condition, marking the specific step to return to if that condition fires downstream.
- Stop condition: the plan is frozen for execution or explicitly reopened upstream.
- Modes: `plan-h` only.
