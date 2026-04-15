# Plan Workflow Trials

Behavioral trials for the `/plan` command, `planner` agent, and
`planning-protocol` skill.

## How to run a trial

1. Ensure the workflow is installed: `./scripts/sync.sh --platform claude`
2. Open a Claude Code session in a target project
3. Copy the **Input prompt** from the trial file and run it as `/plan <prompt>`
4. Work through the **What to observe** checklist against the actual output
5. Record pass/fail and notes in `docs/plan-workflow-trials.md`

## Comparative trials (T6)

Run the same prompt twice:
- Once with `/plan <prompt>` (new workflow)
- Once with a plain `plan this for me: <prompt>` (no workflow)

Compare the two outputs against the same checklist. Record both results.

## Trial index

| File | Behavior tested |
|---|---|
| `t1-clear-request.md` | Clear request still runs planning-protocol A–E |
| `t2-ambiguous-request.md` | Ambiguous request → planning-protocol A–E |
| `t3-framing-trap.md` | Step D objective distance |
| `t4-hidden-dependency.md` | Intra-chain reopen E→B |
| `t5-misframed-request.md` | Intra-chain reopen D→A |
| `t6-comparative.md` | New workflow vs. unstructured planning |
| `t7-clear-but-wrong.md` | Clear but wrong premise is challenged in step A |
| `t8-subtle-framing-trap.md` | D discipline under subtle (all-reasonable) framing trap |
| `t9-long-chain-packet.md` | Constraint packet bus discipline on longer chains |

## Results

Record all trial outcomes in `docs/plan-workflow-trials.md`.
