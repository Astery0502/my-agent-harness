# Planning Artifacts

This file defines the artifact schema for `/plan`.

## Evolving Constraint Language

The constraint packet is not just a handoff template — it is an instance of the *evolving constraint language*: a unified descriptive encoding of requirements, features, modules, and functions that persists across the full iteration lifecycle. Its design intent is machine-readability: another LLM should be able to read a frozen packet and assemble implementation from it directly, without re-reading the planning conversation. The closed-loop flow encoded in the language is itself machine-consumable: feeding the complete lifecycle into an LLM should allow it to automatically generate prompts for the next iteration, greatly reducing development workload over time. Each iteration increment accumulates a traceable history (`delta_from_prior`), so the language evolves with the plan rather than being discarded at handoff.

## Conceptual Model

Requirements-to-code is fundamentally a constraint-solving process: each ARI is a constraint, the plan converges multiple feasible routes to a strategy, and code generation outputs a solution that satisfies the constraint set. If the solution fails, the constraint set needs re-evaluation — re-enter the lifecycle at the nearest broken upstream step. This is why every reopen is a constraint re-entry, not a restart.

## Constraint Packet as Context Bus

The constraint packet is the lifecycle's shared context bus. It is not assembled
at the end of planning — it is initiated at step A and updated forward through
each step. This makes the state of constraints visible at every checkpoint,
so a failure can be traced to the step where the bad assumption entered the chain.

The packet carries an `iteration` counter. On first run it is 0. Each reopen
or re-entry increments it. The `delta_from_prior` field records what changed
from the prior iteration so that a looping plan accumulates a traceable history
rather than overwriting its prior state.

The frozen packet must stay operational rather than prose-only. If the packet
cannot tell another model how to assemble the next implementation slice or how
to prompt the next iteration, the language has not been fully encoded.

## Agent Contract

- Keep the packet machine-readable and stable across prompts, templates, and step handoffs. A later agent should not have to guess whether two field names mean the same thing.
- Treat the packet as the primary shared state. Another agent should be able to continue from the packet without re-reading the whole planning conversation.
- Record actual changes on re-entry in `delta_from_prior` rather than silently overwriting prior conclusions; the loop is supposed to stay traceable.

See `assets/constraint-packet.md` for the canonical template used as the
terminal handoff artifact.

## Shared Fields

- `iteration`: integer starting at 0. Incremented on each reopen or re-entry into the lifecycle.
- `delta_from_prior`: what changed from the prior iteration's constraint packet. Empty on iteration 0.
- `mode`: active planning mode, either `plan-e` or `plan-h`.
- `request_invariant`: stable statement of the original request that must remain preserved through planning.
- `focus`: the primary problem slice the plan is optimizing for.
- `non_goals`: nearby work that is explicitly out of scope.
- `unknowns`: unresolved facts or assumptions that still affect risk.
- `challenged_assumptions`: input assumptions questioned during preprocess.
- `candidate_routes`: bounded set of plausible planning routes considered during expansion.
- `actionable_requirements`: the surviving ARI set after step D (and F/G for plan-h). Each ARI has a statement, acceptance criterion, parent route, and testable boolean outcome. This is the primary constraint set that drives the rest of the plan.
- `rejected_aris`: ARIs removed during critique/filter, with rejection reason per ARI.
- `conflict_notes`: conflicts discovered during critique/filter, with the resolution rationale for each retained choice.
- `accepted_constraints`: constraints derived from the surviving ARI set after step D.
- `chosen_route`: the surviving route selected for completion.
- `why_this_route`: brief justification for route selection.
- `task_chain`: sequencing artifact over the surviving `actionable_requirements`. Derived from ARIs — not defined independently. Execution-facing.
- `imports`: dependencies, approvals, or external inputs required by the task chain.
- `risks`: major risks that remain after route selection.
- `verification_target`: the concrete verification surface that should prove the task chain is satisfied.
- `draft_acceptance_criteria`: execution-facing acceptance criteria derived from the surviving ARIs and task chain.
- `freeze_condition`: the condition under which the reasoning-side plan is stable enough to hand off.
- `code_assembly_schema`: structured mapping from the frozen constraints to implementation units, tests, and touch points so another model can assemble code from the packet without reconstructing the plan from prose.
- `next_iteration_prompt`: the carry-forward prompt to use if execution yields new evidence or a reopen condition fires.
- `reopen_target`: the specific upstream step (A/B/C/D) to return to when a reopen condition fires. Not "reopen" generically — a named step so the correction is surgical rather than a full restart.

## `plan-h` Fields

- `probes`: the smallest useful checks run against surviving ARIs.
- `probe_results`: outcomes of those checks.
- `surviving_requirements`: the ARI subset that passed feasibility probing at step F.
- `killed_aris`: ARIs discarded at step F due to failed feasibility, with failure reason per ARI.
- `red_attacks`: boundary problems and failure edges enumerated by Red per surviving ARI.
- `blue_verdicts`: Blue's resolution verdict per Red attack — `resolved` or `mitigated` — with rationale.
- `reopen_triggers`: conditions that should reopen an upstream planning step.
- `review_decision`: final freeze decision presented for human approval.
- `frozen_task_chain`: the task chain as frozen for execution handoff.
- `execution_ready`: boolean indicating whether execution may begin.
- `reopen_conditions`: explicit conditions under which the frozen chain must be reopened.

## Freeze Criteria

The plan is good enough to freeze only when:

- each ARI in the `task_chain` has a corresponding acceptance criterion that forms a testable boolean outcome — test coverage must be complete relative to the surviving feature set (test-driven development is the foundational execution paradigm; tests must fully correspond to features before handoff)
- the request invariant is preserved
- at least one route is chosen and justified
- the surviving `actionable_requirements` set is coherent and dependency-complete
- the `task_chain` sequences the surviving ARIs without gaps
- major risks are named
- the `verification_target` and `draft_acceptance_criteria` still correspond to the surviving ARI set
- remaining unknowns are acceptable for execution handoff
- `code_assembly_schema` is specific enough that another model could assemble the next implementation slice directly from the packet
- `next_iteration_prompt` is ready for reuse if the chain re-enters with downstream evidence
- for `plan-h`, probes and Red-Blue adversarial do not force reopen, or the surviving ARI set remains sufficient to satisfy the request invariant

Freeze does not mean the work is solved. It means execution can begin without hidden planning gaps dominating the next phase.

## Reopen Criteria

The plan must be reopened when:

- probes invalidate enough ARIs that the surviving set cannot satisfy the request invariant
- a Red-Blue attack cannot be honestly marked `resolved` or `mitigated`
- a critical assumption was unsupported
- a required dependency was omitted
- downstream work shows that the frozen task chain relied on a broken upstream link

Implementation failures (failed tests, broken assumptions discovered during coding) are valid reopen triggers. The failing evidence becomes the input to the nearest broken upstream step — target the `reopen_target` step. On re-entry, increment `iteration` and record `delta_from_prior` before running the lifecycle again.

Reopen should target the nearest broken upstream step rather than restarting the full planning chain by default. Use full-loop re-entry at step A only when the failure is scope-level, cannot be attributed to a specific upstream step, or has become a materially new Raw Request.
