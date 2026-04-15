# Constraint Packet

This is the canonical terminal handoff artifact for all `/plan` front halves.
It is the frozen state of the constraint packet bus at the point of execution handoff.

---

- `iteration`:
- `delta_from_prior`:
- `mode`:
- `request_invariant`:
- `focus`:
- `non_goals`:
- `code_assembly_schema`:
- `next_iteration_prompt`:

## Phase A — Request

- `challenged_assumptions`:
- `unknowns`:

## Phase B — Expansion

- `candidate_routes`:

## Phase C — Atomize

- `actionable_requirements`:

## Phase D — Critique

- `rejected_aris`:
- `conflict_notes`:
- `accepted_constraints`:

## Phase E — Completion

- `chosen_route`:
- `why_this_route`:
- `task_chain`:
- `imports`:
- `risks`:
- `verification_target`:
- `draft_acceptance_criteria`:
- `freeze_condition`:

## Phase F — Probe (plan-h only)

- `probes`:
- `probe_results`:
- `surviving_requirements`:
- `killed_aris`:

## Phase G — Red-Blue (plan-h only)

- `red_attacks`:
- `blue_verdicts`:
- `reopen_triggers`:

## Freeze

- `review_decision`:
- `frozen_task_chain`:
- `execution_ready`:
- `reopen_conditions`:
- `reopen_target`:

---

## Notes

- Fields from phases not yet reached should be left blank, not omitted — they
  mark where the bus was when it was frozen.
- `iteration` starts at 0. Increment before re-entering the lifecycle on any reopen.
- `delta_from_prior` is empty on iteration 0. On re-entry, record what changed from
  the prior frozen packet so the history stays traceable.
- `request_invariant`, `focus`, and `non_goals` come from step A and stay stable unless
  a named reopen changes them.
- `code_assembly_schema` must be operational, not narrative. It should say how the
  frozen constraints map to concrete implementation units, tests, and touch points.
- `next_iteration_prompt` is the carry-forward prompt to reuse if downstream
  execution finds new evidence or a reopen condition fires.
- `task_chain` sequences the surviving `actionable_requirements` — it is derived,
  not independently defined.
- `execution_ready` is a boolean set at freeze — true only when all freeze criteria are met.
- `reopen_conditions` lists the explicit conditions under which the frozen chain must be reopened. Each entry should reference the downstream failure event that would trigger it (e.g., a test failure, a broken assumption discovered during coding).
- `reopen_target` names the specific step (A/B/C/D) to return to if a reopen
  condition fires downstream. Set at freeze; used if the loop comes back.
- Prefer a named `reopen_target` over full-loop restart. Return to A only when the
  downstream problem has become a materially new raw request.
- This packet is a frozen carry-forward artifact, not a worksheet for re-arguing
  the problem.
