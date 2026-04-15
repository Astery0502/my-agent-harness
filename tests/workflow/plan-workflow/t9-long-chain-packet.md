# Trial T9: Constraint Packet Bus Discipline — Long Chain

## Target behavior

When the planning chain is long (many decisions, cross-cutting concerns, multiple
integration points), the constraint packet should be visibly updated at each step
— not assembled once at the end or allowed to drift stale as new concerns emerge.

This trial directly targets the open question: *does constraint packet bus
discipline hold for longer chains?*

## Input prompt

```
/plan Add per-component install hooks: components can register before-install and after-install shell scripts in the manifest, which sync.sh runs at deploy time
```

## How to run

Run exactly as written in a Claude Code session where the harness is installed.

## What to observe

**Routing and step A:**
- [ ] The planner routes to planning-protocol A–E
- [ ] Step A names at least two challenged assumptions in `challenged_assumptions`
      (e.g., "hook scripts are safe to run without sandboxing", "hook failures
      should not abort the full sync")
- [ ] `unknowns` at A include hook failure semantics and security scope

**Step B — expansion must span multiple integration points:**
- [ ] Routes cover the cross-cutting concerns: manifest schema change, sync-common
      execution, install-state recording, doctor.sh handling of hook-failed
      components, and security/trust model for hook scripts

**Constraint packet updates through the chain:**
- [ ] Packet is visibly updated at B with `candidate_routes`
- [ ] Packet is visibly updated at D with `rejected_routes` and `accepted_constraints`
- [ ] Any concern raised at D that affects step A's assumptions triggers a packet
      update to `challenged_assumptions`, not a silent workaround
- [ ] By step E, the packet `accepted_constraints` includes the cross-cutting
      decisions made in earlier steps (e.g., whether hook failure aborts sync,
      whether hooks run in a subshell, whether skipped-hook components show as
      drifted in doctor.sh)

**Packet coherence check — the key signal:**
- [ ] A constraint established early (e.g., "hook failure aborts sync") is
      visible in the packet at E and reflected in the task chain — it was not
      silently dropped or overridden without a named reopen

**Step E:**
- [ ] The task chain is ordered to respect the dependency between integration
      points (manifest schema before sync execution; execution before state
      recording; state recording before doctor.sh handling)
- [ ] No integration point is left implicit ("we'll figure that out during
      implementation")

## Pass condition

The constraint packet is traceable from A through E: every major decision is
visible in the packet at the step where it was made, and the E task chain is
consistent with the accumulated constraints rather than contradicting them.

## Notes

The key failure mode is **packet drift**: the packet is initialized at A with
`unknowns`, but constraints decided at B or D are never added to the packet —
they exist only in the prose. By E the packet no longer reflects the full set
of accepted constraints, and the task chain may contradict earlier decisions
without flagging it.

A secondary failure mode is **silent constraint drop**: a constraint from D
(e.g., "hook scripts must run in a subshell, never the sync process") is named
in prose but missing from `accepted_constraints`, so the E task chain
implements inline execution without noticing the conflict.

This prompt was chosen because it genuinely spans five integration surfaces
(manifest, sync execution, state recording, drift detection, security model),
giving the packet multiple opportunities to drift.
