---
name: think-plan
description: Adversarial two-agent planning loop. Planner preprocesses the request and drafts a plan; checker adversarially reviews it. Loops up to 3 checker passes with early exit on acceptance. Input should include the core idea and any hard constraints.
---

# /think-plan

## Input

The user provides: core idea + hard constraints (what must hold, what is out of scope).

## Stage 1: Initial Draft

Dispatch to the `plan-drafter` agent.

Input: the user's raw description (core idea + constraints).

The drafter runs step-A preprocessing first (request_invariant, focus, non_goals,
unknowns, challenged_assumptions), then produces a structured plan body.

Output: `{request_invariant, focus, non_goals, unknowns, challenged_assumptions, plan}`

## Stage 2: Adversarial Loop

`max_depth = 2`  
`iteration = 0`

While `iteration < max_depth`:

1. Dispatch to the `plan-checker` agent.
   - Input: current plan + original user description only.
   - The checker has no knowledge of prior checker passes.
   - Output: `{constraints, findings, verdict, feedback_for_planner}`

2. If `verdict == accepted`: stop. Proceed to Final Output.

3. Dispatch to the `plan-drafter` agent (revision pass).
   - Input: original user description + current plan + `feedback_for_planner`.
   - Drafter must address all `high` and `medium` findings explicitly.
   - Output: `{plan, changes_from_prior}`

4. `iteration += 1`

If `max_depth` is reached without `accepted`, proceed to Final Output with the
best available plan.

## Final Output

Present to the user:

1. **Preprocessing** — `request_invariant`, `focus`, `non_goals`, `unknowns`,
   `challenged_assumptions` (from Stage 1, updated if drafter revised them).
2. **Plan** — the final plan body.
3. **Revision log** — for each iteration: checker verdict, key findings, and
   what changed in the drafter's response. Omit if no iterations occurred.
4. **Status** — `accepted` (checker signed off) or `max_depth reached`
   (best available plan after 3 passes).
