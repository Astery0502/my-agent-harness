# Trial T2: Ambiguous Request → planning-protocol A–E

## Target behavior

When the request is underspecified or has multiple valid interpretations, the
planner should route to the planning-protocol A–E path and perform divergence
in step B before committing to a route.

## Input prompt

```
/plan Make the doctor better
```

## How to run

Run exactly as written in a Claude Code session where the harness is installed.

## What to observe

- [ ] The planner signals it is using the planning-protocol A–E path
- [ ] Step A surfaces at least two distinct interpretations of "better"
- [ ] Step B generates 2–4 candidate routes (e.g., improve drift detection accuracy,
      improve output formatting, add auto-repair, improve speed)
- [ ] Step D challenges at least one candidate route with objective distance — not
      just continuing B's reasoning
- [ ] The constraint packet is updated at each step (A, B, D, E) — not assembled once at E
- [ ] `challenged_assumptions` is non-empty at step A

## Pass condition

The planner uses A–E diverge-converge reasoning. At least one
candidate route from B is challenged or rejected at D with a reason.

## Notes

"Make the doctor better" is intentionally vague. If the planner moves directly
to a task chain without surfacing competing interpretations, the A routing
heuristic is under-triggering.
