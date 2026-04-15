# AGILE par workflow progress

## Status
last-step: <0 | 1 | 1a | 2 | 3 | 4 | 5>
phase: active | done

## Pending phrases
<!-- Unmatched phrases from Step 1, resolved one-by-one in Step 1a. Clear when empty.
     Example: "I want adaptive mesh refinement", "high resolution near the boundary" -->

## Problem description
<one-to-three sentence plain-language summary; filled at Step 0>

## State
<!-- All resolved parameter=value pairs, grouped by namelist.
     Add one line per parameter as each step completes.
     Example:
       &methodlist: phys = ffhd
       &filelist:   base_filename = output/run
       &ffhd_list:  ffhd_radiative_cooling = T
-->

## Required gaps
<!-- Sections and parameters still needed (required=yes, not yet in state).
     Remove a line when the parameter is answered.
     Example:
       &meshlist: domain_nx1, domain_nx2, domain_nx3
       &meshlist: xprobmin1, xprobmax1, xprobmin2, xprobmax2, xprobmin3, xprobmax3
       &savelist: (group-required — need one of: dtsave_dat, dtsave_log, dtsave_slice, dtsave_collapsed, dtsave_custom, ditsave_log, ditsave_dat, itsave, tsave)
       &stoplist: (group-required — need one of: time_max, it_max, wall_time_max)
-->

## Defaults applied
<!-- Required params auto-filled from registry defaults at Step 2.
     Review and override before final output if needed.
     Example:
       &savelist: dtsave_log = 1.0  (registry default)
-->

## Hooks needed
<!-- Accumulated during Step 3. Add one line per hook as triggers fire.
     Example:
       usr_init_one_grid  (always)
       bfield             (ffhd, always)
       gravity_field      (ffhd + ffhd_gravity=T)
-->
