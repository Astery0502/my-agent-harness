# TDD Workflow

## Purpose

This skill guides the baseline front half for clearer prompts. It assumes the request is already close enough to reality that we can move quickly from interpretation into examples, edge cases, and test-oriented planning.

Scope boundary: this skill stops at the shared constraint packet handoff. It does not cover downstream implementation, coding, or verification beyond the handoff point.

## Inputs

- requested behavior
- target files
- verification command
- prompt clarity level

## Baseline Flow

1. Interpret the prompt into a task statement.
2. Shape provisional acceptance criteria.
3. Move quickly into examples and edge cases.
4. Use those examples to guide test-oriented planning.
5. Emit the shared constraint packet handoff.
6. Let downstream implementation take over from there.

## Required Output

The required output of the baseline front half is the shared constraint packet handoff, meaning the shared `constraint packet` deliverable. It should capture the chosen direction, the provisional acceptance criteria, and the assumptions the downstream implementation should rely on.

## Outputs

- task statement
- provisional acceptance criteria
- examples and edge cases
- shared constraint packet handoff
- downstream implementation start point

## Planned Sections

- baseline purpose
- interpretation
- examples
- edge cases
- handoff boundary
- downstream ownership, not this front-half skill
