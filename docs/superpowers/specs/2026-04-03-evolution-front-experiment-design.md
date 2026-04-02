# Evolution-Front Experiment Design

**Goal:** define a small, opt-in experiment that compares a TDD-centered front-half workflow against an evolution-centered front-half workflow for weak prompts.

## Scope

This design covers one workflow experiment only.

Included:

- an opt-in comparison between two front-half orchestration styles
- a shared implementation tail so the comparison stays narrow
- a semi-structured evaluation rubric
- a white-box artifact format for each run
- theory lenses for interpreting results

Excluded:

- replacing existing TDD-oriented workflow content
- replacing older ECC-inspired routines across the harness
- red-team and blue-team phases
- global promotion into default harness policy
- heavy schema or automation work

## Design Summary

The experiment should test whether an evolution-centered front half handles weak prompts better than a TDD-centered front half.

The comparison should stay narrow:

1. compare only the front half first
2. keep the implementation and verification tail as shared as possible
3. use intentionally weak prompts rather than clean tasks
4. preserve process evidence so failures are diagnosable

The baseline is not "bad." It is simply optimized for a different starting condition. A TDD-centered front half works best when the task is already shaped well enough to move quickly into examples, tests, and implementation planning. The evolution-centered front half is intended to help when the prompt is weak, incomplete, misleading, or pointed at the wrong solution.

## Comparison Target

The main question is:

`when the initial prompt is weak, which front half reduces wasted downstream iteration better?`

The experiment is not primarily about:

- which workflow feels smarter
- which workflow uses more subagents
- which workflow can generate more elaborate plans

The experiment is primarily about:

- clarification quality before planning
- breadth before commitment
- early rejection of weak assumptions
- lightweight probing before convergence
- reduction of downstream local-fix thrashing

## Workflow Designs

### Baseline front half

The baseline should stay close to a TDD-centered orchestration style:

1. interpret the prompt into a task statement
2. shape provisional scope and acceptance criteria
3. move quickly toward examples, edge cases, and test-oriented planning
4. hand off into the shared implementation tail

This baseline assumes the prompt is already close enough to reality that early test-shaping is productive.

### Challenger front half

The challenger should use three operational phases:

1. `clarify`
2. `broaden and critique`
3. `probe and freeze`

This is a compressed execution form of the reasoning in [evolution-constraint-control-notes.md](/Users/astery/src/ai/my-agent-harness/docs/evolution-constraint-control-notes.md), not a rejection of that fuller idea.

#### Phase 1: clarify

This phase should:

- treat the prompt as a hypothesis rather than unquestionable truth
- ask about ambiguity, omissions, and possible factual problems
- identify hidden assumptions and unstable acceptance criteria

#### Phase 2: broaden and critique

This phase should:

- generate a small set of plausible interpretations or solution directions
- decompose them into requirement points
- reject contradictions and weak assumptions
- complete obvious missing links needed for an end-to-end path

#### Phase 3: probe and freeze

This phase should:

- run only the smallest probes that are decision-relevant
- discard infeasible or low-confidence paths
- freeze one workable constraint set before implementation planning

The challenger should then hand off into the same implementation tail the baseline uses.

## Why The Challenger Is Compressed

The source note contains more fine-grained reasoning before any later red-team or blue-team work.

For this experiment, the workflow should stay compressed to three operational phases because:

- the first goal is to test the front-half idea, not build a large orchestration tree
- too many subagent handoffs would make the experiment measure coordination overhead
- a smaller challenger is easier to compare fairly against the baseline
- the harness is still in a foundation-first stage and should avoid premature surface-area growth

The full reasoning checkpoints should still exist inside the three phases. The simplification is operational, not conceptual.

## Shared Tail

After the front half finishes, both workflows should use the same downstream style as much as possible.

The shared tail should include:

- implementation planning or test-shaping handoff
- coding work
- verification and review

This keeps the experiment focused on the difference between:

- early commitment under uncertainty
- clarification and broadening before commitment

## Test Design

The experiment should run in two stages.

### Stage A: front-half comparison

Run both workflows on intentionally weak prompts and compare the produced handoff artifacts before implementation starts.

Good prompt types:

- underspecified feature request
- misleading bug report
- prompt that assumes the wrong solution
- request with multiple plausible interpretations
- task with hidden dependency not stated in the prompt
- task with unclear or unstable acceptance criteria

### Stage B: shared-tail comparison

Take a smaller subset of prompts and feed each front-half output into the same downstream implementation tail.

This stage should measure whether the challenger reduces:

- reopen events after implementation starts
- contradictory patch cycles
- local-fix thrashing
- avoidable upstream reinterpretation

## Constraint Packet

Each front-half run should produce one compact handoff artifact called a `constraint packet`.

It should contain:

- task statement
- clarified assumptions
- rejected interpretations
- chosen direction
- open risks
- probe evidence
- draft acceptance criteria

This packet is the main output used for comparison.

## White-Box Evidence

The experiment should preserve process evidence rather than only final summaries.

Each run should keep:

- original prompt
- clarification questions
- alternatives considered
- rejected assumptions
- probe evidence
- final constraint packet
- reopen events during any later implementation run

This makes failures diagnosable. If a run goes wrong, the harness should be able to inspect where the bad assumption entered instead of only seeing a bad outcome.

## Evaluation Rubric

The experiment should start with a semi-structured rubric rather than a heavy numeric scorecard.

For each run, record:

- `ambiguity surfaced early`: `low / medium / high`
- `breadth before commitment`: `low / medium / high`
- `wrong-path avoidance`: `low / medium / high`
- `constraint stability`: `low / medium / high`
- `diagnosability`: `low / medium / high`
- `downstream churn`: `low / medium / high` for shared-tail runs
- `direction changed by front-half work`: `yes / no`
- `notes`: 2-4 lines of concrete evidence

The rubric should be evidence-bearing. Each judgment should point back to preserved artifacts, not only to operator intuition.

## Theory Lenses

The comparison should be interpreted through four theory lenses.

### Decision theory

This lens asks whether the workflow commits well under uncertainty.

Use it to assess:

- whether enough information was gathered before choosing a path
- whether plausible alternatives were considered
- whether the workflow committed too early

### Control theory

This lens asks whether the workflow has a healthy feedback loop when the initial interpretation is wrong.

Use it to assess:

- where correction enters the loop
- whether upstream assumptions can be reopened early
- whether the workflow converges or oscillates through local retries

### Constraint formalization

This lens asks whether the workflow produces a usable constraint set before implementation starts.

Use it to assess:

- whether requirements are explicit
- whether contradictions are removed
- whether hidden dependencies are surfaced
- whether the handoff is stable enough to support implementation

### Observability

This lens asks whether failure is diagnosable.

Use it to assess:

- whether reasons for path selection are visible
- whether bad assumptions can be located
- whether the workflow exposes process evidence rather than only outcome

## Rollout Recommendation

This should begin as an opt-in workflow experiment only.

Recommended rollout:

1. keep the baseline intact
2. add one experimental evolution-front workflow
3. test only the front-half difference first
4. use weak prompts on purpose
5. record white-box evidence for every run
6. promote findings conservatively

The likely long-term outcome is not that evolution replaces TDD entirely. A more plausible outcome is:

- use evolution-front for weak or ambiguous prompts
- use TDD-front when the task is already clear
- keep TDD as the downstream implementation discipline

## Success Criteria

The experiment is successful if it shows, across repeated weak-prompt runs, that the challenger:

- surfaces important ambiguity earlier
- broadens enough before commitment to avoid fragile path selection
- uses cheap probes to remove bad options
- produces more stable constraint packets
- reduces downstream local-fix thrashing
- makes failures easier to diagnose

If these signals do not appear clearly, the harness should not promote the challenger into shared policy yet.
