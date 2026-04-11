# Constraint Packet

This is the canonical terminal handoff artifact for all `/plan` front halves.
It is the frozen state of the constraint packet bus at the point of execution handoff.

Both `planning-protocol` and `evolution-front-experiment` workflows produce this
artifact as their downstream handoff. The front half differs; the handoff interface
is shared.

---

## Phase A — Request

- `task_statement`:
- `challenged_assumptions`:
- `unknowns`:

## Phase B — Expansion

- `candidate_routes`:

## Phase D — Critique

- `rejected_routes`:
- `accepted_constraints`:

## Phase E — Completion

- `chosen_direction`:
- `open_risks`:
- `verification_target`:
- `draft_acceptance_criteria`:
- `freeze_condition`:

## Phase F–G — Probe (plan-h only)

- `probe_evidence`:
- `reopen_trigger`:

## Freeze

- `reopen_target`:

---

## Notes

- Fields from phases not yet reached should be left blank, not omitted — they
  mark where the bus was when it was frozen.
- `reopen_target` names the specific step (A/B/C/D) to return to if a reopen
  condition fires downstream. It is set at freeze and used if the loop comes back.
- This packet is a frozen carry-forward artifact, not a worksheet for re-arguing
  the problem. It should reflect the reasoning chain's chosen direction, not open
  debate.
