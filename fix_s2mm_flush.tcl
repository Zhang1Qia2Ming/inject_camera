open_project /data/work/gmsl_4ev/code/mipi_gmsl/zu4_pcie_gmsl_tx1rx1_6gloop/project_1.xpr
open_bd_design [get_files design_1.bd]
foreach i {0 1 2} {
  set c [get_bd_cells axi_vdma_$i]
  set_property CONFIG.c_flush_on_fsync 0 $c
}
validate_bd_design
foreach i {0 1 2} {
  set c [get_bd_cells axi_vdma_$i]
  set fs [get_property CONFIG.c_use_s2mm_fsync $c]
  set sof [get_property CONFIG.c_s2mm_sof_enable $c]
  set fl [get_property CONFIG.c_flush_on_fsync $c]
  set mm [get_property CONFIG.c_use_mm2s_fsync $c]
  puts "VDMA$i s2mm_fsync=$fs sof=$sof flush=$fl mm2s_fsync=$mm"
  if {$fs != 0 || $sof != 0 || $fl != 0 || $mm != 1} {
    error "vdma_$i config not applied"
  }
}
save_bd_design
generate_target all [get_files design_1.bd]
exit 0
