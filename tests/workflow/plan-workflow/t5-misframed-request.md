# Trial T5: Intra-Chain Reopen D→A (Misframed Request)

## Target behavior

When the request misframes the problem (proposes an implementation that violates
an existing architectural contract), step D should catch the misframing and
reopen A — not surface it as a route option to filter.

## Input prompt

```
/plan doctor.sh should fix drift automatically
```

## How to run

Run exactly as written in a Claude Code session where the harness is installed.

## Context

doctor.sh and repair.sh have an explicit contract boundary — diagnosis vs. repair
are separated by design. The request frames that boundary as a bug.

## What to observe

- [ ] Step A or D identifies the request as misframing an architectural contract,
      not a genuine feature request
- [ ] Step D (critic agent) catches that "auto-heal" collapses the
      diagnosis/repair split that is intentional
- [ ] The planner explicitly reopens A (not filters a route in D) — the
      `request_invariant` itself needs reconsideration
- [ ] `challenged_assumptions` at A names the assumption that the separation is
      a defect
- [ ] The final output either: (a) reframes the request into something repo-compatible
      (e.g., "add a repair suggestion to doctor output") or (b) escalates the
      architectural tension for human resolution

## Pass condition

The planner does not proceed toward implementing auto-heal in doctor.sh. The
architectural contract violation is named explicitly, and either a reopen-to-A
or an escalation is produced.

## Notes

This is the second highest-signal trial. If the planner proceeds with "yes,
add an auto-fix mode to doctor.sh" without surfacing the contract tension, the
critic agent's isolation and the reopen-to-A path are both not activating.
