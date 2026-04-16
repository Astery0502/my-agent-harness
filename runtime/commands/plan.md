---
name: plan
description: Create a structured implementation plan for non-trivial work. Use when the user explicitly asks for a plan or when the task needs clarification, route comparison, constraints, risks, or phased execution before coding.
---

# /plan

## Admission

- Bypass planning for simple tasks under the no-plan rule.
- Choose `plan-e` for reasoning-complete planning.
- Choose `plan-h` when probe and boundary checks are warranted before freeze.
- Use `planning-protocol` A–E for `/plan` front-half work. Do not bypass step A
  just because the request appears clear.

## Constraints

- Do not treat planning as implementation.
- Do not authorize broad execution during planning.
- Do not replace the original request with a different task.

## Coordination

- Dispatch to the `planner` agent for steps A–C and E.
- Dispatch to the `critic` agent for step D (orthogonal filtering). The critic is the
  default owner of D — not optional.
- Use the `planning-protocol` skill as the source of lifecycle, schema, freeze, and reopen rules.
- Invoke probe behavior (F–G) only for `plan-h`.
