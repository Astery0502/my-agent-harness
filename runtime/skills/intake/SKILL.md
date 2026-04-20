---
name: intake
description: >
  Preprocess bridge for vague, incomplete, or mixed requests. Use when the user's intent
  is not yet stable or agent-legible — before planning, coding, or research begins.
  Invoke with /intake or when you need to clarify what kind of work this actually is.
  Use this skill whenever a request mixes goal and method, skips motivation, contains
  possible wrong assumptions, or is not yet clear enough to act on directly.
---

# Intake

## Role

The agent handles coding, tool use, and structured workflows well. The weak link is at the
translation layer — converting vague human-level expression into a form the execution layer
can actually consume. This skill patches that gap.

Its job is translation only, not execution. Do not plan. Do not code. Do not route.

---

## Label Enumerations

**REQUEST_ISSUES** — pick all that apply; omit the field entirely if none:

| Label | Meaning |
|---|---|
| `VAGUE` | Intent not specific enough to act on |
| `SCOPE_UNDEFINED` | Boundaries of the problem not set |
| `INCOMPLETE` | Key context missing |
| `GOAL_METHOD_MIXED` | Desired outcome conflated with proposed approach |
| `WRONG_ASSUMPTION` | Request contains an unverified or likely incorrect premise — includes user-reported diagnoses (e.g. "there's a memory leak", "the bug is on line 45") that have not been confirmed through direct evidence such as profiler output, stack traces, or code inspection |
| `CONTRADICTORY` | Internal inconsistency in the request |
| `MOTIVATION_MISSING` | Why is unclear; affects scope and prioritization |

**REQUEST_TYPE** — pick one:

| Label | Meaning |
|---|---|
| `CODING` | Direct code task |
| `SCIENCE` | Conceptual, theoretical, or mathematical |
| `SCIENCE_TO_CODING` | Starts scientific, likely becomes code or simulation |
| `MIXED` | Genuinely hybrid |

---

## Phase 1 — Problem Frame

### Perspective Calibration

Derived from `REQUEST_TYPE` once the frame is built. Applies only to clarifying questions — not to the frame itself.

| REQUEST_TYPE | Lens | Blocking if absent |
|---|---|---|
| `CODING` | `engineer` | runtime/env, constraints (perf, size, compat), failure signature, scope/boundaries |
| `SCIENCE` | `researcher` | hypothesis, evidence quality, baseline/control, success criterion, methodology |
| `SCIENCE_TO_CODING` | `both — researcher first` | research question and evidence first; then reproducibility, output format, simulation fidelity |
| `MIXED` | `both` | identify sub-parts as science vs coding; sequence researcher probes before engineer probes |

Any item in the active Lens row that is absent or unverified in the request is a blocking unknown. The active `Lens` is emitted in the Phase 1 block so the user can correct a misclassification before Phase 2.

### Blocking Derivation

`Blocking` items come from three sources, checked in order of severity:

**1. REQUEST_ISSUES flags** — most severe; corrupt output direction regardless of frame completeness:
- `WRONG_ASSUMPTION`: Phase 2 retrieval and routing point at the wrong target
- `CONTRADICTORY`: Phase 2 output would be incoherent regardless of completeness
- `GOAL_METHOD_MIXED` when the real goal cannot be inferred: route hint and retrieval sketch address the method, not the problem

**2. Structural viability** — type-independent; Phase 2 fields cannot be populated:
- Object of change or study unknown
- Success criterion absent and non-inferrable (Work mode cannot be set)
- Scope so unbounded that retrieval has no search region

**3. Lens criteria** — domain-specific; items in the active Lens row of Perspective Calibration that are absent or unverified.

Collect items from all three sources. If source 1 or 2 fires, resolve those before Lens criteria — a Phase 2 output built on a corrupt foundation is worse than an incomplete one.

---

Read the raw request. Emit this block, then pause:

```
REQUEST_ISSUES: [...]        ← omit field entirely if none
REQUEST_TYPE: ...
Lens: <engineer | researcher | both — researcher first | both>

Goal: <what the user is trying to achieve>
Underlying problem: <if distinct from stated goal; omit if same>
Scope: <object of study and boundaries>
Ambiguity: <informational unknowns — Phase 2 proceeds regardless; omit if none>
Blocking: <from Blocking Derivation — sources 1, 2, 3 in order; omit if none>
```

Then:
- If no `Blocking` field: ask "Does this capture your intent, including the Lens? Correct anything before I continue."
- If `Blocking` is present: ask specifically for the minimum information needed to resolve the blocking items, framed from the active `Lens` — apply the blocking criteria from Perspective Calibration. Do not ask about `Ambiguity` items.

Wait for the user's response.

- If the user explicitly confirms (e.g. "yes", "correct", "proceed") → move to Phase 2.
- Otherwise: synthesize [original request + all user responses so far] into one richer
  problem statement. Re-derive the frame from scratch on this combined input — do not
  patch field by field. Emit the re-derived frame and repeat the ask step above.

This is a loop. Phase 2 only runs on explicit confirmation.

---

## Phase 2 — Work Frame

After the user confirms, emit the confirmed Phase 1 block verbatim (labeled), then emit the Work Frame block:

```
--- Confirmed Problem Frame ---
<echo the final confirmed Phase 1 block as-is>

--- Work Frame ---
Work mode: <understand | inspect | modify | debug | simulate | derive | compare | verify | ...>
Execution posture: <immediate | science-first | context-first>
Likely artifacts: <source files | configs | notebooks | papers | test outputs | ...>
Downstream needs:
  - <neutral observation 1>
  - <neutral observation 2>
  - <neutral observation 3, if needed>

Retrieval sketch:
  Likely source types: <source code | config | docs | papers | test outputs | ...>
  Likely search regions: <module name | directory | domain area | ...>
  Search seeds: <key terms, symbol names, concept names>

Handoff:
  Route hint: <coding | research | retrieval | mixed>
  Coding downstream: <yes | no>
  Context before plan: <yes | no>
```

Then **hard stop**.

---

## Interpretation Policy

When the request is ambiguous, choose the most reasonable bounded interpretation. Record
informational unknowns in `Ambiguity` and blocking unknowns (per Blocking Derivation) in
`Blocking`. Do not over-resolve at preprocess stage.

Phase 1 loops until explicit confirmation. Each iteration synthesizes all accumulated
context (original request + every user response so far) into one combined input and
re-derives the frame from scratch. The re-derive replaces patching — the result is a
coherent frame grounded in the full context, not a corrected version of the prior one.

When the user asserts a specific cause or diagnosis — "there's a memory leak", "the race
condition is in X", "the bug is on line 45" — treat the assertion as unverified unless
the request also supplies evidence (profiler output, stack trace, code). Flag
`WRONG_ASSUMPTION` to surface this, even if the claim might be correct.

---

## Hard Constraints

- Do not generate a plan or task chain
- Do not start coding or edit files
- Do not perform retrieval or file search
- Do not execute routing to another workflow
- Next actions are neutral observations, not instructions
