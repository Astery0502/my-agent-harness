# AGILE simulation state

## Problem description
<one-to-three sentence plain-language summary>

## Physics
- module:   hd | mhd | ffhd
- nwfluxbc: N
- features: [list of active non-default features]

## Hooks required in mod_usr.fpp
- [ ] usr_init_one_grid
- [ ] usr_special_bc             (if special BC)
- [ ] usr_aux_output             (if nwauxio > 0)
- [ ] usr_add_aux_names          (if nwauxio > 0)
- [ ] usr_init_vector_potential  (if stagger_grid=T)
- [ ] gravity_field              (ffhd + GRAVITY)
- [ ] addsource_usr              (ffhd + SOURCE_USR)
- [ ] usr_params_read            (if &usr_list defined)
- [ ] usr_refine_grid            (if refine_criterion=0)

## Par file
- path: <relative path to amrvac.par>
- confirmed: false
