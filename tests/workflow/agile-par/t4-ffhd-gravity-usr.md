# Trial T4: FFHD with Gravity, usr_list, and User-Defined AMR

## Target behavior

FFHD physics with gravity fires the gravity hook, user-defined refinement criterion
fires `usr_refine_grid`, and `&usr_list` presence fires `usr_params_read`. All three
hooks appear in `.agile_state.md`. `nwfluxbc = 3` (no HYPERTC).

## Input prompt

```
Set up an FFHD simulation of a solar atmosphere in 3D. Domain is 64×64×96 cells,
physical size 20×20×30 in code units. Gravity on. 3 AMR levels with user-defined
refinement criterion. I have custom parameters in &usr_list. Save every 10 time
units, stop at t=500. Output prefix 'atm/run'.
```

## How to run

Run exactly as written in a Claude Code session where the harness is installed.
When asked about `refine_criterion`, answer `0` (user-defined).

## What to observe

- [ ] `ffhd_gravity = T` in `&ffhd_list`
- [ ] `ffhd_gravity = T` triggers `gravity_field` hook
- [ ] `refine_max_level = 3` triggers AMR chain; answering `refine_criterion = 0`
      triggers `usr_refine_grid` hook
- [ ] `&usr_list` present in par → triggers `usr_params_read` hook
- [ ] `nwfluxbc = 3` (FFHD 3D, no HYPERTC)
- [ ] `.agile_state.md` lists exactly these three hooks:
      `gravity_field`, `usr_refine_grid`, `usr_params_read`
- [ ] Skill issues a hard stop before any `mod_usr.fpp` discussion

## Pass condition

Constraint packet shows `nwfluxbc = 3` and all three hooks are recorded in
`.agile_state.md`. No extra or missing hooks.

## Notes

This trial exercises three independent trigger chains in a single run. If a hook
is missing, identify which trigger failed to fire and check the corresponding
entry in `agile_par_connections.md` §Feature triggers.
