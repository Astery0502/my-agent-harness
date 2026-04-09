---
name: planning-protocol
description: Use for `/plan` workflows that need a stable planning protocol, explicit lifecycle ownership, required planning artifacts, and freeze/reopen rules for `plan-e` and `plan-h`.
---

# Planning Protocol

Use this skill only for `/plan` workflows.

## Core Rules

- Simple tasks must bypass planning under the no-plan rule.
- `plan-e` runs A–E only.
- `plan-h` runs A–H.
- The planner owns A–E.
- Optional probe behavior owns F–G in `plan-h`.
- The human approves freeze at H.

## Output Rules

- Emit the required artifact fields for the active mode.
- Use the templates in `assets/` to keep the review surface stable.
- Do not perform broad implementation while planning.
- Reopen the nearest broken upstream step when probe results or later evidence invalidate the frozen chain.

## References

- Lifecycle, ownership, and stop conditions: `references/lifecycle.md`
- Artifact fields, freeze criteria, and reopen rules: `references/artifacts.md`
- Reviewable output shapes: `assets/plan-e-template.md`, `assets/plan-h-template.md`
