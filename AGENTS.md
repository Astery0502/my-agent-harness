# My Agent Harness Project Guidance

This `AGENTS.md` is for working on the `my-agent-harness` repository itself.

## Project Scope

- treat this repo as the editable source of truth for the harness project
- keep ECC nearby as a reference, but do not mirror it wholesale
- favor small, explainable structures over broad framework imports

## Working Rules

- update source files here instead of editing generated `.local/` runtime outputs
- preserve user-owned runtime data and unrelated local changes
- keep the main docs aligned when changing install or sync behavior
- prefer changes that keep future platform extensions straightforward

## Optional Pattern

When this repo defines installable runtime instructions that should be distinct
from project-local guidance, keep the project contract in `AGENTS.md` and place
the shared cross-platform runtime baseline in `runtime/HARNESS.md`.

This is optional, but it is the preferred pattern here because `my-agent-harness`
is itself a project, not only a source bundle for other runtimes.

## Early Milestone Constraint

The first milestone is only for repository foundation. Do not treat placeholder
files as fully implemented workflows.
