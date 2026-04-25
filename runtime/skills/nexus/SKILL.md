---
name: nexus
description: >
  Scaffold or sync the .nexus/ route-and-impact system.
  Only invoke when the user explicitly asks — never trigger automatically.
  Use when the user says: /nexus, "run nexus", "nexus setup", "nexus sync".
---

# Nexus

## Goal

Run the status check first:

```bash
python <skill_dir>/scripts/nexus_status.py --target <repo_root>
```

Read the `STATE` line and branch:

- `STATE: fresh` — `.nexus/` does not exist → go to **Mode 1 — Setup**
- `STATE: partial` — `.nexus/` exists but some scaffold files are missing → go to **Mode 1 — Setup**
- `STATE: complete` — all scaffold files present → go to **Mode 2 — Sync**

## Scaffold contents

- `.nexus/routes.yaml`
- `.nexus/routes_rules.yaml`
- `.nexus/impact-notes.yaml`
- `.nexus/impact.intent.yaml`
- `.nexus/impact.yaml`
- `.nexus/impact-rules.yaml`
- `.nexus/route-index.json`
- `.nexus/scripts/graph_helpers.py`
- `.nexus/scripts/prepare_impact_notes.py`
- `.nexus/scripts/validate_impact_intents.py`
- `.nexus/scripts/apply_validated_intents.py`
- `.nexus/scripts/sync_routes.py`
- `.nexus/scripts/sync_route_index.py`
- `.nexus/scripts/sync_impact_graph.py`

## Mode 1 — Setup

If `STATE: partial`, the status script already printed `WILL_CREATE` /
`WILL_SKIP` lines — show these to the user and ask for confirmation before
proceeding.

Run:

```bash
python <skill_dir>/scripts/nexus_install.py --target <repo_root>
# add --confirm if STATE was partial and user confirmed
```

`nexus_install.py` outputs `CREATED:` / `SKIPPED:` per file, then `DONE`.

Tell the user the scaffold is ready. No further action required at setup time;
they can configure `.nexus/routes_rules.yaml` and write into
`.nexus/impact-notes.yaml` at their own pace, then invoke the skill again to
sync.

## Mode 2 — Sync

All commands run from `<repo_root>`. Run unconditionally in this order:

### A — Sync route tree

```bash
python .nexus/scripts/sync_routes.py
```

### B — Transform notes into intents

First run:

```bash
python .nexus/scripts/prepare_impact_notes.py
```

Read the YAML result and branch:

- `status: error` — stop Step B and report `errors`
- `status: skip` — skip Step B and continue to Step C
- `status: ready` — continue Step B using only the returned `notes`

When `status: ready`, derive candidate `node_intents` and `edge_intents` from the returned notes.

The agent is responsible for semantic interpretation only:
- classify each note as node intent, edge intent, or unresolved
- resolve canonical repo-relative ids for `target`, `from`, and `to`
- choose valid rule ids from `.nexus/impact-rules.yaml`
- attach the originating `note_id` to every candidate intent derived from a note
- optionally set `route_ref` when explicitly known
- optionally set `role` or `when` when clearly supported by the note

Do not:
- invent missing targets, rules, routes, or conditions
- rewrite `.nexus/impact-notes.yaml` during candidate derivation
- append raw candidate intents directly to `.nexus/impact.intent.yaml`

Before any append, run the candidate batch through stdin:

```bash
python .nexus/scripts/validate_impact_intents.py
```

This helper is the intent admission gate. It validates candidate intents against:
- `.nexus/impact-rules.yaml`
- `.nexus/routes.yaml`
- existing `.nexus/impact.intent.yaml`

Read the YAML result and branch:

- `status: error` — stop Step B and report `errors`
- `status: skip` — continue to the apply helper so unresolved notes stay pending and no append occurs
- `status: ready` — continue to the apply helper with the returned validated `node_intents` and `edge_intents`

Validation constraints:

1. Required fields must exist:
   - node intent: `target`, `kind`
   - edge intent: `from`, `to`, `type`

2. Canonical normalization is allowed only for light cleanup:
   - trim strings
   - strip leading `./`
   - normalize path separators
   - drop malformed optional fields with warnings

3. Rule validation:
   - `node_intents.kind` must use a rule id with scope `node` or `node_edge`
   - `edge_intents.type` must use a rule id with scope `edge` or `node_edge`

4. Route validation:
   - if `route_ref` is present, it must exist in `.nexus/routes.yaml`
   - if `route_ref` is absent, leave it absent and let later compilation infer it when possible

5. Duplicate policy:
   - existing node duplicate: same `target`, `kind`, and `route_ref`
   - existing edge duplicate: same `from`, `to`, `type`, and `when`
   - batch duplicates use the same keys
   - duplicates are filtered, not appended, and not treated as fatal errors
   - `note_id` is Step B provenance only and is not part of duplicate keys or persisted intents

Then run:

```bash
python .nexus/scripts/apply_validated_intents.py
```

Apply behavior:

- append only the helper-returned validated node intents into `.nexus/impact.intent.yaml` `node_intents`
- append only the helper-returned validated edge intents into `.nexus/impact.intent.yaml` `edge_intents`
- preserve existing `node_intents`, `edge_intents`, and `aliases`
- strip `note_id` before persisting to `.nexus/impact.intent.yaml`
- do not append rejected or duplicate candidates

Notes bookkeeping:

- move a note from `.nexus/impact-notes.yaml` `pending` to `transformed` only if at least one validated intent derived from that note was appended
- record:
  - `hint_ids`
  - `date`
- generate `hint_ids` deterministically as the next `H-###` values in append order
- leave unresolved notes in `pending`
- leave duplicate-only notes in `pending`

After apply, if any notes remain unresolved in `pending`, report them all at once with a single clarifying question. Do not interrupt per entry.


### C — Compile impact graph

```bash
python .nexus/scripts/sync_impact_graph.py
```

### D — Build route index

```bash
python .nexus/scripts/sync_route_index.py
```

D joins routes and impact; always run it last. On the very first sync,
`route-index.json` is still the empty template when C runs — C will emit
`confidence: low` warnings for unresolved route refs. This is expected;
subsequent syncs use the index built by the previous D.

## Notes

- `routes_rules.yaml` controls what files become route nodes; edit before
  first sync if the defaults don't fit the project.
- `impact-notes.yaml` is the user's free-form authoring surface.
- `impact.intent.yaml` is agent-written from notes; never edit manually.
- `impact.yaml` is compiled output; never edit manually.
- `route-index.json` is a cache built from routes + impact.
