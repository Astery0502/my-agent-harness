# agile_par_request_mapping.md

Accumulated natural-language → parameter translation table.
Single source of truth for phrase matching; nothing else lives here.

Access pattern: read in full at every invocation (all rows needed for matching).

Extension protocol: after each human clarification that confirms a new mapping
(Step 1a Stage 2), append one row. Never add speculatively; only after human confirmation.
Row schema: `| User phrase | Maps to |`

---

| User phrase | Maps to |
| --- | --- |
| "FFHD physics" | methodlist: phys=ffhd |
| "MHD physics" | methodlist: phys=mhd |
| "HD physics" | methodlist: phys=hd |
| "stagger_grid=T" | mhd_list: stagger_grid=T |
| "I want cooling" | ffhd_list: ffhd_radiative_cooling=T + &rc_list |
| "[CurveName] cooling curve" | rc_list: coolcurve='CurveName' |
| "I want AMR / adaptive mesh" | meshlist: refine_max_level >1 + Step 3 AMR chain |
| "periodic in [dim]" | boundlist: typeboundary_min[N]/max[N]='periodic' for named dims |
| "continuous / cont / zero gradient in [dim]" | boundlist: typeboundary_min[N]/max[N]='cont' for named dims |
| "I want slices" | savelist: dtsave_slice, nslices, slicedir, slicecoord |
| "I want to restart" | filelist: restart_from_file + stoplist: reset_time, reset_it |
| "I want tracer" | hd_list: hd_n_tracer (note: N_TRACER compile flag also needed) |
| "I want gravity" | ffhd_list: ffhd_gravity / mhd_list: mhd_gravity |
| "I want diagnostic output" | filelist: nwauxio (note: usr_aux_output + usr_add_aux_names hooks needed) |
| "I want user source" | ffhd_list: ffhd_source_usr (note: addsource_usr hook needed) |
| "custom parameters / &usr_list / user-defined parameters" | usr_list: usr_list_enabled=T |
| "user-defined refinement criterion" | meshlist: refine_criterion=0 |
