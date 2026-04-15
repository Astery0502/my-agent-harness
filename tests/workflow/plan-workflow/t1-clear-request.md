# Trial T1: Clear Request → planning-protocol A–E

## Target behavior

When the request is interpretable without challenging its premise, the planner
should still run planning-protocol A–E rather than bypassing step A.

## Input prompt

```
/plan Add a --verbose flag to sync.sh that prints each file path as it is deployed
```

## How to run

Run exactly as written in a Claude Code session where the harness is installed.

## What to observe

- [ ] The planner signals it is using planning-protocol A–E
- [ ] Step A still records any unknowns or confirms none need escalation
- [ ] The planner does run a full A–B–C–D–E chain before reaching a task chain
- [ ] Provisional acceptance criteria remain testable and concrete by the time the task chain is frozen
- [ ] The constraint packet is initiated at step A, not assembled at the end
- [ ] Output reaches a concrete task chain without unnecessary scope growth

## Pass condition

The planner runs A–E even on a clear request, and the constraint packet fields
populated at A remain visible through the chain.

## Notes

If the planner bypasses step A here because the prompt looks obvious, that is a
failure of the current contract.
