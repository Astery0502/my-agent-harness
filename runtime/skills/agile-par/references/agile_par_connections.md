# agile_par_connections.md

Dependency graph for the agile-par skill. Two sub-tables only.
Workflow reads this for physics expansion (Step 2) and feature trigger chains (Step 3).

---

## Physics triggers

Keyed by `phys=` value in `&methodlist`. Read at Step 2 (namelist opening) and Step 4 (nwfluxbc).

| phys | activates namelists | nwfluxbc formula | notes |
|---|---|---|---|
| hd   | (none required) | 5+N_TRACER | &hd_list optional; ask only if non-default gamma or tracers |
| mhd  | &mhd_list | 8 (3D) | — |
| ffhd | &ffhd_list | 3 (+1 if HYPERTC) | present full feature checklist |

---

## Feature triggers

Keyed by parameter=value. Iterated at Step 3 until no new trigger fires.

| parameter | condition | consequence | hooks needed |
|---|---|---|---|
| ffhd_radiative_cooling | =T | open &rc_list | — |
| ffhd_gravity | =T | — | gravity_field |
| ffhd_source_usr | =T | — | addsource_usr |
| ffhd_hyperbolic_thermal_conduction | =T | nwfluxbc +1 | — |
| stagger_grid | =T | — | usr_init_vector_potential |
| refine_max_level | >1 | ask: refine_criterion (default=3 Lohner), refine_threshold(:), ditregrid (default=1) | — |
| refine_criterion | =0 | — | usr_refine_grid |
| usr_list_enabled | =T | — | usr_params_read |
| typeboundary_* | contains 'special' | set specialboundary=T | usr_special_bc |
| nwauxio | >0 | confirm count | usr_aux_output, usr_add_aux_names |
| restart_from_file | set (not 'undefined') | ask: reset_time (default=F), reset_it (default=F) | — |
| hd_n_tracer | >0 | nwfluxbc +N; note N_TRACER=N compile flag also required | — |

---

## Extension protocol

- New physics module: append row to §Physics triggers; add registry section in agile_par_registry.md.
- New feature with side-effects: append row to §Feature triggers; add registry row.
- Workflow steps require no changes in either case.
