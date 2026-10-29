open_project /data/work/gmsl_4ev/code/mipi_gmsl/zu4_pcie_gmsl_tx1rx1_6gloop/project_1.xpr
open_bd_design [get_files design_1.bd]

puts "IPS [get_ips -quiet *lane_inject*]"
set ips [get_ips -quiet {design_1_lane_inject_0_0 design_1_lane_inject_1_0 design_1_lane_inject_2_0}]
if {[llength $ips] != 3} {
  puts "IP_LIST_FAIL $ips"
  exit 1
}
if {[catch {update_module_reference $ips} msg]} {
  puts "UPDATE_ERR <$msg>"
  puts "UPDATE_CODE <$::errorCode>"
  exit 1
}
puts "UPDATE_OK <$msg>"
puts "PINS [get_bd_pins lane_inject_0/s2mm_fsync]"

foreach i {0 1 2} {
  set pin [get_bd_pins axi_vdma_$i/s2mm_fsync]
  set nets [get_bd_nets -quiet -of_objects $pin]
  if {[llength $nets]} {
    disconnect_bd_net $nets $pin
  }
  connect_bd_net [get_bd_pins lane_inject_$i/s2mm_fsync] $pin
  set fs [get_property CONFIG.c_use_s2mm_fsync [get_bd_cells axi_vdma_$i]]
  puts "LANE$i fsync_cfg=$fs net=[get_bd_nets -quiet -of_objects $pin]"
  if {$fs != 1} {
    error "axi_vdma_$i s2mm fsync is not external"
  }
}

if {[llength [get_bd_cells -quiet xlconstant_s2mm_fsync]]} {
  delete_bd_objs [get_bd_cells xlconstant_s2mm_fsync]
}

validate_bd_design
save_bd_design
puts "BD_CONNECT_OK"
exit 0
