open_project /data/work/gmsl_4ev/code/mipi_gmsl/zu4_pcie_gmsl_tx1rx1_6gloop/project_1.xpr
open_bd_design [get_files design_1.bd]

set orphan [get_bd_nets -quiet xlconstant_s2mm_fsync_dout]
if {[llength $orphan]} {
  delete_bd_objs $orphan
  puts "DELETED_ORPHAN"
}
foreach i {0 1 2} {
  set pin [get_bd_pins axi_vdma_$i/s2mm_fsync]
  set src [get_bd_pins -quiet -of_objects [get_bd_nets -of_objects $pin] -filter {DIR == O}]
  puts "LANE$i src=$src"
  if {$src ne "/lane_inject_$i/s2mm_fsync"} {
    error "lane $i s2mm_fsync is not driven by lane_inject"
  }
}
validate_bd_design
save_bd_design

set bd [get_files design_1.bd]
generate_target all $bd
make_wrapper -files $bd -top -import -force
set_property top design_1_wrapper [current_fileset]
update_compile_order -fileset sources_1

foreach r {design_1_axi_vdma_0_0_synth_1 design_1_axi_vdma_1_0_synth_1 design_1_axi_vdma_2_0_synth_1} {
  set st [get_property STATUS [get_runs $r]]
  set nr [get_property NEEDS_REFRESH [get_runs $r]]
  puts "RUN $r STATUS $st NEEDS_REFRESH $nr"
  if {$nr} {
    reset_run $r
    puts "RESET $r"
  }
}

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
