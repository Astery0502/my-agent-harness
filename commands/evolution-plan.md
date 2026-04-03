# /evolution-plan

## Role

This is the experimental entrypoint for the evolution-front workflow.

## Dispatch

- `/evolution-plan` dispatches to `agents/evolution-planner.md`.
- It consults `skills/evolution-front-experiment/SKILL.md` before committing to the experiment path.
- It keeps the flow opt-in and distinct from the default `/plan` baseline.

## Handoff Contract

The command builds an evidence chain record before freezing a handoff. The evidence chain record is the primary artifact for this experimental entrypoint.

It records `probe_evidence` whenever probes are used and `reopen_event` whenever a reopen is triggered.

The frozen output is the shared `constraint packet` handoff, not a replacement for the evidence chain record.

## Experiment Shape

This command exists to support the three operational phases, preserve white-box evidence, and freeze a constraint set only after the documented freeze rule has been satisfied.
