# Intake Prompt Refinement Design

## Purpose

Refresh `runtime/skills/intake/SKILL.md` from a domain-to-code bridge into a lightweight prompt-refinement workflow.

The refreshed skill should help when a user has a rough, unclear, or under-structured request and wants it turned into a stronger downstream prompt. It should identify the request's `WORK_TYPE`, assign one fitting `AGENT_ROLE`, preserve the user's actual intent, add missing prompt structure, emit one polished prompt, and stop.

The skill should not implement, route, invoke another skill, create plans, inspect code by default, or imply that prompt polishing solves execution problems. Its value is improving the prompt before another workflow begins.

## Scope

Update only:

- `runtime/skills/intake/SKILL.md`

Keep the frontmatter explicit-invocation rule:

- `LOAD ONLY when the user explicitly invokes /intake. Do not auto-load for any other reason.`

Replace the current heavy domain-to-code framing, labels, and flowchart with prompt-refinement language.

## Work Types And Roles

Initial supported work types:

| `WORK_TYPE` | Role intent |
|---|---|
| `coding` | A senior engineer shaping a clear implementation request |
| `research` | A careful researcher shaping an evidence-seeking request |
| `analysis` | An analyst shaping a data, result, or interpretation request |
| `writing` | An editor shaping a written artifact request |
| `planning` | A planner shaping a sequence, scope, or execution request |
| `debugging` | A debugger shaping a failure-investigation request |
| `decision-framing` | A strategist shaping a comparison or choice request |

The skill should choose one `WORK_TYPE` and one concise `AGENT_ROLE`. If multiple work types are plausible, choose the dominant one and preserve the ambiguity in the diagnosis instead of expanding the taxonomy.

## Flow

### Phase 1: Prompt Diagnosis

Read the user's request and classify:

- `WORK_TYPE`
- `AGENT_ROLE`
- user goal
- intended artifact or output
- stated constraints
- missing prompt ingredients
- whether clarification is required

Clarification should be rare. Ask only if the missing information would materially change the polished prompt. Otherwise, carry uncertainty forward explicitly.

### Phase 2: Prompt Polishing

Once enough information exists, emit the diagnosis and one polished prompt.

The polished prompt should include:

- role
- task
- context
- constraints
- expected output
- success criteria
- important ambiguities

The polished prompt should not include:

- tool calls
- step-by-step implementation
- a forced next workflow
- execution instructions for the current agent

After output, the skill must stop. It must not execute, route, invoke another skill, or make code changes.

## Output Template

```text
--- Prompt Diagnosis ---
WORK_TYPE: <coding | research | analysis | writing | planning | debugging | decision-framing>
AGENT_ROLE: <one concise role>
User goal: <goal>
Target output: <artifact/result>
Constraints: <stated constraints, or none>
Missing ingredients handled: <assumptions or preserved ambiguities>

--- Polished Prompt ---
<one strong downstream prompt>

Stop here. Do not execute, route, invoke another skill, or make code changes.
```

## Verification

Verification should only check the Markdown text itself:

- read the edited file as plain text
- confirm the structure is coherent and not overbuilt
- confirm the explicit-invocation rule remains
- confirm the output says prompt and stop
- confirm no stale "domain-to-code bridge" framing remains as the core purpose

No tests are required for this change.

## Non-Goals

- Do not add runtime code.
- Do not add tests.
- Do not update unrelated skills.
- Do not change install or sync behavior.
- Do not make `intake` a router.
- Do not make `intake` a planning workflow.
