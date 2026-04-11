# Workflow Behavioral Trials

This directory holds behavioral trial prompts for runtime workflows installed by the harness.

Each workflow has its own subdirectory:

```
tests/workflow/
  <workflow-name>/
    README.md          # how to run trials for this workflow
    t1-<name>.md       # individual trial prompts
    t2-<name>.md
    ...
```

## What these are

Behavioral trials are not automated tests. They require a human to:

1. Run the trial prompt against the installed workflow
2. Observe the output against the checklist in the trial file
3. Record results in the corresponding `docs/<workflow>-trials.md` file

## What these are not

These files do not replace the automated content tests in `tests/ops/`. Those
tests verify the structural contracts are encoded in the deployed files. These
trials verify the LLM actually behaves as those contracts intend.

## Adding a new workflow's trials

1. Create `tests/workflow/<workflow-name>/` with its own `README.md`
2. Add one trial file per target behavior
3. Create `docs/<workflow-name>-trials.md` as the living results record
4. Link both from `docs/README.md`
