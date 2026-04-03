# /plan

## Role

Entry point for planning multi-step work.

## Intended Coordination

- `/plan` remains the default baseline entrypoint.
- It coordinates with `agents/planner.md` and the `skills/tdd-workflow/SKILL.md` skill.
- It keeps the baseline front half focused on task framing, examples, and edge cases.
- It produces the same shared constraint packet handoff used by the experiment.
- It applies repository rules while forming the plan.

## Baseline Contract

The baseline contract is to interpret the prompt, shape provisional acceptance criteria, and hand off a shared constraint packet before downstream implementation takes over.
