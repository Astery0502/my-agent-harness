# /plan

## Admission

- Bypass planning for simple tasks under the no-plan rule.
- Choose `plan-e` for reasoning-complete planning.
- Choose `plan-h` when probe and boundary checks are warranted before freeze.
- Route the front half based on request clarity:
  - Clear request (interpretable without challenging its premise) → `tdd-workflow` fast path.
  - Ambiguous or suspect request (requires divergence first) → `planning-protocol` A–E.

## Constraints

- Do not treat planning as implementation.
- Do not authorize broad execution during planning.
- Do not replace the original request with a different task.

## Coordination

- Dispatch to the `planner` agent.
- Use the `planning-protocol` skill as the source of lifecycle, schema, freeze, and reopen rules.
- Invoke probe behavior (F–G) only for `plan-h`.
