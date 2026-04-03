# Evidence Chain Model

This document defines a lightweight evidence-chain model for turning weak requests into provable engineering or research work.

It is meant to support closed-loop constraint solving without forcing the solver to externalize every intermediate thought.

The model should be used as a sparse external record:

- keep internal reasoning flexible
- externalize only decision-critical transformations
- preserve enough state to reopen the right upstream link when later work fails

## Core Idea

The process is not only a sequence of reasoning phases. It is a chain of transformed states.

The minimum chain is:

`request_raw -> clarified_request -> candidate_strategies -> constraints -> constraints_refined -> evidence_chain -> probe_results -> frozen_decision -> verification_target -> reopen_triggers`

The point of the model is:

- traceability from request to engineering decision
- evidence-bearing convergence rather than unsupported preference
- precise reopening when downstream work exposes a broken upstream link

## Externalization Rule

Do not force full explicit reasoning.

Use:

- internal free reasoning within each phase
- minimal structured outputs between phases

Each phase should record only:

- input state
- output state
- evidence for the transformation
- rejected paths when decision-relevant
- reopen conditions when known

## Shared State Shape

```yaml
request_raw:
clarified_request:
suspect_claims:
candidate_strategies:
constraints:
rejected_constraints:
conflicts:
dependency_gaps:
probe_plan:
probe_results:
frozen_decision:
verification_target:
reopen_triggers:
trace_links:
```

## Minimum Required Schema

The shared state shape above is the full conceptual model.

In practice, most runs should emit a smaller `minimum required evidence chain` so the workflow stays lightweight and comparable across runs.

These fields are `required` for a normal evolution-front run:

```yaml
clarified_request:
suspect_claims:
candidate_strategies:
accepted_constraints:
rejected_constraints:
probe_evidence:
frozen_decision:
verification_target:
reopen_trigger:
```

These fields are `optional`, and should be used only when they materially help the decision or later reopening:

```yaml
request_raw:
conflicts:
dependency_gaps:
probe_plan:
trace_links:
```

This minimum schema exists for three reasons:

- keep the external record small enough not to suppress solver quality
- make different experiment runs comparable
- give downstream planning or execution a stable handoff contract

## Required Field Meaning

### `clarified_request`

The best current statement of what problem is actually being solved after ambiguity and suspicious claims have been examined.

### `suspect_claims`

Claims from the original request that may be false, incomplete, hidden, or otherwise unreliable.

### `candidate_strategies`

The small set of plausible paths considered before commitment.

### `accepted_constraints`

The constraints that survived critique and are now treated as the active basis for implementation or experimentation.

### `rejected_constraints`

The discarded constraints or strategy assumptions that were explicitly ruled out and why they were ruled out.

### `probe_evidence`

The smallest decision-relevant checks that were run and what they showed.

### `frozen_decision`

The currently selected path after clarification, broadening, critique, completion, and probes.

### `verification_target`

The concrete result that would count as success for the frozen decision.

### `reopen_trigger`

The condition that should force the workflow to reopen an upstream link instead of continuing local fixes.

## Minimum Artifact Example

```yaml
clarified_request: "Build a local experiment workflow for weak prompts before implementation planning."
suspect_claims:
  - claim: "The user's first suggested solution is the right abstraction."
    reason_suspect: "The prompt may describe a preferred solution rather than the real problem."
candidate_strategies:
  - "TDD-centered baseline front half"
  - "Evolution-centered front half with evidence chain"
accepted_constraints:
  - "The experiment must stay opt-in."
  - "The shared implementation tail should stay the same for both workflows."
rejected_constraints:
  - constraint: "Replace the default planning path immediately."
    reason: "Too much surface-area change for a first experiment."
probe_evidence:
  - probe: "Compare front-half artifacts before implementation."
    result: "Keeps the A/B comparison narrow and interpretable."
frozen_decision: "Run an opt-in evolution-front experiment with a shared downstream tail."
verification_target: "Repeated weak-prompt trials show lower downstream churn and better diagnosability."
reopen_trigger: "If downstream failures cannot be traced cleanly to a justified upstream chain, reopen the missing or broken link."
```

## Phase A: Intake / Hypothesis Sanitization

**Input**

- `request_raw`

**Purpose**

- treat the request as a noisy hypothesis rather than truth
- clarify ambiguity
- challenge suspicious, incomplete, or factually weak claims

**Output**

```yaml
clarified_request:
suspect_claims:
  - claim:
    reason_suspect:
uncertainties:
  - question:
    why_it_matters:
trace_links:
  - from: request_raw
    to: clarified_request
    evidence: clarification or contradiction found
```

## Phase B: Divergent Completion

**Input**

- `clarified_request`
- `suspect_claims`
- `uncertainties`

**Purpose**

- widen the search space before commitment
- generate plausible strategy families
- fill blind spots the requester did not specify

**Output**

```yaml
candidate_strategies:
  - id:
    description:
    assumptions:
    expected_upside:
    main_risk:
trace_links:
  - from: clarified_request
    to: candidate_strategies
    evidence: alternative formulations generated
```

## Phase C: Constraint Extraction

**Input**

- `candidate_strategies`

**Purpose**

- decompose strategies into concrete engineering or research constraints
- prepare later mapping to implementation, experiments, tests, or interfaces

**Output**

```yaml
constraints:
  - id:
    statement:
    type: objective|invariant|interface|resource|risk|test
    derived_from_strategy:
    likely_owner_unit:
trace_links:
  - from: candidate_strategies
    to: constraints
    evidence: decomposition into concrete requirements
```

## Phase D: Orthogonal Critique

**Input**

- `constraints`

**Purpose**

- challenge constraints from multiple angles
- remove contradictions, weak assumptions, and low-feasibility requirements
- begin convergence through filtering

Useful critique axes:

- factual correctness
- logical consistency
- dependency completeness
- feasibility
- safety or risk
- cost and time

**Output**

```yaml
rejected_constraints:
  - constraint_id:
    rejection_reason:
conflicts:
  - conflict:
    involved_constraints:
    resolution:
constraints_refined:
  - id:
    revised_statement:
trace_links:
  - from: constraints
    to: constraints_refined
    evidence: critique and conflict resolution
```

## Phase E: Chain Completion

**Input**

- `constraints_refined`
- `conflicts`

**Purpose**

- make the end-to-end chain complete
- identify missing dependencies and missing logical links
- ensure the refined requirements can actually support a verifiable path

**Output**

```yaml
dependency_gaps:
  - gap:
    why_blocking:
completion_patches:
  - patch:
    fills_gap:
evidence_chain:
  objective:
  assumptions:
  accepted_constraints:
  dependency_links:
  planned_verification_path:
trace_links:
  - from: constraints_refined
    to: evidence_chain
    evidence: missing links completed
```

## Phase F: Probe

**Input**

- `evidence_chain`

**Purpose**

- test only decision-relevant uncertainty
- reject infeasible paths cheaply before full implementation
- produce a supported, frozen decision

Good probe types:

- tiny code spike
- API or interface check
- feasibility script
- documentation or literature check
- toy experiment

**Output**

```yaml
probe_plan:
  - probe_id:
    target_uncertainty:
    cheapest_test:
probe_results:
  - probe_id:
    result:
    implication:
frozen_decision:
  chosen_path:
  chosen_constraints:
  rejected_paths:
verification_target:
reopen_triggers:
  - condition:
    reopen_link:
trace_links:
  - from: evidence_chain
    to: frozen_decision
    evidence: probe-supported convergence
```

## Reopen Event

When execution fails, the workflow should not restart blindly.

It should reopen the specific broken link:

```yaml
reopen_event:
  failure_signal:
  broken_link:
  phase_to_reopen: A|B|C|D|E|F
  reason:
  next_action:
```

This is what makes the loop closed. The system should revisit the nearest broken upstream link rather than thrash in downstream patches.

## Reopen Policy

The reopen policy defines when downstream work is no longer allowed to continue with local patching alone.

The goal is to prevent oscillation, not to force unnecessary restarts.

### Reopen Triggers

A run should reopen an upstream link when one or more of these conditions appear:

- repeated downstream fixes do not improve the verification signal
- new evidence contradicts an accepted constraint
- the current implementation path depends on an assumption that was never justified in the evidence chain
- a probe result was overruled informally instead of being resolved explicitly
- the team cannot explain why the current path is still the right one

### Default Reopen Mapping

Use the nearest broken link first:

- reopen `A` when the clarified request is probably wrong
- reopen `B` when the solution space was too narrow too early
- reopen `C` when the constraints were extracted badly
- reopen `D` when contradictions or bad assumptions were not filtered out
- reopen `E` when the end-to-end chain has a missing dependency or missing logical link
- reopen `F` when the probes were weak, missing, or misinterpreted

### Local-Patch Limit

Local patching is still allowed, but only under control.

It should stay local only when:

- the failure is clearly an implementation defect inside an otherwise justified chain
- the verification target remains stable
- no accepted constraint needs to change

The workflow should stop local patching and reopen upstream when:

- the same class of fix has already failed once or twice
- the patch requires silently changing requirements
- the patch changes system behavior that the current evidence chain does not justify

### Reopen Record

When a reopen happens, record:

```yaml
reopen_event:
  failure_signal:
  broken_link:
  phase_to_reopen: A|B|C|D|E|F
  reason:
  next_action:
```

This should be treated as normal control behavior, not as failure of the whole workflow.

## Probe Budget

The probe budget defines how much uncertainty reduction work is justified before freezing a path.

The point is to use decision theory well:

- probe when uncertainty can change the decision
- avoid probing when the result would not alter the chosen path

### Probe Selection Rule

Run a probe only if all three are true:

1. the uncertainty is decision-relevant
2. the probe is cheaper than committing to the wrong path
3. the result would likely change acceptance, rejection, or ranking of a candidate strategy

### Default Budget

For a normal evolution-front run, the default budget should stay small:

- `0-2` lightweight probes per run
- each probe should target one uncertainty only
- each probe should be cheaper than full implementation or broad redesign

Good probe forms:

- tiny code spike
- API or interface check
- feasibility script
- targeted documentation or literature check
- toy experiment

Bad probe forms for a normal run:

- building half the solution before deciding
- broad exploratory work with no decision target
- collecting evidence that will not change the path

### Freeze Rule

Freeze a path when:

- the leading strategy is supported by the current evidence chain
- the remaining uncertainty is not decision-critical
- the verification target is concrete enough to detect failure later
- a reopen trigger has been recorded

Do not freeze when:

- the leading strategy still depends on unjustified claims
- multiple candidate strategies remain live for unresolved high-impact reasons
- the verification target is too vague to detect wrong convergence

### Probe Record

The minimum external record for probing should include:

```yaml
probe_evidence:
  - probe:
    target_uncertainty:
    result:
    implication:
```

This keeps probes tied to decisions rather than turning them into generic research notes.

## Minimal Artifact Policy

For most real tasks, the model should keep two external artifacts:

1. `evidence chain record`
The fuller white-box state for the evolution workflow.

2. `constraint packet`
A smaller frozen handoff derived from the evidence chain and used by downstream implementation or experiment execution.

The `constraint packet` is useful for handoff, but it should not replace the evidence chain record.

## Applicability

This model is not limited to software coding.

It can also support:

- research idea to experiment design
- investigation to diagnosis workflow
- policy or architecture decisions that need traceable justification

The implementation target changes by domain, but the closed-loop evidence logic stays the same.
