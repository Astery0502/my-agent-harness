# Evolution-Front Experiment

This document records the current state of the opt-in evolution-front workflow experiment in `my-agent-harness`.

## Purpose

The experiment compares two front-half workflows for weak prompts:

- baseline `/plan`, which stays close to a TDD-oriented framing path
- challenger `/evolution-plan`, which uses `clarify -> broaden and critique -> probe and freeze`

The goal is narrow: test whether the challenger reduces wasted downstream iteration when the prompt is weak, incomplete, misleading, or pointed at the wrong solution.

## What Changes Between The Two Paths

The shared downstream tail stays as similar as possible.

The main difference is in the front half:

- the baseline moves quickly toward task framing, examples, edge cases, and a shared `constraint packet`
- the challenger treats the request as a hypothesis, builds an evidence chain, freezes only after a small probe-and-freeze step, and then emits the same shared downstream handoff

The experiment is not primarily about:

- which workflow feels smarter
- which workflow uses more subagents
- which workflow produces the most elaborate planning prose

## Evidence Model

The challenger keeps a white-box record through:

- an `evidence chain record`
- a smaller frozen `constraint packet`
- explicit `reopen_trigger` recording before downstream work starts

The baseline is intentionally lighter. The comparison is therefore about whether the challenger's extra front-half discipline pays for itself by reducing downstream correction cost.

## Method

The experiment currently uses two stages.

### Stage A

Run baseline and challenger on the same intentionally weak prompt and compare the front-half artifacts before implementation starts.

Use this stage to inspect:

- ambiguity surfaced early
- breadth before commitment
- wrong-path avoidance
- evidence-chain completeness
- diagnosability

### Stage B

Take one weak prompt, derive baseline and challenger handoffs, then run both through the same small downstream implementation style in isolated temp repos.

Use this stage to inspect:

- downstream churn
- reopen pressure
- implementation simplicity
- verification outcome
- alignment with repo constraints

## Completed Trials

### Trial Matrix

| ID | Stage | Weak Prompt Class | Short Prompt Shape | Result |
|----|-------|-------------------|--------------------|--------|
| A1 | Stage A | wrong solution surface | add `/repair-sync` | challenger better |
| A2 | Stage A | misleading bug report | make `doctor.sh` auto-heal | challenger better |
| B1 | Stage B | wrong solution surface | implement `/repair-sync` through shared tail | challenger better |
| B2 | Stage B | hidden dependency | add `ready.sh` for machine readiness | challenger better |
| B3 | Stage B | unstable acceptance criteria | add `sync-dev.sh` for a good default dev setup fast | challenger better |

### Trial Notes

#### A1: Wrong Solution Surface

The weak prompt proposed a likely-wrong command surface up front. The baseline stayed closer to that surface, while the challenger more clearly translated the request into "improve or wrap the existing local ops workflow."

Lesson:

- the challenger is better at rejecting a bad implementation suggestion before coding begins

#### A2: Misleading Bug Report

The prompt framed an intentional contract boundary as a bug by asking `doctor.sh` to auto-heal drift and malformed state. The challenger preserved the explicit split between diagnosis and repair more cleanly.

Lesson:

- the challenger is better at separating workflow pain from actual contract breakage

#### B1: `/repair-sync`

Both paths reached a working wrapper around existing local ops scripts. The baseline needed one real reopen during downstream implementation when malformed-state safety was checked. The challenger reached the repo-aligned behavior directly.

Lesson:

- better front-half framing reduced downstream correction cost, not just front-half confusion

#### B2: `ready.sh`

The hidden dependency was that "ready" depended on `doctor.sh`, not just installed state. The baseline first equated `installed` with `ready`, then had to reopen once drift behavior exposed the missing health dependency. The challenger modeled installed-plus-healthy from the start.

Lesson:

- the challenger is better at surfacing hidden operational dependencies before code crystallizes around the wrong abstraction

#### B3: `sync-dev.sh`

The unstable acceptance criteria were "good default dev setup" and "fast." The baseline initially optimized for speed and chose the `minimal` profile, which stayed healthy but omitted the runtime modules. It then needed a reopen to move to `full`. The challenger made that tradeoff explicit and chose `full` immediately.

Lesson:

- the challenger is better at stabilizing ambiguous success criteria before implementation starts making silent tradeoffs

## Current Read

What the completed trials support:

- the challenger is repeatedly better on weak prompts that contain framing traps
- the extra front-half work can pay off in Stage B, not just Stage A
- the main benefit so far is reduced reinterpretation and fewer late corrections

What the completed trials do not yet support:

- replacing the default baseline workflow
- turning the experiment into a stricter subagent-managed system
- promoting the experiment into policy without more evidence

## Current Recommendation

Keep evolution-front as an opt-in experiment.

Do:

- preserve the current prototype
- use it selectively for weak or ambiguous prompts
- keep recording white-box evidence for future runs

Do not do yet:

- make it the default path
- grow it into a strict multi-subagent orchestration tree
- add heavy automation around trial tracking

The evidence is now strong enough to say the idea is promising. It is still not strong enough to justify a larger orchestration system.

## How To Continue Later

If more evidence is wanted, the next best trial classes are:

- hidden dependency with a different repo area
- unstable acceptance criteria with a different operational tradeoff
- multiple plausible interpretations in a non-local-ops workflow

When running future trials:

1. keep the prompt intentionally weak
2. keep the downstream implementation tail small
3. isolate each Stage B run in temp repos
4. record whether baseline or challenger needed a real reopen
5. prefer a short trial note over relying on memory

## Related Files

- [experiment design](/Users/astery/src/ai/my-agent-harness/.worktrees/codex-evolution-front-v1/docs/superpowers/specs/2026-04-03-evolution-front-experiment-design.md)
- [evidence chain model](/Users/astery/src/ai/my-agent-harness/.worktrees/codex-evolution-front-v1/docs/evidence-chain-model.md)
- [experiment results design](/Users/astery/src/ai/my-agent-harness/.worktrees/codex-evolution-front-v1/docs/superpowers/specs/2026-04-03-evolution-front-results-design.md)
