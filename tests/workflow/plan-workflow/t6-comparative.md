# Trial T6: Comparative — New Workflow vs. Unstructured Planning

## Target behavior

Verify that the new workflow produces measurably better outcomes than unstructured
planning on the same weak prompts.

## Prompts to compare

Run both of these prompts through each path (4 runs total):

- Prompt A: `doctor.sh should fix drift automatically` (from T5 — misframed request)
- Prompt B: `Add a /fix-sync command that automatically retries failed syncs` (from T3 — framing trap)

## Paths

**Path 1 (new workflow):**
```
/plan <prompt>
```

**Path 2 (unstructured baseline):**
```
plan this for me: <prompt>
```
(No `/plan`, no skill invocation — just a direct planning request)

## What to observe per run

For each run, score against these dimensions:

| Dimension | Question |
|---|---|
| Framing challenge | Did it challenge the request premise before proceeding? |
| Route breadth | Did it generate more than one candidate approach? |
| D-style critique | Did any candidate routes get rejected with substantive reasons? |
| Hidden contract | Did it surface the architectural contract (doctor/repair split or retry-without-root-cause)? |
| Task chain quality | Is the final task chain aligned with repo constraints? |
| Reopen signal | If the premise is wrong, did it name where to reopen? |

Score each dimension: pass / partial / fail.

## How to record

Record a 2×2 matrix per prompt in `docs/plan-workflow-trials.md`:

```
Prompt A:
  /plan:      [scores]
  unstructured: [scores]

Prompt B:
  /plan:      [scores]
  unstructured: [scores]
```

## Pass condition

The new workflow scores higher than the unstructured baseline on at least 4 of
6 dimensions for both prompts.

## Notes

This trial directly follows the evolution-front experiment methodology. Use the
same isolated context for each run to avoid cross-contamination.
