open_project /data/work/gmsl_4ev/code/mipi_gmsl/zu4_pcie_gmsl_tx1rx1_6gloop/project_1.xpr
update_compile_order -fileset sources_1
set rc [catch {update_module_reference [get_ips design_1_mipi_gen_0_0]} msg]
puts "UPDATE_RC $rc $msg"
set bd [get_files design_1.bd]
generate_target all $bd
make_wrapper -files $bd -top -import -force
set_property top design_1_wrapper [current_fileset]
update_compile_order -fileset sources_1

if {[llength [get_runs -quiet synth_tx2]] == 0} {
  create_run synth_tx2 -flow {Vivado Synthesis 2020} -strategy {Vivado Synthesis Defaults}
}
if {[llength [get_runs -quiet impl_tx2]] == 0} {
  create_run impl_tx2 -parent_run synth_tx2 -flow {Vivado Implementation 2020} -strategy {Vivado Implementation Defaults}
}
reset_run synth_tx2
if {[llength [get_runs -quiet design_1_mipi_gen_0_0_synth_1]]} {
  reset_run design_1_mipi_gen_0_0_synth_1
}
launch_runs impl_tx2 -to_step write_bitstream -jobs 8
wait_on_run impl_tx2
set st [get_property STATUS [get_runs impl_tx2]]
set pr [get_property PROGRESS [get_runs impl_tx2]]
puts "IMPL_STATUS $st"
puts "IMPL_PROGRESS $pr"
if {[get_property STATS.WNS [get_runs impl_tx2]] ne ""} {
  puts "IMPL_WNS [get_property STATS.WNS [get_runs impl_tx2]]"
}
exit
