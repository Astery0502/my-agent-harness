# Nexus Engineering Estimation Report

## 1. Executive summary

- **Current maturity:** `mostly reliable`
- **Overall confidence:** medium
- The core scaffold/setup and deterministic sync scripts are simple, readable, and covered by existing integration-style tests.
- `SKILL.md` gives strong agent-facing constraints for exact translation, validation, and note bookkeeping.
- The main weakness is that the hardest part — agent semantic translation from free-form notes into candidate intents — is guided but not directly testable by the current script tests.
- The safety model is mostly good: install skips existing files, generated artifacts are separated, and apply only writes after validated payloads.
- Remaining work is mostly targeted test coverage, schema documentation, and a few guardrails rather than a rewrite.

Verification run during inspection:

```bash
bash "runtime/skills/nexus/tests/test-nexus-setup.sh" && bash "runtime/skills/nexus/tests/test-nexus-sync.sh"
```

Result:

```text
PASS: nexus setup behavior
PASS: nexus sync behavior
```

## 2. What exists

Nexus has a clear two-mode workflow:

- `SKILL.md` defines the purpose: maintain `.nexus/` route and impact maps, scaffold files, sync route discovery, translate notes into validated intents, compile graph/index artifacts (`runtime/skills/nexus/SKILL.md:13`).
- The core exactness rule is explicit: only use prepared notes, routes, rules, existing intents, and confirmed repo files as evidence (`runtime/skills/nexus/SKILL.md:30`).
- Setup mode uses `nexus_status.py` to classify state as `fresh`, `partial`, or `complete` (`runtime/skills/nexus/SKILL.md:47`, `runtime/skills/nexus/scripts/nexus_status.py:27`).
- Install mode copies scaffold files and skips existing files, so it does not overwrite existing scaffold content (`runtime/skills/nexus/scripts/nexus_install.py:53`).
- Sync mode is documented as route sync, note preparation, candidate derivation, validation, apply, impact graph compile, and route index build (`runtime/skills/nexus/SKILL.md:96`).

Implemented script responsibilities:

- `sync_routes.py` discovers git-visible files, applies `routes_rules.yaml`, preserves manual route fields, and marks missing old nodes as stale (`runtime/skills/nexus/template/.nexus/scripts/sync_routes.py:27`, `runtime/skills/nexus/template/.nexus/scripts/sync_routes.py:118`).
- `prepare_impact_notes.py` validates and normalizes pending notes into a clean agent input payload (`runtime/skills/nexus/template/.nexus/scripts/prepare_impact_notes.py:71`).
- `validate_impact_intents.py` validates candidate intents against rule ids, routes, existing intents, and duplicate policy (`runtime/skills/nexus/template/.nexus/scripts/validate_impact_intents.py:229`).
- `apply_validated_intents.py` appends validated intents, strips `note_id`, moves only successfully transformed notes, and preserves aliases (`runtime/skills/nexus/template/.nexus/scripts/apply_validated_intents.py:181`).
- `sync_impact_graph.py` compiles `.nexus/impact.yaml` from intent data and route/index context (`runtime/skills/nexus/template/.nexus/scripts/sync_impact_graph.py:10`).
- `sync_route_index.py` joins routes and compiled impact graph into `.nexus/route-index.json` (`runtime/skills/nexus/template/.nexus/scripts/sync_route_index.py:10`).

The templates distinguish hand-authored, script-generated, and agent-written files (`runtime/skills/nexus/template/.nexus/README.md:7`, `runtime/skills/nexus/template/.nexus/README.md:15`, `runtime/skills/nexus/template/.nexus/README.md:37`).

## 3. Gap analysis

### Confirmed gaps

- **Scaffold README omits the full Step B workflow.** The README’s “Typical sync order” lists only route sync, impact graph sync, and route index sync (`runtime/skills/nexus/template/.nexus/README.md:43`). It does not show `prepare_impact_notes.py`, candidate validation, or apply. `SKILL.md` does include the full flow, so this is a docs consistency gap, not an implementation gap.
- **Tests cover apply behavior but not validator behavior in depth.** `test-nexus-sync.sh` directly calls `apply_validated_intents.py` with a ready payload (`runtime/skills/nexus/tests/test-nexus-sync.sh:50`) but does not exercise `validate_impact_intents.py` through stdin for invalid rules, invalid routes, existing duplicates, batch duplicates, or malformed payloads.
- **No direct test for `prepare_impact_notes.py`.** The prepare script has meaningful behavior around invalid pending entries, normalization, warning generation, and `skip` vs `ready`, but current tests do not appear to invoke it directly.
- **No full end-to-end test of Step B.** The agent-only semantic translation step cannot be fully deterministic, but the deterministic envelope around it can be tested: prepared notes → candidate payload → validator → apply → pending/transformed bookkeeping.
- **Empty or unrelated `.nexus/` directory is treated as `fresh`.** `nexus_status.py` reports `fresh` only when `.nexus/` does not exist on the fast path, but `classify()` also yields `fresh` if no template files exist in the target (`runtime/skills/nexus/scripts/nexus_status.py:35`). This is probably harmless for an empty directory, but slightly weaker than the documented definition that `partial` means `.nexus/` exists but scaffold files are missing (`runtime/skills/nexus/SKILL.md:56`).

### Uncertainties needing more inspection

- **Real agent compliance with the exactness rule.** The instructions are good, but real behavior depends on whether agents consistently refuse under-specified notes rather than inventing structure.
- **YAML dependency availability in target repos.** `graph_helpers.py` requires either `ruamel.yaml` or `PyYAML` (`runtime/skills/nexus/template/.nexus/scripts/graph_helpers.py:10`). Existing tests passed in this environment, but target environments may vary.
- **Large repository performance.** Route discovery uses `git ls-files` with a filesystem fallback (`runtime/skills/nexus/template/.nexus/scripts/sync_routes.py:27`). This is likely fine for normal repos, but not assessed for very large monorepos.

## 4. Risk assessment

### High

None found from the read-only inspection and existing test run.

### Medium

- **Agent may over-infer candidate intents.**
  - Impact: inaccurate `.nexus/impact.intent.yaml`, misleading graph.
  - Trigger: vague `impact-notes.yaml` entries where the agent chooses a plausible interpretation instead of leaving the note pending.
  - Existing mitigation: strong exactness rule in `SKILL.md` (`runtime/skills/nexus/SKILL.md:26`), validator gate, pending-note behavior.
  - Remaining risk: validator checks shape/rules/routes, not semantic truth.

- **Apply helper trusts validator-shaped input.**
  - Impact: if called directly with a `status: ready` payload that did not come from the validator, invalid but well-shaped intents can be appended.
  - Trigger: agent bypasses `validate_impact_intents.py`.
  - Existing mitigation: `SKILL.md` explicitly requires validation before apply (`runtime/skills/nexus/SKILL.md:163`).
  - Possible improvement: small provenance/status guard or tests reinforcing the required call sequence.

- **README sync order can mislead manual users.**
  - Impact: users running scripts manually may skip note transformation and wonder why notes do not affect the graph.
  - Trigger: user follows `.nexus/README.md` rather than `/nexus`.
  - Existing mitigation: README says invoke `/nexus` for full workflow (`runtime/skills/nexus/template/.nexus/README.md:51`).

### Low

- **Partial/fresh classification edge case.**
  - Impact: an existing `.nexus/` directory with unrelated files may be treated as `fresh`; install will add scaffold files without explicit partial confirmation.
  - Trigger: target repo already has `.nexus/` but none of the template files.
  - Mitigation: install skips existing files and should not overwrite unrelated files.

- **Generated YAML formatting may change comments.**
  - Impact: manual comments in generated or agent-written files can be lost when scripts save YAML.
  - Trigger: user manually edits files that are supposed to be generated or agent-written.
  - Mitigation: docs clearly separate hand-authored vs generated/agent-written surfaces.

## 5. Test coverage estimate

### Covered now

- Setup from fresh state to complete scaffold (`runtime/skills/nexus/tests/test-nexus-setup.sh:9`).
- Partial install requires confirmation and preserves existing files (`runtime/skills/nexus/tests/test-nexus-setup.sh:15`).
- `.DS_Store` is ignored during scaffold state checks (`runtime/skills/nexus/tests/test-nexus-setup.sh:31`).
- Route sync creates expected file nodes (`runtime/skills/nexus/tests/test-nexus-sync.sh:10`).
- Apply helper appends validated node/edge intents, strips `note_id`, preserves aliases, and moves transformed notes (`runtime/skills/nexus/tests/test-nexus-sync.sh:71`).
- Apply skip path does not mutate files (`runtime/skills/nexus/tests/test-nexus-sync.sh:75`).
- Impact graph and route index are compiled into expected durable artifacts (`runtime/skills/nexus/tests/test-nexus-sync.sh:89`).

### Missing

- Direct tests for `prepare_impact_notes.py`.
- Direct tests for `validate_impact_intents.py`.
- End-to-end deterministic Step B envelope.
- Invalid YAML / malformed schema tests.
- Duplicate filtering tests at validator level.
- Invalid `route_ref`, invalid `kind`, invalid `type` tests.
- Stale route behavior when files disappear.
- Route manual-field preservation beyond the basic route sync assertion.
- Route index first-sync behavior where previous `route-index.json` is empty and route refs may be inferred later.

### Tests to add first

1. **Validator admission tests**: valid payload, invalid rule id, invalid route ref, existing duplicate, batch duplicate.
2. **Prepare notes tests**: empty pending → `skip`; valid pending → normalized `ready`; malformed pending → `error`.
3. **Full deterministic Step B test**: prepared fixture candidate → validator → apply → assert `impact.intent.yaml` and `impact-notes.yaml` state.
4. **Route preservation/stale test**: manually edit route fields, remove a fixture file, sync routes, assert manual fields remain and old path becomes `stale: true`.

These should stay artifact/state-based, not text-output-based.

## 6. Effort estimate

| Task | Size | Confidence | Notes |
| --- | ---: | ---: | --- |
| Add direct `prepare_impact_notes.py` tests | S | High | Straightforward shell fixture + YAML assertions. |
| Add direct `validate_impact_intents.py` tests | M | High | Several small payload cases; high value. |
| Add deterministic Step B envelope test | M | Medium | Needs a clean fixture flow but no agent simulation. |
| Align `.nexus/README.md` with full `/nexus` sync flow | XS | High | Small docs correction. |
| Clarify `fresh` vs `partial` behavior for existing empty/unrelated `.nexus/` | XS/S | Medium | Could be docs-only or small status logic change. |
| Add route stale/manual-field preservation test | S | High | Exercises existing intended behavior. |
| Add schema reference comments or compact schema section | S | Medium | Useful, but avoid over-documenting. |
| Add lightweight guardrails around apply input provenance | S/M | Medium | Needs care not to overcomplicate trusted helper flow. |
| Assess large-repo route sync performance | M | Low | Only needed if Nexus will be used on large repos soon. |

## 7. Recommended next steps

1. **Add validator tests first.** This is the highest-leverage reliability gap because the validator is the admission gate for agent-generated structure.
2. **Add prepare-note tests next.** This locks down the user-authored boundary and prevents malformed notes from reaching semantic translation.
3. **Add one deterministic Step B envelope test.** Do not try to test LLM judgment; test the durable state transitions around it.
4. **Update `.nexus/README.md` to mention the full `/nexus` flow.** Keep manual script examples, but clarify that note transformation requires prepare/validate/apply or invoking the skill.
5. **Decide whether existing empty `.nexus/` should be `fresh` or `partial`.** If current behavior is intentional, document it. If not, adjust `nexus_status.py` and test it.
6. **Avoid broad refactors.** The current scripts are small and understandable. The best improvements are surgical tests and small clarity fixes.
