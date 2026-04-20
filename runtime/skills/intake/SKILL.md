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

Read the raw request. Emit this block, then pause:

```
REQUEST_ISSUES: [...]        ← omit field entirely if none
REQUEST_TYPE: ...

Goal: <what the user is trying to achieve>
Underlying problem: <if distinct from stated goal; omit if same>
Scope: <object of study and boundaries>
Ambiguity: <informational unknowns — Phase 2 proceeds regardless; omit if none>
Blocking: <unknowns that would leave Phase 2's retrieval sketch and handoff empty; omit if none>
```

Then:
- If no `Blocking` field: ask "Does this capture your intent? Correct anything before I continue."
- If `Blocking` is present: ask specifically for the minimum information needed to resolve the blocking items. Do not ask about `Ambiguity` items.

Wait for the user's response. Synthesize the original request and the user's response into a single richer problem statement. Re-derive the problem frame from scratch on this combined input — do not patch the prior frame field by field. Emit the re-derived frame (without a confirmation prompt), then proceed directly to Phase 2.

---

## Phase 2 — Work Frame

After the user confirms, emit this block:

```
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
informational unknowns in `Ambiguity` and unknowns that would empty the retrieval sketch
or handoff in `Blocking`. Do not over-resolve at preprocess stage.

After the user responds, synthesize original request + response into one combined input
and re-derive the frame from scratch. The re-derive replaces patching: it produces a
coherent frame grounded in the fuller context, not a corrected version of the prior one.

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
