---
name: planning-protocol
description: Use for `/plan` workflows that need the full planning lifecycle as an agent-operable constraint-solving protocol. Reach for it whenever the task needs stabilization, route expansion, ARI filtering, freeze/reopen discipline, or a reusable constraint packet for `plan-e` or `plan-h`, even if the user only asks for "a plan."
---

# Planning Protocol

Use this skill only for `/plan` workflows. Design goal: the closed-loop structure should make an ordinary model highly focused and effective — structure compensates for model capability.

## Read Order

1. Read `references/lifecycle.md` for step ownership, stop conditions, and reopen semantics.
2. Read `references/artifacts.md` for the packet schema and freeze criteria.
3. Use `assets/plan-e-template.md` or `assets/plan-h-template.md` as the output surface for the active mode.
4. Use `assets/constraint-packet.md` when freezing a handoff packet or when re-entering the lifecycle after new evidence.

## Core Rules

- Simple tasks must bypass planning under the no-plan rule.
- `plan-e` runs A–E only.
- `plan-h` runs A–H.
- The planner owns A–C and E, and assembles H for human review in `plan-h`.
- The `critic` agent owns D by default; the planner submits the ARI set and steps back.
- Optional probe behavior owns F–G in `plan-h`; if probe behavior is unavailable, the planner may run those steps without changing their rules.
- The human approves freeze at H.
- Keep one evolving constraint packet from step A onward; do not reconstruct the packet from scratch at the end.
- Persist that evolving packet in one workspace-local file: `.constraint-packet.md` in the current working directory of the `/plan` run. This file is the live `constraint_packet` and must be reused throughout the lifecycle rather than replaced with per-step snapshots.
- When ownership moves to another role, hand off through the current packet and the step's required inputs rather than hidden conversational memory.

## Output Rules

- Emit the required artifact fields for the active mode.
- Use the templates in `assets/` to keep the review surface stable.
- Follow the file-backed operating rule in `references/lifecycle.md`: every step reads `.constraint-packet.md` first and overwrites it once at step end before any handoff or stop.
- Keep field names stable across lifecycle notes, packet templates, and final outputs so another agent can continue from the packet without reinterpreting it.
- Do not perform broad implementation while planning.
- Keep the task chain derived from the surviving ARIs; do not invent execution tasks independently.
- Reopen the nearest broken upstream step when probe results or later evidence invalidate the frozen chain.

## References

- Lifecycle, ownership, and stop conditions: `references/lifecycle.md`
- Artifact fields, freeze criteria, and reopen rules: `references/artifacts.md`
- Reviewable output shapes: `assets/plan-e-template.md`, `assets/plan-h-template.md`
