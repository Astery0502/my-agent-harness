# Planning Lifecycle

This file defines the normative A–H lifecycle for `/plan`.

## Step A. Preprocess

- Purpose: treat the request as an input hypothesis rather than final truth.
- Goals: identify ambiguity, missing information, factual conflict, unstable assumptions, and preserve intent while normalizing the task.
- Ownership: planner.
- Required output: `request_invariant`, `focus`, `non_goals`, `unknowns`, `challenged_assumptions`.
- Constraint packet update: initiate the packet — write `task_statement`, `unknowns`, `challenged_assumptions`. The packet is now open and will be updated forward.
- Stop condition: the request is compressed into a stable, reviewable statement without losing original intent.
- Modes: `plan-e`, `plan-h`.

## Step B. Expand

- Purpose: broaden the possibility space before narrowing it.
- Goals: expose candidate routes, hidden requirements, and blind spots in the user request.
- Ownership: planner.
- Required output: `candidate_routes`, optional hidden requirements, optional route-level assumptions.
- Constraint: expansion should usually stay within 2–4 routes rather than an open tree.
- Constraint packet update: add `candidate_routes` to the packet.
- Stop condition: the route set is large enough for comparison without becoming noisy.
- Modes: `plan-e`, `plan-h`.

## Step C. Decompose

- Purpose: translate candidate routes into structured task material.
- Goals: break routes into requirement points, identify dependencies, and produce a first task-chain draft.
- Ownership: planner.
- Required output: `task_chain_draft`, dependency notes, route-to-task mapping.
- Constraint packet update: add `task_chain_draft` to the packet.
- Upstream reopen condition: if decomposition surfaces a hidden requirement that invalidates the `request_invariant`, reopen A before continuing.
- Stop condition: the chosen route can be expressed as a bounded task chain.
- Modes: `plan-e`, `plan-h`.

## Step D. Critique / Filter

- Purpose: reject weak, conflicting, or hallucinated branches.
- Goals: remove unreasonable routes, identify requirement conflicts, and reduce noise.
- Ownership: planner by default. A separate critic may be used, but it is not the default.
- Role discipline: conduct step D as if you are a skeptical external reviewer who did not write the B output. Do not continue B's line of reasoning — attack it. What is wrong, incomplete, or optimistic about the candidate routes? Apply orthogonal filtering; surface conflicts; reject non-objective requirements.
- Required output: `rejected_routes`, `conflict_notes`, `weak_assumptions`, filtered route set.
- Constraint packet update: update `candidate_routes` to the surviving set; add `rejected_routes` and `accepted_constraints`.
- Upstream reopen condition: if critique reveals the expansion was built on a false premise, reopen B. If it reveals the request itself was misframed, reopen A.
- Stop condition: the surviving route set is materially cleaner than after expansion.
- Modes: `plan-e`, `plan-h`.

## Step E. Complete

- Purpose: close the reasoning chain so execution can be handed off safely.
- Goals: fill missing links, complete dependencies, and stabilize the task chain.
- Ownership: planner.
- Required output: `chosen_route`, `why_this_route`, `task_chain`, `imports`, `risks`, `freeze_condition`.
- Constraint packet update: finalize `chosen_direction`, `task_chain`, `open_risks`, `verification_target`, `draft_acceptance_criteria`, `freeze_condition`. The packet is now a stable handoff candidate.
- Upstream reopen condition: if gap-filling reveals a missing dependency that no surviving route can satisfy, reopen B. If the gap cannot be resolved locally, surface it as an unresolved unknown for human escalation rather than silently patching.
- Stop condition: the task chain is coherent, proportional, and stable enough that execution could begin.
- Modes: `plan-e`, `plan-h`.

## Step F. Probe

- Purpose: cheaply test whether the chosen route is viable before execution.
- Goals: validate inexpensive assumptions, kill bad routes early, and reduce execution waste.
- Ownership: probe role if available, otherwise planner.
- Required output: `probes`, `probe_results`, `kill_conditions`.
- Constraint: probes must stay minimal and must not become broad implementation. Where feasible, generate lightweight validation code to test feasibility rather than relying on conceptual checks alone.
- Constraint packet update: add `probe_evidence` to the packet.
- Stop condition: the plan has passed or failed the smallest useful viability checks.
- Modes: `plan-h` only.

## Step G. Boundary Attack

- Purpose: stress the plan at likely failure edges.
- Goals: attack boundary conditions, expose brittle assumptions, and identify mitigation or reopen triggers.
- Ownership: probe role by default.
- Required output: `boundary_checks`, `failure_edges`, `mitigations`, `reopen_triggers`.
- Constraint packet update: add `reopen_trigger` to the packet; update `open_risks` with any new failure edges.
- Stop condition: major failure edges are accepted, mitigated, or escalated for reopen.
- Modes: `plan-h` only.

## Step H. Review / Freeze

- Purpose: compress the lifecycle into a reviewable decision artifact.
- Goals: decide whether the plan is stable enough to execute, keep the review surface small, and define reopen conditions.
- Ownership: planner assembles the artifact; human approves freeze.
- Required output: `review_decision`, `frozen_task_chain`, `execution_ready`, `reopen_conditions`.
- Constraint packet update: freeze the packet — write `reopen_target` for each reopen condition, marking the specific step to return to if that condition fires downstream.
- Stop condition: the plan is frozen for execution or explicitly reopened upstream.
- Modes: `plan-h` only.
