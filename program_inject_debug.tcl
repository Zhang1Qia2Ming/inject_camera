open_hw_manager
connect_hw_server -url 127.0.0.1:3121
open_hw_target

set dev [lindex [get_hw_devices xczu4_0] 0]
if {$dev eq ""} {
    set dev [lindex [get_hw_devices] 0]
}
current_hw_device $dev
set_property PROGRAM.FILE \
    project_1.runs/impl_tx2/design_1_wrapper.bit $dev
set_property PROBES.FILE \
    project_1.runs/impl_tx2/design_1_wrapper.ltx $dev
set_property FULL_PROBES.FILE \
    project_1.runs/impl_tx2/design_1_wrapper.ltx $dev
program_hw_devices $dev
refresh_hw_device $dev

puts "PROGRAMMED_DEVICE $dev"
puts "HW_ILAS [get_hw_ilas -of_objects $dev]"
puts "HW_VIOS [get_hw_vios -of_objects $dev]"

close_hw_manager
