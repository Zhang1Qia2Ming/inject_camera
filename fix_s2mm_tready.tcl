open_project /data/work/gmsl_4ev/code/mipi_gmsl/zu4_pcie_gmsl_tx1rx1_6gloop/project_1.xpr
open_bd_design [get_files design_1.bd]

foreach i {0 1 2} {
  set c [get_bd_cells axi_vdma_$i]
  set_property CONFIG.c_use_s2mm_fsync 0 $c
  if {[catch {set_property CONFIG.c_s2mm_sof_enable 0 $c} msg]} {
    puts "SOF_SET_WARN $i $msg"
  }
}

validate_bd_design
foreach i {0 1 2} {
  set c [get_bd_cells axi_vdma_$i]
  set fs [get_property CONFIG.c_use_s2mm_fsync $c]
  set sof [get_property CONFIG.c_s2mm_sof_enable $c]
  set mm [get_property CONFIG.c_use_mm2s_fsync $c]
  puts "VDMA$i s2mm_fsync=$fs sof=$sof mm2s_fsync=$mm"
  if {$fs != 0 || $sof != 0 || $mm != 1} {
    error "vdma_$i fsync config not applied"
  }
}
save_bd_design

set bd [get_files design_1.bd]
generate_target all $bd
make_wrapper -files $bd -top -import -force
set_property top design_1_wrapper [current_fileset]
update_compile_order -fileset sources_1

reset_run synth_tx2
launch_runs impl_tx2 -to_step write_bitstream -jobs 8
wait_on_run impl_tx2
set st [get_property STATUS [get_runs impl_tx2]]
set pr [get_property PROGRESS [get_runs impl_tx2]]
puts "IMPL_STATUS $st"
puts "IMPL_PROGRESS $pr"
if {[get_property STATS.WNS [get_runs impl_tx2]] ne ""} {
  puts "IMPL_WNS [get_property STATS.WNS [get_runs impl_tx2]]"
}
if {$st ne "write_bitstream Complete!"} {
  exit 1
}
exit 0
