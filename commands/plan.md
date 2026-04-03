# /plan

## Role

Entry point for planning multi-step work.

## Intended Coordination

- `/plan` remains the default baseline entrypoint.
- It coordinates with `agents/planner.md` and the `skills/tdd-workflow/SKILL.md` skill.
- It keeps the baseline front half focused on task framing, examples, and edge cases.
- It produces the same shared constraint packet handoff, meaning the shared `constraint packet` deliverable, used by the experiment.
- It applies repository rules while forming the plan.

## Baseline Contract

The baseline contract is to interpret the prompt, shape provisional acceptance criteria, and hand off the shared constraint packet handoff before downstream implementation takes over.
