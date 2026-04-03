# Evolution Front Experiment

## Status

This skill is opt-in and experimental. It exists to support the evolution-front comparison and should not replace the baseline planning path.

## Purpose

Use this skill when a prompt is weak, misleading, underspecified, or likely to benefit from a closed evidence chain before downstream planning begins.

The primary artifact is the evidence chain record. The shared `constraint packet` is a frozen handoff derived from that record, not a substitute for it.

## Operational Phases

The workflow uses three operational phases:

1. `clarify`
2. `broaden and critique`
3. `probe and freeze`

These phases are compressed for operation, but their internal checkpoints are preserved inside the phase boundaries.

### Clarify

- treat the request as a hypothesis, not a fact
- surface ambiguity, omissions, and suspicious claims
- preserve the clarification checkpoints needed to reopen the right upstream link later

### Broaden and Critique

- generate a small set of plausible candidate strategies
- test the request against competing interpretations
- decompose ideas into concrete constraints
- reject weak assumptions before commitment

### Probe and Freeze

- run only decision-relevant probes
- keep probe outputs in the `probe_evidence` structure
- record the pre-failure condition in `reopen_trigger`
- if a reopen actually happens, record the later `reopen_event` structure for that reopen action
- freeze only by the documented freeze rule, not by informal confidence alone

## Evidence Chain Record

The evidence chain record is the primary artifact for this experiment. Its minimum required schema must include:

- `clarified_request`
- `suspect_claims`
- `candidate_strategies`
- `accepted_constraints`
- `rejected_constraints`
- `probe_evidence`
- `frozen_decision`
- `verification_target`
- `reopen_trigger`

The record should stay sparse, but it must preserve enough structure to explain how the request was transformed and how a later reopen can target the nearest broken link. `reopen_trigger` is the condition that is recorded before failure or escalation, while `reopen_event` is the later record written only if a reopen actually occurs.

## Freeze Rule

Freeze only when the documented freeze rule is satisfied:

- the leading strategy is supported by the current evidence chain
- remaining uncertainty is not decision-critical
- the verification target is concrete enough to detect failure later
- a reopen trigger has been recorded

If those conditions are not met, continue clarifying, broadening, or probing instead of freezing early.

## Shared Handoff

After freeze, hand off into the same implementation tail as the baseline workflow. The shared downstream path remains the same as `/plan` and the baseline planner flow; the difference is only in the front half and the evidence carried into the handoff.

## Planned Sections

- status
- operational phases
- evidence chain record
- freeze rule
- shared handoff
