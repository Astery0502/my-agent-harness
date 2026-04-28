---
name: intake
description: >
  Clarify non-coding or domain-level intent into a coding-facing downstream prompt.
  LOAD ONLY when the user explicitly invokes /intake. Do not auto-load for any other reason.
---

# Intake

## Role

Intake is a domain-to-code bridge. It clarifies a user's idea before that idea becomes coding work.

Its job is to translate from:

```text
I want to understand / prove / compare / automate / simulate / decide something.
```

into:

```text
What computational artifact, input, output, validation method, and project context would serve that goal?
```

The product of this skill is a confirmed idea frame plus a coding-facing downstream prompt. It is not a plan and not execution.

---

## Front-door gate

Use this skill only when the request begins outside ordinary software-engineering work and may need to become software work. Skip intake when the request already identifies an artifact or symptom, desired change or investigation target, and safe next action.

Good intake cases:

- Science or research intent that may become a simulation, notebook, benchmark, or analysis pipeline
- Product or workflow intent that may become a script, CLI, app feature, test harness, or automation
- Conceptual or analytical intent where the computational target is not yet stable
- Requests with a user-stated premise that should become a hypothesis before code is changed
- Mixed domain/coding requests where the domain goal must be stabilized before planning or implementation

Do not use intake for ordinary coding requests:

- Fix/debug/refactor/test/implement code
- Inspect a file, module, repository, or error
- Add a feature with a stable software goal
- Verify a change or run checks
- Choose between implementation routes for an already-coding task

If explicitly invoked on an ordinary coding request, say briefly that the request is already coding-facing and should proceed through normal coding/planning/verification instead. Do not run the full intake flow.

---

## Labels

**REQUEST_ORIGIN** — pick one:

| Label | Meaning |
|---|---|
| `SCIENCE` | Scientific, mathematical, theoretical, or simulation intent |
| `RESEARCH` | Investigation, evidence gathering, comparison, or reproduction intent |
| `ANALYSIS` | Data/log/result interpretation or measurement intent |
| `WORKFLOW` | Manual process, operational flow, or automation intent |
| `PRODUCT` | User-facing, stakeholder, UX, or product outcome intent |
| `CONCEPTUAL` | Idea exploration, taxonomy, decision framing, or explanation intent |
| `MIXED` | Multiple origins are genuinely entangled |

**PREMISE_STATUS** — pick one for any user-stated claim about cause, mechanism, or desired method:

| Label | Meaning |
|---|---|
| `EVIDENCE_BACKED` | Evidence is supplied or already established in the request |
| `ACCEPTED_AS_GIVEN` | The premise is a user requirement or definition, not something to verify |
| `UNVERIFIED` | The premise may be true but evidence has not been supplied |
| `CONTRADICTED` | The premise conflicts with supplied evidence or established facts |
| `INCOMPLETE` | The premise lacks enough context to interpret |
| `NONE` | No material premise is stated |

**CODING_NEED** — pick one:

| Label | Meaning |
|---|---|
| `YES` | The confirmed idea likely needs code/config/notebook/tests/simulation/repo work |
| `NO` | The confirmed idea is non-coding and should not be translated into coding work |
| `UNCERTAIN` | Coding may or may not be needed; the next workflow must decide after context |

---

## Phase 1 — Idea Frame

Clarify the domain/intention layer before discussing implementation. Ask:

```text
What is the user actually trying to understand, prove, compare, automate, simulate, or decide?
```

Do not ask for files, libraries, architecture, or implementation route unless that information is necessary to stabilize the idea.

Emit this block, then pause:

```text
--- Idea Frame ---
REQUEST_ORIGIN: <SCIENCE | RESEARCH | ANALYSIS | WORKFLOW | PRODUCT | CONCEPTUAL | MIXED>

Domain goal: <real-world/scientific/product/workflow/conceptual outcome>
Object/process: <thing being studied, transformed, compared, automated, or decided>
User-stated premise: <claim, diagnosis, mechanism, or proposed method; omit if none>
PREMISE_STATUS: <EVIDENCE_BACKED | ACCEPTED_AS_GIVEN | UNVERIFIED | CONTRADICTED | INCOMPLETE | NONE>
Success evidence: <what observation/result would satisfy the domain goal>
Ambiguity: <useful non-blocking unknowns; omit if none>
Blocking: <idea-level unknowns that must be answered before coding translation; omit if none>
```

### Blocking rule

A missing detail is blocking only if its answer would change at least one of:

1. Whether coding is needed at all
2. The computational target
3. The required input
4. The expected output
5. The validation method
6. The domain goal itself

Do not mark ordinary implementation details as blocking. File locations, library choices, code architecture, and exact implementation route usually belong to project inspection or planning, not intake.

Missing origin, premise, or coding-need label detail blocks only when its absence prevents forming a safe Phase 2 Work Frame. Otherwise preserve it as `Ambiguity`. Treat `CONTRADICTED` premises as blocking. Treat `UNVERIFIED` premises as non-blocking when they can be carried forward neutrally without accepting them as fact.

Then:

- If `Blocking` is absent: ask `Does this capture your idea? Correct anything before I translate it into a coding-facing prompt.`
- If `Blocking` is present: ask only for the minimum information needed to resolve those blockers. Do not ask about `Ambiguity` items.

Wait for the user's response.

- If the user explicitly confirms, move to Phase 2.
- Otherwise, synthesize the original request plus all user responses so far into one richer idea statement. Re-derive the entire Idea Frame from scratch and repeat the ask step.

Phase 2 only runs after explicit confirmation.

---

## Phase 2 — Coding Translation

After confirmation, emit the confirmed Idea Frame verbatim, then translate it into a coding-facing handoff. This translation may identify project context that must be inspected later, but intake itself does not inspect the project.

```text
--- Confirmed Idea Frame ---
<echo the final confirmed Idea Frame as-is>

--- Coding Translation ---
CODING_NEED: <YES | NO | UNCERTAIN>
Execution posture: <immediate | context-first | science-first | none>
Computational target: <known target | project-dependent | unknown | none>
Candidate artifact: <script | notebook | config | simulation setup | test harness | CLI | app feature | analysis pipeline | benchmark | document | undecided | none>
Required inputs: <data, parameters, examples, paper result, user workflow, logs, repo context, etc.>
Expected outputs: <plot, table, metric, config, test result, feature behavior, report, reproduction, etc.>
Validation method: <evidence that would show the coding work served the domain goal>

Known non-blocking ambiguities:
- <uncertainty downstream work should preserve; omit if none>

Project context needed before implementation:
- <repo/project fact a downstream workflow should inspect; omit if none>
- <repo/project fact a downstream workflow should inspect; omit if none>

Open coding questions:
- <implementation-facing question left for planning/inspection; omit if none>

Suggested downstream class: <planning | retrieval/context | coding | research | none>
This is metadata only; do not invoke the suggested class.

Downstream prompt:
"""
<one concise prompt that a planning, retrieval, coding, or research workflow can act on; preserve the confirmed goal, scope, premise status, required context, known ambiguities, and validation evidence; do not include implementation steps>
"""
```

Then hard stop. Do not invoke the suggested downstream class; wait for the user or caller to choose the next workflow.

### Execution posture rules

- `immediate`: enough information exists for downstream action without more domain clarification.
- `context-first`: repository, file, data, or project context must be inspected before planning or implementation.
- `science-first`: conceptual, scientific, or methodological validity must be clarified before coding translation can be trusted.
- `none`: `CODING_NEED` is `NO`, so no coding-facing downstream action is needed.

---

## Downstream prompt requirements

The downstream prompt is the main deliverable. It should be coding-facing but not a plan.

Include:

- The confirmed domain goal
- The likely computational artifact, if known
- Required inputs and expected outputs
- Validation evidence
- Project context that must be inspected before implementation, if project-dependent
- Any unverified premise that downstream work must not silently accept as fact

Avoid:

- Step-by-step implementation plans
- Tool calls or file searches
- Routing commands
- Speculative architecture choices
- Generic next-action advice

---

## Hard constraints

- Do not generate a plan or task chain
- Do not start coding or edit files
- Do not perform retrieval, repository inspection, or file search
- Do not execute routing to another workflow
- Do not ask implementation-detail questions unless they affect the idea-to-code translation
- Treat user diagnoses as unverified premises unless evidence is supplied
- Hard stop after emitting the Coding Translation
