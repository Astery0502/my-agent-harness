---
name: agile-par
description: >
  Create or modify amrvac.par for an AGILE (GPU AMR) simulation.
  LOAD ONLY when the user explicitly invokes this skill by name (e.g. "/agile-par",
  "use agile-par", "load agile-par"). Do NOT auto-load based on topic keywords such
  as amrvac.par, par files, namelists, or simulation setup mentions alone.
---

## Inputs
- par file path (or "new")
- user's natural-language request

## Knowledge base
- references/agile_par_registry.md          (required keys, defaults)
- references/agile_par_connections.md       (trigger expansion)
- references/agile_par_request_mapping.md   (NL → parameter table; read in full)
- references/agile_par_knowledge_scan.md    (scan protocol for unknown parameters)
- assets/constraint-packet.md              (output template: constraint packet)
- assets/agile-state.md                    (output template: .agile_state.md)
- assets/agile-par-progress.md             (progress file template)

## Progress file

Path: `.agile_par_progress.md` alongside `amrvac.par`; if no par path yet, write in CWD.
Template: assets/agile-par-progress.md
Step order: [0, 1, 1a, 2, 3, 4, 5]
Purpose: persists `state`, `required_gaps`, `problem_description`, and `hooks_needed`
         across context resets.

Resume: Step 0 checks for this file; if found and phase != done, restore all fields
        and resume from the entry after last-step in the step order list.
Done: at Step 5, mark phase=done.

## Write-back protocol

Triggered inline — apply immediately when confirmed new knowledge surfaces; do not wait.
Match the format of existing rows in the target file.

**NL phrase rule** (Step 1a Stage 2, and Stage 3 after scan confirms)
  Target: references/agile_par_request_mapping.md

**Scan rule** (Step 1a Stage 3)
  Target: delegate to Update protocol in references/agile_par_knowledge_scan.md
  (handles registry + connections if a trigger is found)

**Connection rule** (any step — user reveals a feature→consequence link not in connections)
  Target: references/agile_par_connections.md §Feature triggers

**Registry rule** (any step — user names a parameter absent from registry, no scan needed)
  Target: references/agile_par_registry.md — matching §section

## Patch protocol

Patch = add missing namelists and parameters only; never modify or remove an existing
value. If a conflict is found between state and an existing value in the par file,
warn and ask the user before overwriting.

## Required gaps rule

required_gaps must never contain params that have trigger dependencies (connections).
Params with triggers are handled exclusively by Step 3's trigger loop.
This makes the Step 5 completeness gate safe: any param remaining in required_gaps
at Step 5 has no downstream trigger effects.

---

## Step -1 — Environment check

ACCESS: shell — check $AMRVAC_DIR
ACTION:
  1. if $AMRVAC_DIR is unset or path does not exist:
       STOP — ask user: "AMRVAC_DIR is not set. Please set it to the root of
       your AGILE source tree (e.g. export AMRVAC_DIR=/path/to/agile) and retry."
  2. else: continue to Step 0

---

## Step 0 — Quickscan (minimal questions, token-minimal)

ACCESS: check for .agile_par_progress.md alongside amrvac.par (or in CWD)
        read §Required gaps from references/agile_par_registry.md
        grep "&\w*list" in amrvac.par (if par file given) → existing sections and set params
ACTION:
  1. if progress file found and phase != done:
       1a. restore state, required_gaps, problem_description, hooks_needed from it
       1b. resume from the entry after last-step in step order list
  2. else (fresh start):
       2a. initialise state = {parameter → value} for all params set in par file (or {} if none)
       2b. initialise required_gaps = §Required gaps table from registry
       2c. remove any param already in state from required_gaps
       2d. extract plain-language summary of the physical problem from the user's request
       2e. if too vague: ask "In one sentence, what physical problem does this simulation model?"
           wait for user response
       2f. store answer as problem_description
       2g. write progress file — state, required_gaps, problem_description,
           pending_phrases=[], hooks_needed=[], last-step: 0, phase: active

---

## Step 1 — Request translation

ACCESS: references/agile_par_request_mapping.md (read in full)
ACTION:
  1. match user phrase → parameter=value pairs; add each matched pair to state
  2. for each addition: remove param from required_gaps if present
  3. collect all unmatched phrases → pending_phrases
  4. if pending_phrases is empty: write progress file (state, required_gaps, pending_phrases=[], last-step: 1)
     else: write progress file (state, required_gaps, pending_phrases, last-step: 1);
           dispatch to Step 1a for first pending phrase (Step 1a owns subsequent last-step writes)

---

## Step 1a — Unknown intent fallback

Run per pending phrase. On resume, restore pending_phrases from progress file and
continue with the next unresolved phrase.

ACCESS: grep references/agile_par_registry.md notes column for domain keywords from phrase
ACTION:
  Stage 1 — present candidates compactly:
    "I found these parameters related to [category]:
      &xxx_list:  param_a  — <one-line purpose>
    Do any of these match what you need?"

  if user confirms → Stage 2; if no candidate or user cannot confirm → Stage 3

  Stage 2 — on confirmation:
    1. add confirmed param to state
    2. remove from required_gaps if present
    3. apply NL phrase rule (write-back protocol)

  Stage 3 — unresolved:
    1. ask: "What should [concept] change about the simulation's physical behavior or output?"
    2. re-run category search
    3. if still unresolved: run knowledge scan (unknown parameter — see agile_par_knowledge_scan.md)
    4. after scan confirms the parameter:
         4a. apply scan rule (write-back protocol)
         4b. apply NL phrase rule for the original phrase (write-back protocol)
         4c. add to state; remove from required_gaps if present

  After each phrase resolution:
    1. check: if the user's response revealed a new parameter, connection, or a correction
              not already in the knowledge files, apply the relevant write-back rule
    2. remove resolved phrase from pending_phrases
    3. if pending_phrases not empty: write progress file (last-step: 1a); process next phrase
       if pending_phrases empty:     write progress file (last-step: 1)

---

## Step 2 — Fill core sections

ACCESS: read only sections with entries in required_gaps from references/agile_par_registry.md
ACTION:
  1. evaluate yes* waivers: for each required=yes* param in required_gaps:
       if waiver condition met (alternative already in state): remove from required_gaps

  Round 1 — phys (skip entirely if phys already in state; Step 1 write already covers it):
    2. ask: "What physics module? (hd | mhd | ffhd)"
    3. add answer to state; remove phys from required_gaps
    4. write progress file (phys now in state; crash-safe before Round 2)

  Round 2 — structured form for remaining required_gaps:
    5. for each param in required_gaps: check registry default column
         if default exists: apply default; add to state; remove from required_gaps;
                            record in progress file §Defaults applied as "  &section: param = value  (registry default)"
    6. ACCESS: Step 2 form template from references/agile_par_registry.md
    7. render form:
         blank fields = params still in required_gaps (need user input)
         pre-filled   = params already in state (shown for context only)
    8. parse response: only process blank fields as new answers; add to state; remove from required_gaps
       pre-filled values are not re-processed unless the user explicitly changes them
    9. check: if the user's response revealed a new parameter, connection, or a correction
              not already in the knowledge files, apply the relevant write-back rule
   10. write progress file (state, required_gaps, last-step: 2)

---

## Step 3 — Feature expansion and dependency chain

ACCESS: references/agile_par_connections.md §Feature triggers (evaluate against full state)
        references/agile_par_registry.md — targeted read for each newly opened section
ACTION:
  Pass 1 seeds from all params currently in state; subsequent passes seed only from
  params added during that pass.
  1. iterate until no new trigger fires:
       1a. on each pass, evaluate triggers keyed on seed params for that pass
       1b. for each trigger that fires:
             i.   if trigger opens a sub-namelist: read that section from registry
             ii.  ask for required=yes values absent from state; add to state
             iii. for required=yes* params: evaluate waiver condition; if not met, ask; add to state
             iv.  check connections "ask:" annotation; ask values listed there not already in state,
                  showing defaults as suggestions; apply registry defaults silently for all other
                  params in that section not already in state
             v.   accumulate hooks_needed for each hook the trigger requires
             vi.  if the user's response revealed a new parameter, connection, or a correction
                  not already in the knowledge files, apply the relevant write-back rule
             vii. write progress file (state, hooks_needed updated)
  2. write progress file (last-step: 3)  ← state and hooks already current; updates step marker only

---

## Step 4 — Boundary condition assembly

ACCESS: references/agile_par_connections.md §Physics triggers (for nwfluxbc formula)
ACTION:
  1. compute nwfluxbc from phys + active features in state
  2. if user provided "all periodic" or "all cont": apply nwfluxbc*'type' to all 6 faces; update state
     else: for each typeboundary_* face in state (type collected in Step 2):
               assemble final value as nwfluxbc*'type'; update state
               if type = 'special': set specialboundary=T in state
  3. write progress file (last-step: 4)

---

## Step 5 — STOP: Constraint Packet + State File

ACCESS: assets/constraint-packet.md, assets/agile-state.md
        references/agile_par_registry.md — default column for any remaining required_gaps
ACTION:
  1. completeness gate — for each param still in required_gaps:
       1a. if registry default exists: apply default silently; add to state; remove from gaps
       1b. if no default: collect all such params in one final prompt; add answers to state
             if user declines: apply registry default if one exists; otherwise warn and skip
       1c. proceed only when required_gaps is empty
  2. generate complete amrvac.par using patch protocol (patch existing or create fresh)
  3. emit constraint packet filled from accumulated state (template: assets/constraint-packet.md)
  4. write .agile_state.md alongside amrvac.par (template: assets/agile-state.md)
  5. write progress file (last-step: 5, phase: done)
  6. HARD STOP — do not begin mod_usr.fpp phase
