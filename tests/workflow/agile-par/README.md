# agile-par Behavioral Trials

Behavioral trial prompts for the `agile-par` skill.

## How to run

1. Activate the skill (it should trigger automatically on par-related prompts)
2. Run the input prompt in a Claude Code session with the harness installed
3. Check each item in the "What to observe" checklist
4. Pass/fail is determined by the pass condition in each file

## What these verify

- Correct nwfluxbc computation per physics module and feature set
- Trigger chains fire for features that require sub-namelists (cooling, stagger, AMR, gravity)
- Boundary condition assembly matches phys-nwfluxbc combinations
- `.agile_state.md` is written
- Skill halts before `mod_usr.fpp`

## Trial index

| File | Scenario |
|------|----------|
| t1-ffhd-radiative-cooling.md | FFHD + cooling, all periodic, 3D |
| t2-mhd-stagger-grid.md | MHD + stagger_grid, all periodic, 3D |
| t3-hd-amr-mixed-bcs.md | HD + AMR, mixed BCs, 3D |
| t4-ffhd-gravity-usr.md | FFHD + gravity + usr_list + user-defined AMR |
