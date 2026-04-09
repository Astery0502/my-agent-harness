# Planning Artifacts

This file defines the artifact schema for `/plan`.

## Shared Fields

- `mode`: active planning mode, either `plan-e` or `plan-h`.
- `request_invariant`: stable statement of the original request that must remain preserved through planning.
- `focus`: the primary problem slice the plan is optimizing for.
- `non_goals`: nearby work that is explicitly out of scope.
- `unknowns`: unresolved facts or assumptions that still affect risk.
- `challenged_assumptions`: input assumptions questioned during preprocess.
- `candidate_routes`: bounded set of plausible planning routes considered during expansion.
- `rejected_routes`: routes removed during critique/filter, with enough context to explain rejection.
- `chosen_route`: the surviving route selected for completion.
- `why_this_route`: brief justification for route selection.
- `task_chain`: bounded execution-facing chain derived from the chosen route.
- `imports`: dependencies, approvals, or external inputs required by the task chain.
- `risks`: major risks that remain after route selection.
- `freeze_condition`: the condition under which the reasoning-side plan is stable enough to hand off.

## `plan-h` Fields

- `probes`: the smallest useful checks run against the chosen route.
- `probe_results`: outcomes of those checks.
- `kill_conditions`: findings that invalidate the chosen route or require reopen.
- `boundary_checks`: likely failure edges attacked before freeze.
- `failure_edges`: brittle spots exposed by boundary attack.
- `mitigations`: accepted mitigations for those edges.
- `reopen_triggers`: conditions that should reopen an upstream planning step.
- `review_decision`: final freeze decision presented for human approval.
- `frozen_task_chain`: the task chain as frozen for execution handoff.
- `execution_ready`: boolean indicating whether execution may begin.
- `reopen_conditions`: explicit conditions under which the frozen chain must be reopened.

## Freeze Criteria

The plan is good enough to freeze only when:

- the request invariant is preserved
- at least one route is chosen and justified
- the task chain is coherent and dependency-complete
- major risks are named
- remaining unknowns are acceptable for execution handoff
- for `plan-h`, probes and boundary checks do not force reopen
- the review surface is small enough for human approval

Freeze does not mean the work is solved. It means execution can begin without hidden planning gaps dominating the next phase.

## Reopen Criteria

The plan must be reopened when:

- probes invalidate the chosen route
- a boundary attack exposes an unmitigated failure edge
- a critical assumption was unsupported
- a required dependency was omitted
- downstream work shows that the frozen task chain relied on a broken upstream link

Reopen should target the nearest broken upstream step rather than restarting the full planning chain by default.
