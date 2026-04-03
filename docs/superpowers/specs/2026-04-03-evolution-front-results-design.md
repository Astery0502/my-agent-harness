# Evolution-Front Results Documentation Design

**Goal:** add durable experiment documentation for the evolution-front workflow and extend the current evidence set with two additional Stage B trials on different weak-prompt classes.

## Scope

This design covers experiment evidence, not workflow promotion.

Included:

- two more Stage B trials on different weak-prompt classes
- one permanent repo doc that records method, completed trials, and current recommendation
- a small README note pointing readers to the experiment doc

Excluded:

- promotion of evolution-front into default harness policy
- a stricter subagent orchestration layer
- heavy automation or result dashboards
- changing the baseline or challenger workflow definitions themselves

## Proposed Trial Batch

Run two additional Stage B trials:

1. `hidden dependency`
2. `unstable acceptance criteria`

Each trial should:

- start from a weak prompt grounded in the repo
- produce baseline and challenger front-half handoffs
- execute both through the same small downstream implementation style in isolated temp repos
- record reopen pressure, downstream churn, and verification outcome

## Permanent Documentation

Create `docs/evolution-front-experiment.md` as the durable reference doc.

It should include:

- experiment purpose and boundaries
- baseline vs challenger summary
- Stage A and Stage B method
- completed trial matrix
- key lessons from each trial
- current recommendation
- how to continue the experiment later without changing policy prematurely

## README Update

Add a short section in `README.md` that points to `docs/evolution-front-experiment.md` and explains that the workflow is still experimental and evidence-driven.

## Success Criteria

This work is successful if:

- the repo contains a durable experiment reference doc
- at least two additional Stage B trials are completed and summarized there
- the current recommendation is grounded in repeated trial evidence rather than ad hoc memory
