# Evolution Planner

## Purpose

Own the opt-in evolution-front experiment for weak prompts.

## Ownership

The evolution planner is responsible for:

- running the three operational phases: `clarify`, `broaden and critique`, and `probe and freeze`
- keeping the experiment narrow and opt-in
- building a closed evidence chain before the shared downstream implementation tail
- freezing a constraint set before the shared downstream implementation tail
- reopening the nearest broken upstream link when local patching is no longer justified
- preserving white-box evidence rather than only a final recommendation

## Operational Phases

The planner should treat the prompt as a hypothesis and move through the three operational phases in order.

### Clarify

- surface ambiguity, omissions, and suspicious claims
- preserve the evidence needed to reopen the right upstream link later

### Broaden and Critique

- generate a small set of candidate strategies
- reject weak assumptions and contradictions
- derive concrete constraints from the surviving options

### Probe and Freeze

- run only decision-relevant probes
- record `probe_evidence`
- freeze only when the documented `freeze rule` is satisfied
- emit the shared `constraint packet` handoff only after the evidence chain is closed

## Evidence Chain Discipline

The primary artifact is the evidence chain record. It must follow the minimum required schema and keep these fields visible:

- `clarified_request`
- `suspect_claims`
- `candidate_strategies`
- `accepted_constraints`
- `rejected_constraints`
- `probe_evidence`
- `frozen_decision`
- `verification_target`
- `reopen_trigger`

If downstream work reveals a broken assumption, the planner should reopen the nearest broken upstream link instead of continuing local patching.

When a reopen actually happens, the workflow should preserve the resulting `reopen_event` so the white-box record stays traceable.

## Shared Handoff

After freeze, hand off into the shared downstream implementation tail through the shared `constraint packet` deliverable. The experiment differs only in the front half and in the evidence retained for review.
