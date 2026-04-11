# Trial T4: Intra-Chain Reopen E→B (Hidden Dependency)

## Target behavior

When gap-filling at step E reveals a hidden dependency that no current candidate
route can satisfy, the planner should reopen B — not silently patch E or proceed
with an incomplete chain.

## Input prompt

```
/plan Add a --check flag to sync.sh that validates the install-map before syncing
```

## How to run

Run exactly as written in a Claude Code session where the harness is installed.

## What to observe

- [ ] Step E attempts to fill the dependency chain for "validate the install-map"
- [ ] Step E surfaces the hidden dependency: "validate" is underspecified —
      validate against what? (JSON schema? required fields? component coverage?
      path existence?)
- [ ] The planner does NOT silently pick one interpretation and proceed
- [ ] The planner either: (a) explicitly reopens B to generate routes for each
      interpretation of "validate", or (b) surfaces this as an unresolved unknown
      requiring human escalation — not local patching
- [ ] If a reopen fires, `reopen_target` is named as B (not A, not a full restart)

## Pass condition

The planner names the missing dependency explicitly and either reopens B or
escalates to the human rather than silently completing with an arbitrary choice.

## Notes

A silent patch at E (e.g., "we'll validate by checking required JSON keys") is
the failure mode. The intra-chain reopen should be visible in the output.
