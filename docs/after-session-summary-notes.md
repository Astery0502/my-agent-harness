# After-Session Summary Notes

This file captures a future cross-project note for an `after-session-summary` skill without implementing the skill yet.

## Why Keep This

`my-agent-harness` is still a base setup repo for Claude Code and Codex. The right level for now is a single note that explains the future skill clearly enough to guide later implementation.

## Purpose

The future `after-session-summary` skill should review one session or a selected group of sessions and turn them into reusable harness learning.

It should not be a glorified recap. Its main job should be:

- extract reusable patterns
- diagnose what kind of problem or success pattern occurred
- map the pattern to a small set of abstract theory lenses
- suggest the smallest worthwhile harness or prompt experiment
- decide whether the lesson is local, provisional, or worth promoting across projects

## Scope

This future skill is meant to be general and cross-project.

It should help answer questions like:

- what repeated failure mode showed up here
- what kind of control or feedback was missing
- whether the fix belongs in prompt wording, workflow, context structure, or verification
- which improvements are likely to generalize beyond this one task

It should not assume the session was about a specific language, framework, or repository.

## Core Principle

The skill should convert:

`session history -> pattern -> theory lens -> mechanism -> experiment -> promotion decision`

That is better than repeatedly doing:

`session history -> rewrite prompts again`

## What It Should Produce

For each analyzed session or session group, the future skill should output six sections.

### 1. Factual Summary

A short account of what actually happened.

This should include:

- user goal
- what the agent tried
- where the workflow slowed down, failed, or succeeded
- what evidence supports the summary

This section should stay descriptive rather than interpretive.

### 2. Pattern Diagnosis

A classification of the main pattern involved.

Useful pattern categories:

- ambiguity or underspecification
- premature convergence
- weak decomposition
- hidden dependency or coupling
- poor observability
- weak verification
- local-fix trap
- coordination failure
- tool misuse
- good stabilizing pattern worth reusing

The point is to identify the class of issue, not just its surface symptoms.

### 3. Theory Mapping

A small mapping from the diagnosed pattern to one to three abstract theory lenses.

The future skill should prefer a stable set of lenses:

- control theory
- systems theory
- decision theory
- constraint solving or formalization
- safety engineering
- observability or diagnosability

Each lens should be translated into plain language rather than jargon.

Examples:

- control theory: missing feedback, unstable loop, weak observability, no correction trigger
- systems theory: hidden coupling, unclear boundaries, dependency leak
- decision theory: decided too early, explored too much, gathered too little information
- constraint solving: requirements were too vague to verify or satisfy cleanly
- safety engineering: dangerous path lacked a circuit breaker or stop gate
- observability: wrong result was visible but wrong process was not

### 4. Harness Implication

The future skill should identify where a useful fix belongs.

Possible target layers:

- prompt wording
- reusable skill
- agent role split
- workflow phase
- gate or policy rule
- shared context format
- observability or logging
- evaluation and verification

This is important because many session problems are not really prompt problems.

### 5. Minimal Experiment

The future skill should recommend the smallest worthwhile change to test next.

Good examples:

- add one explicit reopen rule
- add one probe step before strategy choice
- record assumptions in a simple structured block
- add one review phase for edge cases
- require one evidence-bearing verification summary

Bad examples:

- rewrite the entire harness
- add many new agents at once
- mutate global prompts based on one session

### 6. Promotion Decision

The future skill should decide how broadly the lesson should be applied.

Useful levels:

- `local`: only relevant to this task or repo
- `candidate`: interesting, but needs another trial
- `promote`: general enough to belong in shared harness guidance

Promotion should be conservative. A lesson should not become shared harness policy just because one session made it look smart.

## Recommended Inputs

If implemented later, the skill should accept:

- one session transcript or summary
- multiple related sessions for pattern clustering
- optional user annotations about what felt good or painful
- optional selected artifacts such as plans, logs, or review notes

## Recommended Output Shape

If implemented later, a clean output format would be:

1. session scope
2. factual summary
3. diagnosed pattern
4. theory lens mapping
5. likely root cause
6. harness implication
7. smallest worthwhile experiment
8. promotion decision
9. confidence
10. open doubts

## Theory Guide

The future skill should keep theory practical and small.

### Control Theory

Use when the session shows:

- repeated retries with no convergence
- no trigger for revisiting assumptions
- weak feedback loops
- poor measurement of progress or failure

Likely implications:

- add a reopen rule
- add a feedback checkpoint
- add a stability gate before implementation
- improve observability of state transitions

### Systems Theory

Use when the session shows:

- poor decomposition
- unclear ownership
- hidden dependencies
- coupling between phases or components

Likely implications:

- split roles or phases
- clarify boundaries
- separate concerns in workflow or context

### Decision Theory

Use when the session shows:

- exploration without payoff
- overconfidence under uncertainty
- early commitment to one path
- insufficient evidence before deciding

Likely implications:

- probe before commit
- compare options explicitly
- define what evidence is enough to decide

### Constraint Solving

Use when the session shows:

- vague requirements
- unstable acceptance criteria
- hard-to-test outputs
- confusion between goal and implementation

Likely implications:

- make constraints explicit
- separate requirement from solution
- refine acceptance criteria and tests

### Safety Engineering

Use when the session shows:

- obviously bad paths were allowed to continue
- risky work lacked escalation
- harmful design ideas were patched rather than blocked

Likely implications:

- add stop conditions
- add circuit breakers
- add explicit rejection rules for bad designs

### Observability

Use when the session shows:

- wrong result but invisible process
- lots of guessing during debugging
- poor evidence about where failure entered the workflow

Likely implications:

- record state changes
- capture reason and evidence for major decisions
- make the process more white-box

## Promotion Rules

The future skill should only recommend promotion into the shared harness when at least one of these is true:

- the same pattern appeared across multiple sessions
- the failure caused expensive rework
- the lesson is model-agnostic
- the lesson improves diagnosability
- the fix is simple enough to maintain

## Anti-Patterns

The future skill should explicitly guard against:

- treating every session as proof that the harness needs big changes
- producing vague advice like "improve the prompt"
- adding theory language without operational implications
- overfitting the harness to one project or one model
- confusing an attractive explanation with a validated mechanism

## Relationship To Existing Notes

This note pairs well with [evolution-constraint-control-notes.md](/Users/astery/src/ai/my-agent-harness/docs/evolution-constraint-control-notes.md).

That note is about how a future workflow might structure an individual task.

This note is about how future session review might improve the harness itself across tasks and projects.

## Practical Future Use

If implemented later, the future skill should probably be used:

- after a notably good or bad session
- after a cluster of similar sessions
- before changing shared prompts or harness rules
- when deciding whether a local trick deserves promotion into shared practice

## Bottom Line

The future `after-session-summary` skill should act as a cross-project learning layer.

Its value is not in retelling what happened. Its value is in turning sessions into reusable engineering guidance with just enough theory to improve prompts, workflows, gates, and observability in a disciplined way.
