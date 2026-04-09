# /plan

## Purpose

Entry point for bounded planning on non-trivial work.

## Process Ownership

The command owns planning admission and routing.

It should:

- bypass planning for simple tasks under the no-plan rule
- choose `plan-e` for reasoning-complete planning
- choose `plan-h` when minimal validation and freeze checks are warranted
- dispatch to the `planner` agent
- require use of the `planning-protocol` skill
- assemble a compact review surface for the human at freeze time

It must not:

- treat planning as implementation
- authorize broad execution during planning
- replace the original request with a different task

## Mode Routing

- `plan-e`: run A–E and stop once the reasoning-side task chain is stable enough for execution handoff.
- `plan-h`: run A–E, then add F–G probe and boundary checks before H review/freeze.

## Intended Coordination

- dispatch to the `planner` agent
- consult the `planning-protocol` skill for lifecycle, schema, freeze, and reopen rules
- invoke optional probe behavior only for `plan-h`
- apply repository rules while forming the plan
