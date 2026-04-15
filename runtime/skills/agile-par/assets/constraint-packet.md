=== CONSTRAINT PACKET ===
Physics:   [hd | mhd | ffhd]
nwfluxbc:  N  →  typeboundary uses N*'...' per face
Features:  [list of active non-default features]
Hooks needed in mod_usr.fpp:
  [ ] usr_init_one_grid          (always)
  [ ] usr_special_bc             (if any 'special' BC)
  [ ] usr_aux_output             (if nwauxio > 0)
  [ ] usr_add_aux_names          (if nwauxio > 0)
  [ ] usr_init_vector_potential  (if stagger_grid=T)
  [ ] gravity_field              (ffhd + ffhd_gravity=T)
  [ ] addsource_usr              (ffhd + ffhd_source_usr=T)
  [ ] usr_params_read            (if &usr_list defined)
  [ ] usr_refine_grid            (if refine_criterion=0)

=== STOP: Confirm amrvac.par before mod_usr.fpp ===
