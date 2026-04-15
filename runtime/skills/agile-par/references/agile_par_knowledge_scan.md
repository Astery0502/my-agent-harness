# agile_par_knowledge_scan — Parameter Knowledge Extraction

## Purpose

Two triggers for running this scan:

1. **Initial population** — building or refreshing `agile_par_registry.md` or
   `agile_par_connections.md` from scratch.
2. **Unknown parameter** — user mentions a parameter not found in the registry.
   Run the targeted scan for that parameter's section, then append the result
   to the registry before continuing the workflow.

---

## Scan order and targets

Work through these layers in order. Each layer adds different knowledge.
Stop as soon as the parameter is found (for trigger 2).

### Layer 0 — Authoritative reference (read first)

**What:** Pre-scanned registry covering all common parameters and defaults.

**Where:** `doc/agile_codebase.md` — Section 20 (Par File Reference)

**How:** Read §20 top-to-bottom; extract every parameter block into registry rows.
Only proceed to Layers 1–4 for parameters absent from §20 or where a default value
appears to conflict.

**Note:** `$AMRVAC_DIR` is required for Layers 1–4 but not for Layer 0.
Layer 0 reads a doc-local file; the env check gates Layers 1–4 only.

---

### Layer 1 — Test par files (usage patterns)

**What:** Real working examples; the most reliable source of which parameters
are actually needed and what values are used in practice.

**Where:**

```
tests/hd/*/amrvac.par       → HD usage
tests/mhd/*/amrvac.par      → MHD usage
tests/ffhd/*/amrvac.par     → FFHD usage
```

Representative baselines to always include:
- `tests/hd/KH3D/amrvac.par` — minimal HD
- `tests/mhd/Orszag-Tang_3D/amrvac.par` — MHD with stagger_grid
- `tests/ffhd/TI3D/amrvac.par` — FFHD with cooling

**How:** Grep for `&<section>` blocks; extract parameter=value lines.
For each unique parameter record: section, observed value(s), which test used it.

---

### Layer 2 — Physics templates (authoritative defaults and types)

**What:** The `namelist /xxx_list/` declarations and the `read_params()`
subroutines that set defaults before reading. This is the ground truth for
what each parameter controls and what its default is.

**Where:**

```
src/hd/mod_hd_templates.fpp        → &hd_list   (line ~86: namelist declaration)
src/mhd/mod_mhd_templates.fpp      → &mhd_list  (line ~108: namelist declaration)
src/ffhd/mod_ffhd_templates.fpp    → &ffhd_list, &rc_list
```

**How:** For each physics file:
1. Find the `namelist /xxx_list/` line — lists all accepted parameters.
2. Find the `read_params()` or equivalent subroutine above it — assignment
   statements before the `read(unit_par, xxx_list)` call are the defaults.
3. For each parameter: name, default value (from assignment or `= .false.`
   pattern), brief purpose (from inline comment if present).

---

### Layer 3 — IO and global config (filelist, savelist, stoplist, paramlist)

**What:** Core framework namelists that every par file needs regardless of physics.

**Where:**

```
src/io/mod_input_output.fpp        → &filelist, &savelist, &stoplist, &paramlist
src/io/mod_config.fpp              → compile-time flags that interact with par params
src/io/mod_slice.fpp               → slice-related savelist parameters
src/io/mod_collapse.fpp            → collapse-related savelist parameters
```

**How:** Same pattern as Layer 2 — find `namelist /xxx_list/` then the
default-setting block just above the `read(unit_par, xxx_list)` call.

---

### Layer 4 — Mesh and AMR (meshlist, methodlist, boundlist)

**What:** Grid setup and solver parameters. Less often modified but needed
for every run.

**Where:**

```
src/amr/mod_initialize_amr.fpp     → &meshlist (domain_nx, xprobmin/max, block_nx, iprob)
src/amr/mod_amr_grid.fpp           → AMR refinement parameters
src/mod_global_parameters.fpp      → global variable declarations (cross-reference for types)
```

**How:** Same pattern. Note: `&methodlist` (phys=, flux_scheme, limiter,
time_stepper) may be in `mod_initialize_amr.fpp` or a top-level init file —
grep for `namelist /methodlist/` to locate it precisely.

---

## Extraction format

For each parameter found, produce one table row in this format:

| section | parameter | required | default | trigger | notes |
|---|---|---|---|---|---|
| &ffhd_list | ffhd_radiative_cooling | no | F | → &rc_list | enables cooling source |
| &meshlist | domain_nx1 | yes | — | | number of cells, x-direction |
| &paramlist | courantpar | no | 0.7 | | CFL number |

Column definitions:
- **required** — `yes` if no default exists and workflow must ask; `no` otherwise
- **default** — value from source code assignment; `—` if none (must ask)
- **trigger** — if setting this parameter implies adding another section or hook,
  note it here (cross-references `agile_par_connections.md`)
- **notes** — one-line purpose; omit if obvious from name

---

## Update protocol

After extraction, patch the knowledge base files:

1. **New parameter with no connections:** append row to the relevant section
   table in `agile_par_registry.md`.

2. **New parameter with trigger:** append row to registry AND append trigger
   row to the appropriate sub-table in `agile_par_connections.md`.

3. **Unknown parameter from user (trigger 2):** after appending, resume the
   workflow from the point where the unknown parameter was mentioned — do not
   restart from Step 0.

4. **Conflicting default:** trust the source code (Layer 2/3) over the test
   file (Layer 1). Note the discrepancy in the `notes` column.
