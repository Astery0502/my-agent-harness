# Trial T1: Clear Request → tdd-workflow Fast Path

## Target behavior

When the request is interpretable without challenging its premise, the planner
should select the `tdd-workflow` fast path and skip the full A–E divergence cycle.

## Input prompt

```
/plan Add a --verbose flag to sync.sh that prints each file path as it is deployed
```

## How to run

Run exactly as written in a Claude Code session where the harness is installed.

## What to observe

- [ ] The planner signals it is using the tdd-workflow fast path (explicit mention
      of "tdd-workflow", "fast path", or "clear request" routing)
- [ ] The planner does NOT run a full A–B–C–D–E expansion cycle before reaching
      a task chain
- [ ] Provisional acceptance criteria are shaped early (before examples/edge cases)
- [ ] The constraint packet is initiated at step A, not assembled at the end
- [ ] Output reaches a concrete task chain without significant front-half divergence

## Pass condition

The planner selects the fast path and produces a task chain without a full
A–E divergence cycle. The constraint packet fields populated at A are visible.

## Notes

If the planner runs a full A–E cycle on this prompt, that is the signal to
examine: either the routing heuristic needs sharper wording, or the request
is not as clear as assumed.
