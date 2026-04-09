# Planning Lifecycle

This file defines the normative A–H lifecycle for `/plan`.

## Step A. Preprocess

- Purpose: treat the request as an input hypothesis rather than final truth.
- Goals: identify ambiguity, missing information, factual conflict, unstable assumptions, and preserve intent while normalizing the task.
- Ownership: planner.
- Required output: `request_invariant`, `focus`, `non_goals`, `unknowns`, `challenged_assumptions`.
- Stop condition: the request is compressed into a stable, reviewable statement without losing original intent.
- Modes: `plan-e`, `plan-h`.

## Step B. Expand

- Purpose: broaden the possibility space before narrowing it.
- Goals: expose candidate routes, hidden requirements, and blind spots in the user request.
- Ownership: planner.
- Required output: `candidate_routes`, optional hidden requirements, optional route-level assumptions.
- Constraint: expansion should usually stay within 2–4 routes rather than an open tree.
- Stop condition: the route set is large enough for comparison without becoming noisy.
- Modes: `plan-e`, `plan-h`.

## Step C. Decompose

- Purpose: translate candidate routes into structured task material.
- Goals: break routes into requirement points, identify dependencies, and produce a first task-chain draft.
- Ownership: planner.
- Required output: `task_chain_draft`, dependency notes, route-to-task mapping.
- Stop condition: the chosen route can be expressed as a bounded task chain.
- Modes: `plan-e`, `plan-h`.

## Step D. Critique / Filter

- Purpose: reject weak, conflicting, or hallucinated branches.
- Goals: remove unreasonable routes, identify requirement conflicts, and reduce noise.
- Ownership: planner by default. A separate critic may be used, but it is not the default.
- Required output: `rejected_routes`, `conflict_notes`, `weak_assumptions`, filtered route set.
- Stop condition: the surviving route set is materially cleaner than after expansion.
- Modes: `plan-e`, `plan-h`.

## Step E. Complete

- Purpose: close the reasoning chain so execution can be handed off safely.
- Goals: fill missing links, complete dependencies, and stabilize the task chain.
- Ownership: planner.
- Required output: `chosen_route`, `why_this_route`, `task_chain`, `imports`, `risks`, `freeze_condition`.
- Stop condition: the task chain is coherent, proportional, and stable enough that execution could begin.
- Modes: `plan-e`, `plan-h`.

## Step F. Probe

- Purpose: cheaply test whether the chosen route is viable before execution.
- Goals: validate inexpensive assumptions, kill bad routes early, and reduce execution waste.
- Ownership: probe role if available, otherwise planner.
- Required output: `probes`, `probe_results`, `kill_conditions`.
- Constraint: probes must stay minimal and must not become broad implementation.
- Stop condition: the plan has passed or failed the smallest useful viability checks.
- Modes: `plan-h` only.

## Step G. Boundary Attack

- Purpose: stress the plan at likely failure edges.
- Goals: attack boundary conditions, expose brittle assumptions, and identify mitigation or reopen triggers.
- Ownership: probe role by default.
- Required output: `boundary_checks`, `failure_edges`, `mitigations`, `reopen_triggers`.
- Stop condition: major failure edges are accepted, mitigated, or escalated for reopen.
- Modes: `plan-h` only.

## Step H. Review / Freeze

- Purpose: compress the lifecycle into a reviewable decision artifact.
- Goals: decide whether the plan is stable enough to execute, keep the review surface small, and define reopen conditions.
- Ownership: planner assembles the artifact; human approves freeze.
- Required output: `review_decision`, `frozen_task_chain`, `execution_ready`, `reopen_conditions`.
- Stop condition: the plan is frozen for execution or explicitly reopened upstream.
- Modes: `plan-h` only.
