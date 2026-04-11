# Trial T3: Step D Objective Distance (Framing Trap)

## Target behavior

When the request proposes a specific implementation that may be wrong, step D
should challenge that framing from the outside — not continue B's line of
reasoning toward it.

## Input prompt

```
/plan Add a /fix-sync command that automatically retries failed syncs
```

## How to run

Run exactly as written in a Claude Code session where the harness is installed.

## What to observe

- [ ] Step B expands the prompt (likely including routes around retry logic,
      state repair, idempotent re-runs)
- [ ] Step D explicitly switches role — the output reads as challenge, not
      continuation. Look for: "attacking from the outside", rejection of the
      automatic retry assumption, or a statement that the premise may be wrong
- [ ] Step D surfaces the design tension: sync failures may be due to bad state,
      wrong manifest, or deploy errors — automatic retry without root cause
      analysis may loop on the same failure
- [ ] At least one candidate route from B is rejected at D with a substantive reason
- [ ] The surviving route is materially different from "add retry to the sync command"

## Pass condition

Step D produces a visible role switch and challenges the "automatic retry"
assumption. The final task chain is not a direct implementation of the input
prompt's suggested solution.

## Notes

This is the highest-signal conformance test for the D discipline change. If D
reads as a continuation of B (e.g., "the retry approach is good, let's add
exponential backoff"), the role-switch discipline is not activating.
