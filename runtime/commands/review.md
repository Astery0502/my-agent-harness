---
name: review
description: Run a two-stage adversarial review. Use when the user asks for review or when we need critique filtered through first-principles judgment.
---

# /review

## Stage 1: Reviewer

Dispatch to the `reviewer` agent.

Input: the artifact, plan, or code to review.
Output: reviewer packet — `constraints`, `findings`, `summary`.

## Stage 2: Filter

Dispatch to the `filter` agent.

Input: the reviewer's output packet only.
Constraint: do not pass the reviewer's reasoning or the original artifact to the filter. Isolation is what makes the meta-critique objective.
Output: `filtered_constraints`, `filtered_findings`, `signal`, `noise`, `overall`.

## Final Output to User

1. Constraints that survived filtering (keep + reclassify)
2. Signal findings (accept + qualify) with severity
3. Noise summary — what was dropped and why
