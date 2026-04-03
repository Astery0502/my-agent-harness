# /evolution-plan

## Role

This is the explicit experimental entrypoint for the evolution-front workflow.

## Dispatch

- `/evolution-plan` dispatches to `agents/evolution-planner.md`.
- It consults `skills/evolution-front-experiment/SKILL.md` to run the experiment path.
- It keeps the flow opt-in and distinct from the default `/plan` baseline.

## Handoff Contract

The command builds an evidence chain record before freezing the shared downstream implementation tail handoff. The evidence chain record is the primary artifact for this experimental entrypoint.

It records `probe_evidence` whenever probes are used.

It records `reopen_trigger` in the evidence chain record before any reopen, and records `reopen_event` only if that reopen actually happens.

The frozen output is the shared `constraint packet` handoff, not a replacement for the evidence chain record.

## Experiment Shape

This command exists to support the three operational phases, preserve white-box evidence, and freeze a constraint set only after the documented freeze rule has been satisfied.
