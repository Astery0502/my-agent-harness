# Trial T2: MHD with stagger_grid (Orszag-Tang-like)

## Target behavior

MHD physics with `stagger_grid = T` computes `nwfluxbc = 8` (CT scheme — no GLM psi),
applies `8*'periodic'` to all six faces, and records `usr_init_vector_potential` in hooks.

## Input prompt

```
Create an amrvac.par for an Orszag-Tang vortex test in 3D. MHD physics,
stagger_grid=T. 128^3 cells, domain 0 to 2π in all dimensions, all periodic.
Run to t=1, save snapshots every 0.05. Output prefix 'ot3d/run'.
```

## How to run

Run exactly as written in a Claude Code session where the harness is installed.

## What to observe

- [ ] `&mhd_list` is present with `stagger_grid = T`
- [ ] `nwfluxbc = 8` (rho + 3 mom + e + 3 B; CT scheme omits GLM psi)
- [ ] All six `typeboundary_*` faces use `8*'periodic'`
- [ ] Constraint packet lists `usr_init_vector_potential` in required hooks
- [ ] `.agile_state.md` is written alongside `amrvac.par`
- [ ] Skill issues a hard stop before any `mod_usr.fpp` discussion

## Pass condition

Constraint packet shows `nwfluxbc = 8`, `stagger_grid = T` in `&mhd_list`,
all boundaries periodic, and `usr_init_vector_potential` listed as a required hook.

## Notes

If `nwfluxbc = 9`, the GLM psi field is being included despite `stagger_grid = T`.
Check the stagger_grid trigger in `agile_par_connections.md` — CT scheme should
suppress the GLM divergence-cleaning field.
