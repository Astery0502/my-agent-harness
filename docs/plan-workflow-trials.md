# Plan Workflow Trials

This document records behavioral trial results for the updated `/plan` workflow
introduced after the evolution-front experiment.

## Purpose

Verify that the three structural changes to the planning workflow produce the
intended behaviors:

1. The constraint packet is updated at each step (not assembled as a terminal artifact)
2. Step D exhibits genuine objective distance from B (not continuation of B's reasoning)
3. Intra-chain reopen conditions fire correctly (named upstream step, not silent patch or restart)

Also compare the new workflow against unstructured planning to check whether it
produces better outcomes on weak prompts.

## What this does not test

- Operational sync correctness (covered in `tests/ops/`)
- Structural contract encoding (covered in `tests/ops/test-workflow-content.sh`)

## Method

Trial prompts live in `tests/workflow/plan-workflow/`. Each trial file specifies:
- the input prompt
- which behavior it targets
- a per-observation checklist
- a pass condition

To run a trial:

1. Install the workflow: `./scripts/sync.sh --platform claude`
2. Open a fresh Claude Code session in a target project
3. Run the trial prompt as written
4. Score the output against the trial's checklist
5. Record results below

For comparative trials (T6): run the same prompt twice in separate sessions —
once with `/plan`, once as plain unstructured planning — and record both scores.

---

## Trial Matrix

| ID | Behavior tested | Result | Notes |
|----|----------------|--------|-------|
| T1 | Clear request → tdd-workflow fast path | PASS | Fast path selected; no A–E cycle; packet at A |
| T2 | Ambiguous request → planning-protocol A–E | PASS | Full A–E; 4 routes in B; 2 rejected in D |
| T3 | Step D objective distance (framing trap) | PASS | D explicitly rejected auto-retry; surviving route materially different |
| T4 | Intra-chain reopen E→B (hidden dependency) | PASS | E surfaced ambiguity in "validates"; reopen_target B named |
| T5 | Intra-chain reopen D→A (misframed request) | PASS | D caught architectural contract violation; reopen_target A; request reframed |
| T6 | New workflow vs. unstructured baseline | PASS (6/6 vs 0/6) | Workflow caught all framing issues; baseline implemented wrong approaches directly |
| T7 | Routing precision: clear but wrong premise | PASS | Routed to A–E (not tdd-workflow); false premise named at D; reframed as incremental backup |
| T8 | D discipline under subtle framing trap | PASS | D attacked the shared model across all four routes; surviving route constrained to staging-only |
| T9 | Constraint packet bus discipline (long chain) | PASS | Packet updated at A, B, D, E; hook failure semantics unknown at A → accepted constraint at D → reflected in E task chain |

---

## Trial Notes

### T1: Clear Request → tdd-workflow Fast Path

**Prompt:** `Add a --verbose flag to sync.sh that prints each file path as it is deployed`

**Routing decision:** Clear, interpretable without premise challenge. Premise is sound. → tdd-workflow fast path selected.

**Constraint packet at A:**
- `task_statement`: Add `--verbose` flag to sync.sh; print each deployed file path
- `challenged_assumptions`: none
- `unknowns`: output format (source path, target path, or both); stdout vs. stderr

**tdd-workflow execution:**

*Interpret:* sync.sh deploys via the deploy step in sync-common.sh. `--verbose` prints per-file during that step. Flag is opt-in; default behavior unchanged.

*Provisional acceptance criteria:*
1. `sync.sh` accepts `--verbose` without error
2. With `--verbose`, each deployed path is printed during deployment
3. Without `--verbose`, output is unchanged
4. `--verbose --dry-run` prints paths that would be deployed

*Examples:*
- `./scripts/sync.sh --platform claude --verbose` → one line per file: `deploy: runtime/agents/planner.md → ~/.claude/agents/planner.md`
- Concat-mode files (CLAUDE.md built from two sources): one output line for the final target

*Edge cases:* `--target staging` paths use staging root; concat mode emits one line per built target, not per source.

**Constraint packet handoff:**
- `chosen_direction`: parse flag in sync.sh → pass to deploy() → print path per-file
- `verification_target`: `./scripts/sync.sh --platform claude --verbose` produces per-file output

**Task chain:**
1. Add `--verbose` to sync.sh argument parsing
2. Pass `verbose` to `sync_platform()` → `deploy()` in sync-common.sh
3. In deploy loop: if verbose, print `deploy: $src → $target`
4. Update `--help` output

**Checklist:**
- [x] Planner signals tdd-workflow fast path
- [x] No A–E cycle
- [x] Acceptance criteria shaped before examples
- [x] Constraint packet initiated at A
- [x] Concrete task chain without front-half divergence

**Verdict: PASS**

---

### T2: Ambiguous Request → planning-protocol A–E

**Prompt:** `Make the doctor better`

**Routing decision:** "better" is underspecified — no concrete premise to work from. → planning-protocol A–E.

**Step A:**
- `request_invariant`: "Improve doctor.sh in some meaningful way"
- `challenged_assumptions`: ["'better' is a well-defined goal", "any improvement counts equally"]
- `unknowns`: ["which dimension: UX? accuracy? coverage? speed?", "what is the user's pain point?"]

**Constraint packet at A:** `challenged_assumptions` non-empty; `unknowns` named.

**Step B (expand — 4 routes):**
1. Improve drift detection accuracy (hash comparison may produce false positives on line-ending differences)
2. Improve output readability (current flat list is hard to scan)
3. Add component-level summary (pass/fail per component, not just per file)
4. Support stateless mode (work without a prior sync/install-state)

**Constraint packet at B:** `candidate_routes` = [accuracy, readability, component-summary, stateless-mode]

**Step D (critique — critic agent, independent filtering):**

*Attacking Route 1 (accuracy):* "Where is the evidence of false positives? This assumes a known bug without data. Don't plan fixes for unobserved problems." → REJECTED.

*Attacking Route 4 (stateless mode):* "This is a new feature, not an improvement. It changes the fundamental model of doctor.sh requiring install-state. Out of scope." → REJECTED.

*Attacking Route 3 (component summary):* "More complex than it sounds — requires aggregating drift by component key. Risk of over-engineering a formatting concern into a data model change." → Partially preserved as a formatting sub-concern of Route 2.

Surviving: Route 2 (output readability) + component grouping as a formatting improvement.

**Constraint packet at D:**
- `rejected_routes`: [accuracy (no evidence), stateless-mode (scope creep)]
- `accepted_constraints`: ["improvement must target observable UX pain", "no new functional models"]

**Step E (complete):**
- `chosen_route`: Improve output formatting — group drifted files by component, add summary line
- `why_this_route`: Concrete, bounded, addresses the most likely scan-fatigue pain point
- `task_chain`: (1) Group doctor.sh output by component; (2) Show per-component ✓/✗; (3) List drifted files under component; (4) Add "N components clean, M drifted" summary
- `risks`: requires reading componentTargets from state file (existing data, low risk)

**Checklist:**
- [x] Routes to planning-protocol A–E (not tdd-workflow)
- [x] Step A surfaces multiple interpretations (4 dimensions)
- [x] Step B generates 4 candidate routes
- [x] Step D challenges routes with objective distance (2 explicitly rejected)
- [x] Constraint packet updated at A, B, D, E
- [x] `challenged_assumptions` non-empty at A

**Verdict: PASS**

---

### T3: Step D Objective Distance (Framing Trap)

**Prompt:** `Add a /fix-sync command that automatically retries failed syncs`

**Routing decision:** Concrete surface, but "automatically retries" assumes a failure class. Premise may be wrong. → planning-protocol A–E.

**Step A:**
- `request_invariant`: "Add a mechanism for handling sync failures"
- `challenged_assumptions`: ["sync failures are transient and retryable", "automatic retry is safe without diagnosing failure cause", "/fix-sync as a new command is the right surface"]
- `unknowns`: ["what causes the sync failures the user is experiencing?", "is the failure state recoverable by simply retrying?"]

**Constraint packet at A:** framing assumptions front-loaded.

**Step B (expand):**
1. `/fix-sync` command with automatic retry (as proposed)
2. Post-failure diagnostic UX — improve error messages so users know what to fix manually
3. Wrap repair.sh — `/fix-sync` calls repair.sh after doctor confirms drift
4. Pre-sync validation — catch errors before deployment starts

**Constraint packet at B:** `candidate_routes` = [auto-retry, diagnostic-UX, repair-wrapper, pre-validate]

**Step D (critique — critic agent, independent filtering):**

*Attacking Route 1 (auto-retry):* **REJECTED.** Sync failures in this repo come from bad config, malformed state, or missing source files — not transient errors. Retrying the same broken sync produces the same failure. Worse: a partial deploy followed by retry can corrupt install-state. The diagnosis/repair split exists precisely to prevent blind auto-fix. Automatic retry without root-cause diagnosis is the wrong abstraction for this failure class.

*Attacking Route 4 (pre-validate):* PARTIALLY VALID but has a hidden dependency — "validates the install-map" is underspecified (schema? coverage? file existence?). Cannot commit to this route without clarification.

*Attacking Route 3 (repair-wrapper):* The concept is closer to correct, but naming it `/fix-sync` implies it fixes sync failures. It actually calls repair.sh after drift is confirmed. The name is misleading and conflates two different problems.

Surviving: Route 2 (diagnostic UX) — honest about what the tool can do. Route 3 partially — if surfaced as "a post-drift repair shortcut" rather than a "sync failure fix".

**Constraint packet at D:**
- `rejected_routes`: [auto-retry (wrong abstraction for this failure class), pre-validate (underspecified)]
- `accepted_constraints`: ["no automatic state modification without diagnosis", "must respect diagnosis/repair contract"]

**Step E:**
- `chosen_route`: Improve sync failure error messages (Route 2)
- Reframing: the user wants sync failures easier to recover from, not auto-remediated. Better errors are the right lever.
- `task_chain`: (1) Wrap deploy errors with actionable messages ("permission error on $target — check target path ownership"); (2) In sync.sh exit handler, print "sync failed — run ./scripts/repair.sh if install-state may be inconsistent"; (3) Optionally add repair.sh suggestion to doctor.sh drift output

**Checklist:**
- [x] Step B expands prompt (retry logic, diagnostic UX, repair wrapper, pre-validate)
- [x] Step D switches role — reads as challenge, not continuation ("REJECTED. Sync failures in this repo come from bad config...")
- [x] Surfaces design tension (retry loops on same failure; state corruption risk)
- [x] At least one route rejected at D with substantive reason (auto-retry, pre-validate both rejected)
- [x] Surviving route materially different from "add retry to sync" (better error messages)

**Verdict: PASS**

**Key lesson:** D caught the "wrong failure class" assumption that B didn't challenge. The request proposed a solution appropriate for network transient errors; the repo has deterministic, config-driven failures. That distinction was invisible until D attacked B.

---

### T4: Intra-chain Reopen E→B (Hidden Dependency)

**Prompt:** `Add a --check flag to sync.sh that validates the install-map before syncing`

**Routing decision:** Concrete surface but "validates" is ambiguous. → planning-protocol A–E.

**Step A:**
- `request_invariant`: "Add pre-sync validation to sync.sh"
- `unknowns`: ["what does 'validates' mean?"]
- `challenged_assumptions`: ["'validates the install-map' has a single unambiguous meaning"]

**Step B (expand — 3 routes, all independently valid):**
1. JSON structure validation — is install-map.json valid JSON with required fields?
2. Component coverage check — do all manifest.json components have mappings in install-map?
3. Source file existence — do all source paths in mappings point to real files in the repo?

**Step C (atomize):**
- Route 1: touches install-map JSON parsing in sync-common.sh
- Route 2: requires cross-referencing manifest.json + install-map.json — new logic
- Route 3: requires walking all source paths before sync — potentially slow

**Step D (critique):**
All three routes are valid, non-overlapping, and non-conflicting. The problem is not that any route is wrong — it's that they answer different questions under the same flag name.

"If we ship Route 1 only and a user runs `--check` expecting source-file existence validation (Route 3), they will conclude the flag is broken. The three routes have different failure modes, different output, and different implementation locations. Picking one silently is a trap."

**Step E (gap-fill — REOPEN FIRES):**

Attempting to close the dependency chain for `--check`:

To define `--check` behavior, I need to know which validation class it implements. Without that choice, any implementation is an undocumented arbitrary decision.

**INTRA-CHAIN REOPEN → B:**

The gap is not fillable at E without an arbitrary choice the user hasn't made. Silent completion would be local patching — picking Route 1 (simplest) without acknowledging the other two exist.

- `reopen_target`: B
- Reopen action: return to expansion with the specific question: "which validation class? (JSON schema / component coverage / file existence)" — require human input, then select one route and re-enter C.
- Alternatively escalate as unresolved unknown for human resolution before proceeding.

**Constraint packet at reopen:**
- `reopen_target`: B
- `unknowns`: ["which validation class: schema / coverage / file existence?"]

**Checklist:**
- [x] Step E attempts to fill dependency chain
- [x] Step E surfaces hidden dependency ("validates" is underspecified across 3 classes)
- [x] Planner does NOT silently pick one interpretation
- [x] Reopens B / escalates as unresolved unknown
- [x] `reopen_target` named as B

**Verdict: PASS**

**Key lesson:** The hidden dependency was not about a missing file or missing API — it was a semantic ambiguity in the verb "validates". The intra-chain reopen fired correctly because E couldn't resolve it locally without lying about the scope.

---

### T5: Intra-chain Reopen D→A (Misframed Request)

**Prompt:** `doctor.sh should fix drift automatically`

**Routing decision:** Touches doctor.sh architecture. The premise may violate an intentional contract. → planning-protocol A–E.

**Step A:**
- `request_invariant`: "doctor.sh should automatically fix drift when it detects it"
- `challenged_assumptions`: ["the current separation between diagnosis (doctor.sh) and repair (repair.sh) is a defect", "auto-fixing drift is safe without explicit user consent"]
- `unknowns`: ["why does the user want this? pain with the two-step flow?", "is the use case interactive or CI?"]

**Step B (expand):**
1. Merge doctor.sh and repair.sh into a single auto-fix tool
2. Add `--auto-fix` flag to doctor.sh as opt-in
3. Reduce two-step-flow friction without adding auto-fix (better UX only)
4. Add doctor → repair pipeline: `doctor.sh --fix` calls repair.sh internally

**Step D (critique — critic agent, independent filtering):**

**Routes 1, 2, and 4 all violate an intentional architectural contract.**

doctor.sh and repair.sh are separated by design: diagnosis does not modify state. This is documented in the repo. The separation exists so users know what's wrong before anything is changed. Adding auto-fix to doctor.sh gives it side effects, which changes its contract from "read-only reporter" to "state mutator". That is an architectural decision, not a feature.

**This request is framed as a bug ("should fix") when it is actually proposing to change a design choice.**

The `request_invariant` is built on a false premise — that the separation is a defect. D cannot simply filter routes here; the root input is wrong.

**→ REOPEN A:** The request itself needs to be rechallenged, not just the routes.

**Reopened Step A:**

Challenge: What does the user actually want?
- If the pain is the two-step flow (annoyance at running two commands): Route 3 addresses this without violating the contract — better UX, a hint in doctor.sh output saying "run ./scripts/repair.sh to fix"
- If the pain is CI automation (no user present to run the second command): that is a distinct workflow — `repair.sh --ci` mode or a CI wrapper script
- If the user genuinely wants to collapse the tools: that is an architectural decision requiring explicit human approval, not a planning task

**Revised `request_invariant`:** "Reduce friction when drift is detected, while preserving the diagnosis/repair contract"

**Revised B → E (after reopen):**
- Surviving candidate: Route 3 (reduce friction)
- `chosen_route`: In doctor.sh output, when drift is found, append "Run `./scripts/repair.sh --target $TARGET` to restore consistency"
- `task_chain`: (1) Detect drift in doctor.sh; (2) Append repair.sh invocation hint to output; (3) Optionally add `--repair` passthrough that invokes repair.sh with matching args (explicit, not automatic)

**Checklist:**
- [x] Step A or D identifies request as misframing an architectural contract
- [x] Step D catches that "auto-heal" collapses the diagnosis/repair split
- [x] Planner explicitly reopens A (not just filters routes in D)
- [x] `challenged_assumptions` at A names the "separation is a defect" assumption
- [x] Final output reframes rather than implements auto-heal

**Verdict: PASS**

**Key lesson:** Direct analogue of evolution-front Trial A2. D→A reopen fired because the false premise was in the request_invariant itself, not in the expansion routes. Filtering routes at D would have been wrong — the right move was to reopen A and restate what the user actually needs.

---

### T6: Comparative — New Workflow vs. Unstructured Planning

**Prompts used:** T3 (framing trap) and T5 (misframed request) — the two highest-signal conformance trials.

#### Prompt A: `doctor.sh should fix drift automatically`

**Path 1 — `/plan` (new workflow):** See T5 above.

**Path 2 — Unstructured (`plan this for me: doctor.sh should fix drift automatically`):**

Without the workflow, the response proceeds directly:

> *Add an `--auto-fix` flag to doctor.sh. When set, after drift is detected, call repair.sh with matching arguments. Add `--yes` to skip confirmation. Support `--target live|staging`. Log repaired components.*
>
> *Task chain: (1) Parse `--auto-fix` in doctor.sh; (2) Call repair.sh conditionally after drift detection; (3) Print repair summary.*

The baseline:
- Accepts the premise without challenge
- Does not surface the diagnosis/repair architectural split
- Produces one route (the proposed solution) without alternatives
- Would produce a doctor.sh with side effects — breaking the repo's intentional contract

**Prompt A scores:**

| Dimension | /plan | unstructured |
|---|---|---|
| Framing challenge | PASS | FAIL |
| Route breadth | PASS (4 routes) | FAIL (1 route) |
| D-style critique | PASS (contract violation named) | FAIL |
| Hidden contract (diagnosis/repair split) | PASS (explicit) | FAIL |
| Task chain quality | PASS (repo-aligned) | FAIL (breaks contract) |
| Reopen signal | PASS (reopen_target A) | N/A |
| **Total** | **6 / 6** | **0 / 6** |

---

#### Prompt B: `Add a /fix-sync command that automatically retries failed syncs`

**Path 1 — `/plan` (new workflow):** See T3 above.

**Path 2 — Unstructured (`plan this for me: Add a /fix-sync command that automatically retries failed syncs`):**

Without the workflow:

> *Create fix-sync.sh. The script re-runs sync.sh with the last-used arguments. Add a retry loop (default 3 attempts) with exponential backoff. Log each attempt. Exit non-zero if all retries fail.*
>
> *Task chain: (1) Capture sync.sh arguments; (2) Add retry loop with backoff; (3) Add `--max-retries` flag; (4) Wire into scripts/*

The baseline:
- Accepts the retry premise without challenge
- Does not surface the "wrong failure class" problem (sync failures are config-driven, not transient)
- Does not mention the diagnosis/repair architecture
- Would produce code that retries the same broken sync 3 times before failing

**Prompt B scores:**

| Dimension | /plan | unstructured |
|---|---|---|
| Framing challenge | PASS | FAIL |
| Route breadth | PASS (4 routes) | FAIL (1 route) |
| D-style critique | PASS (auto-retry rejected) | FAIL |
| Hidden contract (retry wrong for this failure class) | PASS | FAIL |
| Task chain quality | PASS (better error messages) | PARTIAL (functional but wrong approach) |
| Reopen signal | PASS (named at D) | N/A |
| **Total** | **6 / 6** | **0–1 / 6** |

---

**T6 verdict: PASS** — new workflow scores ≥ 4/6 on both prompts. Baseline scores 0/6 (Prompt A) and 0–1/6 (Prompt B).

---

### T7: Routing Precision — Clear but Wrong Premise

**Prompt:** `Add a --skip-backup flag to sync.sh to speed up deploys on trusted machines`

**Routing decision:** Syntactically clear (named flag, stated rationale), but the rationale embeds a suspect premise: "trusted machines" frames backup as a trust/identity concern, not a deploy-safety concern. → planning-protocol A–E.

**Step A:**
- `request_invariant`: "Add an optional mechanism to sync.sh that reduces backup overhead during deployment"
- `challenged_assumptions`: (1) Backups are a trust/identity concern — the "trusted machine" frame implies backups protect against untrusted operators, but backups protect *for* the operator against deploy errors (bad state, partial deploy, path collision) regardless of who runs the command. (2) Backups are the deploy speed bottleneck — no profiling data. (3) A flag is safe because it's opt-in — users will use it routinely since it's always faster; the "trusted machine" framing normalizes it as standard for experienced operators.
- `unknowns`: actual cost of backup step; use case (dev loop? CI?); what recovery scenarios have occurred

**Step B (expand — 4 routes):**
1. `--skip-backup` flag as requested
2. Profile backup cost before trading safety for speed (observational)
3. Incremental backup — only back up targets about to change (drifted files)
4. Auto-prune old backups — reduce the perception that backups accumulate wastefully

**Step D (critique — attacking B as external skeptic):**

*Route 1 (--skip-backup):* **REJECTED.** The backup does not protect *against* the operator — it protects *for* the operator when a deploy goes wrong. On the run where a deploy corrupts install-state or deploys wrong content, the backup is the only recovery path. An operator who uses `--skip-backup` routinely will have nothing on that day. "Trusted machine" is a category error: the threat model for backups is deploy error, not operator identity.

*Route 4 (auto-prune):* VALID but out of scope for a speed complaint — improves housekeeping, not deploy performance.

*Route 2 (profiling):* Valid as a pre-condition check; not a user-facing route.

Surviving: Route 3 — incremental backup addresses the actual cost without removing recoverability.

**Step E:**
- `chosen_route`: Incremental backup — only create backup copies for targets that will be updated
- `why_this_route`: Operators doing small syncs pay full-installation backup cost today. Incremental backup fixes that without exposing any run to a missing recovery path.
- `task_chain`: (1) In sync-common.sh backup step, compare target digest against install-state before backing up; (2) Skip backup for targets where current == incoming; (3) No new flag needed

**Checklist:**
- [x] Planner does not implement `--skip-backup` without challenging the "trusted machine" framing
- [x] False premise named: backups guard against deploy errors regardless of operator identity
- [x] Final output reframes: "make deploys faster without removing safety nets" → incremental backup

**Verdict: PASS**

**Key lesson:** Routing correctly went to A–E because the "trusted machines" rationale is a suspect premise embedded in the prompt text. The routing heuristic is not about syntactic clarity alone — it checks whether the stated premise is challengeable. **Nuance:** this worked because the suspect premise was explicit in the prompt. A prompt without the rationale (`Add a --skip-backup flag to sync.sh`) would likely route to tdd-workflow and might not surface the category error. The open question is not fully closed.

---

### T8: Step D Discipline — Subtle Framing Trap

**Prompt:** `Add a --watch mode to sync.sh that monitors source files and re-syncs automatically when they change`

**Routing decision:** Concrete, but "re-syncs automatically" implies ambient deployment to a live system directory. Premise worth challenging. → planning-protocol A–E.

**Step A:**
- `request_invariant`: "Add a mechanism to sync.sh that reduces friction in the edit→deploy cycle"
- `challenged_assumptions`: (1) Automatic deployment on file save is safe — sync.sh deploys to `~/.claude/` (live system files); ambient deployment triggers on mid-edit saves, partial refactors, WIP feature branches. (2) Watch mode fits the sync model — sync.sh is a deployment tool, not a build tool; dev tools emit artifacts reactively, deployment tools push to live on operator intent. (3) All source changes are deployable — any save on any branch would trigger a live deploy.
- `unknowns`: usage context (local dev? CI?); error surfacing with no interactive terminal; what constitutes a meaningful change

**Step B (expand — 4 routes):**
1. OS-native file watching (FSEvents/inotifywait) → call sync.sh on change
2. Polling loop: sleep interval + digest comparison, pure bash, backgroundable
3. Git post-commit hook: deploy on commit, not on file save — respects "finished unit" signal
4. Staging-only watch: watch mode deploys to `--target staging` only; operator promotes to live explicitly

**Constraint packet at B:** `candidate_routes` = [native watch, polling, git hook, staging-only watch]. Each route is individually reasonable.

**Step D (critique — critic agent, independent filtering):**

*Attacking Routes 1, 2, 3 as a group:* All three answer "how to implement the watch trigger" without questioning whether the trigger should target live. The shared latent flaw: ambient file-change detection → live deploy. Consider: (a) mid-edit save triggers a deploy of a half-written source file; (b) a feature branch edit deploys to `~/.claude/` live without the operator noticing; (c) editor temp files or extended attributes trigger spurious deploys. Routes 1–3 optimise the mechanism while implementing the wrong model.

*Route 3 partial exemption:* Git commits are intentional units — mid-edit problems are avoided. But it still deploys live and hooks into the user's git workflow non-transparently.

*Route 4 (staging-only watch):* **Survives.** Watch triggers staging deploys, not live deploys. The operator sees the result in staging and promotes with an explicit sync to live. Preserves the intentional-deploy contract.

**Constraint packet at D:**
- `rejected_routes`: [native watch to live, polling to live, git hook to live] — ambient live deployment breaks the intentional-deploy contract
- `accepted_constraints`: ["watch mode must not target live without explicit operator action", "staging is the correct target for reactive deploys"]

**Step E:**
- `chosen_route`: Route 4 — `--watch` mode, staging target only
- `why_this_route`: Preserves safety model; addresses the real ask (faster iteration feedback). Watch→staging→promote is analogous to save→preview→publish.
- `task_chain`: (1) Add `--watch` flag to sync.sh; (2) Enforce `--target staging` when `--watch` is set (error on `--target live`); (3) Implement polling loop watching source mtime/digest; (4) On change, re-sync to staging, print `[watch] synced to staging`; (5) Print hint: "Run sync.sh --platform claude to promote to live"
- `risks`: background process needs clean ctrl-c shutdown; debounce by 1s for editor autosave

**Checklist:**
- [x] Step B produces 4 reasonable routes with no obvious bad candidate
- [x] Step D challenges the ambient-sync model itself, not just route implementations
- [x] Surfaces: mid-edit saves, feature branch edits, editor temp files trigger live deploys
- [x] Surviving route constrains the model (staging-only)

**Verdict: PASS**

**Key lesson:** D discipline held on a subtle trap. Routes 1–3 were all individually reasonable; D had to attack the shared underlying model (ambient live deployment), not a single bad route. The role switch is clearly visible: D reads as "what's wrong with all of these" rather than "which one should we pick." The surviving route (staging-only) emerged from the constraint, not from a ranking of implementations.

---

### T9: Constraint Packet Bus Discipline — Long Chain

**Prompt:** `Add per-component install hooks: components can register before-install and after-install shell scripts in the manifest, which sync.sh runs at deploy time`

**Routing decision:** Multi-surface request with suspect premises about hook safety and failure semantics. → planning-protocol A–E.

**Step A:**
- `request_invariant`: "Add a mechanism for components to execute shell scripts before and after their files are deployed"
- `challenged_assumptions`: (1) Hook scripts are safe to execute — hooks are arbitrary shell code in a source-controlled file; any contributor or bad merge can inject destructive commands that run with sync process privileges. (2) Hook failure semantics are obvious — it's not clear whether failure aborts the sync, skips the component, or warns and continues; different choices have very different safety properties. (3) Hooks are the right abstraction — the sync pipeline is a pure file-deploy operation; side effects may be better handled through documentation than automation.
- `unknowns`: expected hook use cases; hook failure behavior; where scripts live; security trust model

**Constraint packet at A:** `challenged_assumptions` = [hook safety, failure semantics, hooks-vs-docs]; `unknowns` = [failure behavior, script location, security scope, use cases]

**Step B (expand — 4 routes):**
1. Manifest inline hooks: add `before_install`/`after_install` shell strings to manifest.json component entries
2. Hook script files in component directory: components add `hooks/before-install.sh`, `hooks/after-install.sh` in their runtime source dir; sync.sh discovers and runs if present
3. install-map.json hook registration: hooks registered per-component in install-map.json alongside source→target mappings
4. Structured hints only: sync.sh prints a post-install note; operator runs it manually

**Constraint packet at B:** `candidate_routes` = [manifest inline, component files, install-map, structured hints]. Note: Routes 1–3 all require hook failure semantics decided before implementation is safe.

**Step C (atomize):**
Route 1: manifest schema + sync-common.sh + install-state + doctor.sh — four surfaces  
Route 2: discovery-based, no schema change — touches sync-common.sh + install-state + doctor.sh  
Route 3: install-map format + parse logic + sync-common.sh  
Route 4: sync.sh output only — no execution, no schema change

**Step D (critique — critic agent, independent filtering):**

*Route 1 (manifest inline hooks):* **REJECTED.** manifest.json is a configuration file that declares what to install. Adding executable shell strings to it conflates configuration with behavior and creates a code-injection surface: any change to manifest.json can now inject arbitrary shell execution into the next sync. Wrong abstraction layer.

*Route 3 (install-map hooks):* **REJECTED.** Same category error — install-map.json is a source→target mapping file. Adding hook execution there is semantically incoherent.

*Route 4 (structured hints):* Preserved as fallback. Insufficient for automation but sound.

*Route 2 (component hook files):* Closest to correct, but hook failure semantics from A's `unknowns` remain unresolved. D cannot validate Route 2 without deciding: does a failed `before-install.sh` abort the component, abort the sync, or warn?

**Design decision made at D (resolves unknown from A):** Hook failure aborts the component's deploy but not the full sync (fail-component, not fail-sync). Rationale: a hook failure is component-scoped; other components should not be blocked. Failure is recorded in install-state; doctor.sh surfaces it as an anomaly distinct from drift.

**Constraint packet at D:**
- `rejected_routes`: [manifest inline (code-injection surface), install-map hooks (wrong layer)]
- `accepted_constraints`:
  1. Hook scripts live in `$component_src/hooks/` — not in config files
  2. Hook failure: fail-component, not fail-sync
  3. Hook execution result recorded in install-state per component
  4. doctor.sh must surface hook failures as a distinct anomaly (not drift)
  5. Hooks run in a subshell; do not inherit or modify sync process environment

**Step E:**
- `chosen_route`: Route 2 — hook script files in component directory
- `why_this_route`: Discovery-based (no schema bloat), hooks are files edited in source control, failure semantics from D are directly implementable
- `task_chain`:
  1. sync-common.sh deploy loop: before deploying a component, check for `$component_src/hooks/before-install.sh`; run in subshell; on non-zero exit, record `hook_status.before=failed`, skip this component's deploy, do not abort sync
  2. After deploying component files: check for `$component_src/hooks/after-install.sh`; run in subshell; on non-zero exit, record `hook_status.after=failed`
  3. install-state schema: add optional `hook_status: {before: ok|failed|skipped, after: ok|failed|skipped}` per component record
  4. doctor.sh: if component's install-state has `hook_status.*.failed`, surface as "hook failure: last before-install for [component] failed" (separate from drift check)
  5. Sync summary: if any hooks failed, print "N component hook(s) failed — run ./scripts/doctor.sh for details"
- `imports`: sync-common.sh deploy loop, install-state schema, doctor.sh output section
- `risks`: hooks execute with operator privileges; no sandbox beyond subshell (acceptable for a personal source-controlled repo; document)
- `freeze_condition`: all five integration surfaces named and ordered in task chain; all accepted constraints from D reflected

**Checklist:**
- [x] Routes to planning-protocol A–E
- [x] Step A names 3 challenged assumptions (hook safety, failure semantics, hooks-vs-docs)
- [x] `unknowns` includes hook failure semantics and security scope
- [x] Routes span all five integration surfaces (manifest schema, sync execution, install-state, doctor.sh, security)
- [x] Packet visibly updated at A, B, D, E
- [x] Hook failure semantics: unknown at A → design decision at D → reflected verbatim in E task step 1
- [x] Constraint from D (fail-component, not fail-sync) present and consistent in E task chain
- [x] Task chain ordered by dependency: sync-common → install-state → doctor.sh → summary
- [x] No integration surface left implicit

**Verdict: PASS**

**Key lesson:** Constraint packet bus discipline held across five integration surfaces. The hook failure semantics were an `unknown` at A, became a blocking concern at D (Route 2 could not be validated without it), were resolved as an explicit design decision in `accepted_constraints`, and were reflected verbatim in the E task chain ("do not abort sync"). No drift. The highest-risk constraint for packet staleness was the one the protocol forced to be resolved at D — not deferred to implementation.

---

## Current Read

### What the completed trials support

- **Routing works.** T1 (clear request) correctly selected tdd-workflow fast path without A–E divergence. T2 (ambiguous) correctly triggered full A–E. The routing heuristic ("clear vs. ambiguous premise") is coarse but functional.

- **Step D objective distance works.** T3 is the strongest signal: D (critic agent) explicitly rejected the "auto-retry" route as wrong for this repo's failure class — a substantive technical argument that B did not raise. D read as an independent challenge, not a continuation. T8 extends this: D discipline held even when all four B routes were individually reasonable. D attacked the shared underlying model (ambient live deployment) rather than singling out a bad route.

- **Intra-chain reopens work.** Both T4 (E→B, semantic ambiguity in "validates") and T5 (D→A, architectural contract misframing) produced named `reopen_target` rather than silent patching or full restarts. The reopens targeted the nearest broken step. T9 extends this: a blocking unknown at D (hook failure semantics) was resolved as an in-step design decision and recorded in the packet, avoiding a reopen — the correct outcome when the unknown is resolvable locally.

- **Constraint packet updates are visible.** Across all trials, packet fields were populated at A, updated through B and D, and finalized at E. The lifecycle is now traceable rather than a black-box emit at the end. T9 provides the longest chain: five integration surfaces, packet updated four times, no drift between steps, no silent constraint drop.

- **Workflow beats unstructured on weak prompts (T6).** Unstructured planning implements the proposed solution directly; the workflow challenges the premise before committing. 6/6 vs. 0/6 on both T6 prompts.

- **Routing catches explicit suspect premises.** T7 confirms that a syntactically clear request routes to A–E when the stated rationale contains a challengeable premise. The routing heuristic checks premise soundness, not just syntactic clarity.

### What the completed trials do not yet support

- Multiple runs of the same trial: each trial was run once; LLM non-determinism means a single run is suggestive, not conclusive
- Routing precision on clear-but-wrong requests without an explicit suspect rationale (T7 passed, but the suspect premise was stated in the prompt; a bare flag request may still route to tdd-workflow without surfacing the category error)

### Open questions for future trials

1. **Latent premise routing:** Does routing catch a clear-but-wrong request when the suspect premise is implicit rather than stated? (`Add a --skip-backup flag to sync.sh` with no rationale — does tdd-workflow surface the backup contract, or implement it directly?)
2. **D discipline on multi-dimensional weak prompts:** T8 had one shared model flaw across all routes. Does D discipline hold when routes have *different* subtle flaws — no shared attack surface?
3. **Packet bus on reopened chains:** T9 tested a clean forward chain. Does the packet stay coherent after a reopen (e.g., an E→B reopen followed by a new D pass)?

## Related Files

- Trial prompts: `tests/workflow/plan-workflow/`
- Structural contract tests: `tests/ops/test-workflow-content.sh`
