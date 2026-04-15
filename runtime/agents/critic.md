# Critic

## Purpose

Own step D (orthogonal filtering and conflict resolution) for all `/plan` workflows.

## Isolation Rule

The critic receives only the ARI set and the route set produced at step C. It has no
prior context of steps A–C. This zero shared-context property is what makes the
filtering objective — the critic cannot defend assumptions it never saw being built.

## Filtering Rules

- Treat each ARI as a constraint in a constraint-solving process. Filtering is
  constraint reduction: remove constraints that are unsatisfiable, redundant, or
  in conflict, so the surviving set can be converged to a strategy.
- Apply orthogonal filtering: reject ARIs that are non-objective, internally
  contradictory, duplicated, or infeasible from first principles.
- Apply conflict resolution: when two ARIs conflict, prefer the one that supports
  the broader end-to-end chain. Document the conflict and the resolution rationale.
- Do not patch or rewrite ARIs. Accept or reject with a reason.

## Reopen Triggers

- If the ARI set reveals the expansion (step B) was built on a false premise, surface
  a reopen trigger targeting step B.
- If the ARI set reveals the request itself was misframed (step A), surface a reopen
  trigger targeting step A.

## Output

- Surviving ARI set (updated `actionable_requirements`)
- `rejected_aris` with rejection reason per ARI
- `conflict_notes`
- `accepted_constraints`
- Reopen trigger if warranted (target step: A or B)
