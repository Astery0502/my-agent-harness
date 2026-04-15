# agile_par_registry.md

Single source of truth for parameter existence, section, required flag, default, and triggers.
Workflow reads this; never embeds parameter knowledge inline.

Access pattern:
- Step 0: read §Required gaps only (initialise required_gaps)
- Steps 2–3: read only the sections with gaps (one targeted read per section)

## Required gaps

Pre-defined required params for every run. Step 0 reads this section to initialise
required_gaps; Step 2 reads it to generate the structured prompt form.

**Maintenance rule:** if a required=yes or required=yes* param is added to or removed
from any section below, update this table and the form template immediately.

| section | params | flag | form_group |
| --- | --- | --- | --- |
| &methodlist | phys | yes | Round 1 |
| &meshlist | domain_nx1, domain_nx2, domain_nx3, xprobmin1, xprobmax1, xprobmin2, xprobmax2, xprobmin3, xprobmax3 | yes | Domain |
| &filelist | base_filename | yes | I/O |
| &savelist | dtsave_dat | yes* | I/O |
| &stoplist | time_max | yes* | I/O |
| &boundlist | typeboundary_min1, typeboundary_max1, typeboundary_min2, typeboundary_max2, typeboundary_min3, typeboundary_max3 | yes | Boundaries |

### Step 2 form template

Step 2 Round 2 renders this form. Pre-fill any param already in state.
Omit dtsave_dat / time_max if waived. Boundaries: type only, no N.

```
=== Domain ===
domain_nx1/2/3 = ___ ___ ___
xprob  x [___, ___]  y [___, ___]  z [___, ___]

=== I/O ===
base_filename = ___   dtsave_dat = ___   time_max = ___

=== Boundaries (type per face: periodic | cont | symm | asymm | special) ===
min1: ___  max1: ___  min2: ___  max2: ___  min3: ___  max3: ___
```

---

Row schema: `| parameter | required | default | trigger | notes |`
- required=yes:  must ask if missing and no default
- required=yes*: must ask if missing AND waiver condition (stated in notes) is not met in state
- required=no:   use default or skip
- trigger: → &xxx_list or → hook:name; blank if none
- notes: one-line purpose; omit if obvious

---

## &filelist

| parameter | required | default | trigger | notes |
|---|---|---|---|---|
| base_filename | yes | — | | output path stem; e.g. 'output/run' |
| restart_from_file | no | undefined | → restart chain | path stem to restart from (no extension); triggers reset_time/reset_it ask |
| typefilelog | no | normal | | 'normal'\|'special'\|'regression_test' |
| autoconvert | yes | F | | convert to VTK etc. during run |
| convert_type | yes | vtuBCCmpi | | vtuCC\|vtuBCC\|pvtuCCmpi\|tecplot\|... |
| saveprim | yes | T | | save primitive (T) or conservative (F) variables |
| nwauxio | yes | 0 | → hook:usr_aux_output + hook:usr_add_aux_names | extra output vars; hooks needed if >0 |
| snapshotnext | no | 0 | | index of next snapshot to write |

---

## &savelist

At least one save trigger is required (any of: dtsave_dat, dtsave_log, dtsave_slice, dtsave_collapsed, dtsave_custom, ditsave_log, ditsave_dat, itsave, tsave).

| parameter | required | default | trigger | notes |
|---|---|---|---|---|
| dtsave_log | no | — | | write log every N time units; raw form: dtsave(1) |
| dtsave_dat | yes* | — | | *waived if any other save trigger in state: dtsave_log, dtsave_slice, dtsave_collapsed, dtsave_custom, ditsave_log, ditsave_dat, itsave, tsave |
| dtsave_slice | no | — | | write 2D slices every N time units; raw form: dtsave(3) |
| dtsave_collapsed | no | — | | write collapsed (integrated) output; raw form: dtsave(4) |
| dtsave_custom | no | — | | write analysis output; raw form: dtsave(5) |
| ditsave_log | no | — | | write log every N iterations |
| ditsave_dat | no | — | | write snapshot every N iterations |
| itsave | no | — | | explicit save iterations; array form: itsave(i,ifile) |
| tsave | no | — | | explicit save times; array form: tsave(i,ifile) |
| time_between_print | no | 30.0 | | wall-clock seconds between progress prints |

---

## &stoplist

At least one stop condition required (any of: time_max, it_max, wall_time_max).

| parameter | required | default | trigger | notes |
|---|---|---|---|---|
| time_max | yes* | — | | *waived if it_max or wall_time_max in state |
| it_max | no* | — | | stop after this many iterations |
| wall_time_max | no | — | | stop after this many wall-clock hours |
| dtmin | no | 1.d-10 | | stop if dt shrinks below this |
| reset_time | no | F | | reset simulation time to time_init on restart |
| reset_it | no | F | | reset iteration count on restart |

---

## &methodlist

| parameter | required | default | trigger | notes |
|---|---|---|---|---|
| phys | yes | — | → physics namelist | must match compile-time PHYS flag: 'hd'\|'mhd'\|'ffhd' |
| time_stepper | no | threestep | | 'onestep'\|'twostep'\|'threestep'\|'fourstep'\|'fivestep'\|'rk4' |
| time_integrator | no | — | | overrides time_stepper if set; e.g. 'ssprk3' |
| flux_scheme | no | 20*'tvdlf' | | per-level: 'tvdlf'\|'hll'\|'hllc' |
| limiter | no | 20*'vanleer' | | per-level slope limiter |
| source_split_usr | no | F | | split (T) or unsplit (F) user sources |
| dimsplit | no | F | | dimensional splitting |
| H_correction | no | F | | H-correction for carbuncle fix |
| small_values_method | no | error | | 'error'\|'ignore'\|'replace'\|'average' |
| small_density | no | 1.d-15 | | |
| small_pressure | no | 1.d-15 | | |
| small_temperature | no | 1.d-15 | | |
| fix_small_values | no | F | | |
| check_small_values | no | T | | |

---

## &boundlist

| parameter | required | default | trigger | notes |
|---|---|---|---|---|
| nghostcells | no | 2 | | increase for high-order schemes |
| specialboundary | no | F | | set T if any face uses 'special' type; auto-set by feature trigger |
| internalboundary | no | F | | set T if usr_internal_bc is used |
| typeboundary_min1 | yes | — | → specialboundary if contains 'special' | N*'type'; N=nwfluxbc; types: periodic\|cont\|symm\|asymm\|special |
| typeboundary_max1 | yes | — | → specialboundary if contains 'special' | same as min1 |
| typeboundary_min2 | yes | — | → specialboundary if contains 'special' | |
| typeboundary_max2 | yes | — | → specialboundary if contains 'special' | |
| typeboundary_min3 | yes | — | → specialboundary if contains 'special' | |
| typeboundary_max3 | yes | — | → specialboundary if contains 'special' | |

---

## &meshlist

| parameter | required | default | trigger | notes |
|---|---|---|---|---|
| block_nx1 | no | 16 | | cells per block in dim 1 (no ghosts) |
| block_nx2 | no | 16 | | cells per block in dim 2 |
| block_nx3 | no | 16 | | cells per block in dim 3 |
| domain_nx1 | yes | — | | total cells at level 1, dim 1 |
| domain_nx2 | yes | — | | total cells at level 1, dim 2 |
| domain_nx3 | yes | — | | total cells at level 1, dim 3 |
| xprobmin1 | yes | — | | physical domain lower corner, dim 1 |
| xprobmax1 | yes | — | | physical domain upper corner, dim 1 |
| xprobmin2 | yes | — | | |
| xprobmax2 | yes | — | | |
| xprobmin3 | yes | — | | |
| xprobmax3 | yes | — | | |
| max_blocks | no | 4096 | | max blocks per MPI rank (memory limit) |
| refine_max_level | no | 1 | → AMR chain | >1 triggers refine_criterion + refine_threshold + ditregrid ask |
| iprob | no | 1 | | user-defined problem switch; read in usr_init_one_grid |

---

## &paramlist

| parameter | required | default | trigger | notes |
|---|---|---|---|---|
| courantpar | no | 0.7 | | CFL number |
| typecourant | no | maxsum | | 'maxsum'\|'summax'\|'minimum' |
| slowsteps | no | 10 | | ramp-up steps at start (reduces dt) |
| dtpar | no | -1.d0 | | if >0 force fixed dt, ignoring CFL |
| dtdiffpar | no | 0.5d0 | | diffusive CFL safety factor |

---

## &hd_list

Only needed if non-default hd_energy, hd_gamma, or tracers. Otherwise defaults are fine.

| parameter | required | default | trigger | notes |
|---|---|---|---|---|
| hd_energy | no | T | | solve energy equation |
| hd_gamma | no | 1.6667d0 | | adiabatic index |
| hd_n_tracer | no | 0 | → nwfluxbc+N; compile flag N_TRACER=N | number of passive tracers; must match N_TRACER compile flag |

---

## &mhd_list

| parameter | required | default | trigger | notes |
|---|---|---|---|---|
| mhd_energy | no | T | | solve energy equation |
| mhd_gamma | no | 1.6667d0 | | adiabatic index |
| mhd_glm_alpha | no | 0.5d0 | | GLM div-B diffusion ratio [0,1] |
| mhd_gravity | no | F | | gravitational source term |
| mhd_n_tracer | no | 0 | | passive tracers; must match N_TRACER compile flag |
| He_abundance | no | 0.1d0 | | helium abundance |
| stagger_grid | no | F | → hook:usr_init_vector_potential | constrained transport (CT) |

---

## &ffhd_list

| parameter | required | default | trigger | notes |
|---|---|---|---|---|
| ffhd_energy | no | T | | solve energy equation |
| ffhd_gamma | no | 1.6667d0 | | adiabatic index |
| ffhd_gravity | no | F | → hook:gravity_field | also needs -DGRAVITY compile flag |
| ffhd_radiative_cooling | no | F | → &rc_list | also needs -DCOOLING compile flag |
| ffhd_hyperbolic_thermal_conduction | no | F | → nwfluxbc+1 | also needs -DHYPERTC compile flag |
| ffhd_source_usr | no | F | → hook:addsource_usr | also needs -DSOURCE_USR compile flag |
| ffhd_pdivb | no | F | | p·∇·B correction; also needs -DPDIVB compile flag |
| He_abundance | no | 0.1d0 | | helium abundance (auto-fill) |

---

## &rc_list

Activated when ffhd_radiative_cooling=T (and -DCOOLING compile flag).

| parameter | required | default | trigger | notes |
|---|---|---|---|---|
| coolcurve | yes | — | | cooling curve name; e.g. 'Colgan_DM'\|'JCcorona' |
| coolmethod | no | exact | | 'explicit'\|'exact'\|'subcycle' |
| ncool | no | 4000 | | number of cooling table points |

---

## &usr_list

User-defined parameters; read by usr_params_read in mod_usr.fpp. Contents are problem-specific.

| parameter | required | default | trigger | notes |
|---|---|---|---|---|
| usr_list_enabled | no | F | → hook:usr_params_read | set T if simulation uses &usr_list; triggers usr_params_read hook |
| (problem-specific) | no | — | | define namelist /usr_list/ in mod_usr.fpp; sync to GPU with !$acc update device(...) after read |
