# Trial T3: HD with AMR and Mixed BCs (KH3D-like)

## Target behavior

HD physics with 3 AMR levels fires the AMR trigger chain, computes `nwfluxbc = 5`,
and assembles mixed boundary conditions: periodic in x and z, continuous in y.

## Input prompt

```
I need a par file for a Kelvin-Helmholtz instability. HD physics, 256x256x64
domain from 0-1 × 0-1 × 0-0.25, periodic in x and z, continuous (zero gradient)
in y. I want 3 AMR levels. Stop at t=2, snapshots every 0.02. Base filename
'kh3d/run'.
```

## How to run

Run exactly as written in a Claude Code session where the harness is installed.

## What to observe

- [ ] `phys = 'hd'` in `&filelist` or equivalent
- [ ] `refine_max_level = 3` in `&amrvaclist`
- [ ] AMR trigger chain fires: `refine_criterion`, `refine_threshold`, `ditregrid` are asked
- [ ] `nwfluxbc = 5` (HD 3D: rho + 3 mom + e)
- [ ] x-min/x-max faces: `5*'periodic'`
- [ ] z-min/z-max faces: `5*'periodic'`
- [ ] y-min/y-max faces: `5*'cont'`
- [ ] No `usr_refine_grid` or special-BC hooks in `.agile_state.md`
- [ ] `.agile_state.md` is written alongside `amrvac.par`
- [ ] Skill issues a hard stop before any `mod_usr.fpp` discussion

## Pass condition

Constraint packet shows `nwfluxbc = 5`, correct per-face boundary types,
`refine_max_level = 3`, and no spurious hooks.

## Notes

If `typeboundary_*` applies the wrong count per face, verify that the BC assembly
step (Step 4) uses the computed `nwfluxbc` rather than a hardcoded value.
Mixed-BC prompts are the most common source of face-count errors.
