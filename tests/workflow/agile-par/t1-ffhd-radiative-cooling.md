# Trial T1: FFHD with Radiative Cooling (TI3D-like)

## Target behavior

FFHD physics with radiative cooling triggers `&rc_list`, computes `nwfluxbc = 3`,
and applies `3*'periodic'` to all six faces. No conditional hooks beyond cooling.

## Input prompt

```
I want to set up a new thermal instability simulation in 3D. I'll use FFHD physics
with radiative cooling, Colgan_DM cooling curve. 256^3 domain from 0 to 1 in all
dimensions, all periodic boundaries. Save snapshots every 0.1 time units, stop at
t=10. Call the output 'ti3d/run'.
```

## How to run

Run exactly as written in a Claude Code session where the harness is installed.

## What to observe

- [ ] All 7 core namelists are present in the output par
- [ ] `&ffhd_list` contains `ffhd_radiative_cooling = T`
- [ ] `ffhd_radiative_cooling = T` triggers `&rc_list` (Step 3 chain fires)
- [ ] `coolcurve = 'Colgan_DM'` appears in `&rc_list`
- [ ] `nwfluxbc = 3` (rho + mom(1..3) + e for FFHD 3D — no extra fields)
- [ ] All six `typeboundary_*` faces use `3*'periodic'`
- [ ] No `usr_init_vector_potential` or gravity hooks in `.agile_state.md`
- [ ] `.agile_state.md` is written alongside `amrvac.par`
- [ ] Skill issues a hard stop before any `mod_usr.fpp` discussion

## Pass condition

Constraint packet shows `nwfluxbc = 3`, `&rc_list` is present with the correct
cooling curve, all boundaries are periodic, and the skill halts at Step 5.

## Notes

If `nwfluxbc` is not 3, check whether the formula in `agile_par_connections.md`
§Physics triggers is being applied for FFHD 3D without HYPERTC.
