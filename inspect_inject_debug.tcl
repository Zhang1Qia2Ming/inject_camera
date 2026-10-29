open_hw_manager
connect_hw_server -url 127.0.0.1:3121
open_hw_target

set dev [lindex [get_hw_devices xczu4ev_0] 0]
if {$dev eq ""} {
    set dev [lindex [get_hw_devices] 0]
}
current_hw_device $dev
set_property PROBES.FILE \
    project_1.runs/impl_tx2/design_1_wrapper.ltx $dev
set_property FULL_PROBES.FILE \
    project_1.runs/impl_tx2/design_1_wrapper.ltx $dev
refresh_hw_device $dev

puts "HW_DEVICE $dev"
puts "HW_ILAS [get_hw_ilas -of_objects $dev]"
puts "HW_VIOS [get_hw_vios -of_objects $dev]"
foreach ila [get_hw_ilas -of_objects $dev] {
    puts "ILA $ila"
    foreach probe [get_hw_probes -of_objects $ila] {
        puts "ILA_PROBE $probe WIDTH=[get_property WIDTH $probe]"
    }
    run_hw_ila -trigger_now $ila
    wait_on_hw_ila $ila
    set data [upload_hw_ila_data $ila]
    write_hw_ila_data -force -csv_file /tmp/pcie_diag_capture.csv $data
    puts "ILA_CAPTURE /tmp/pcie_diag_capture.csv"
}
foreach vio [get_hw_vios -of_objects $dev] {
    puts "VIO $vio"
    foreach probe [get_hw_probes -of_objects $vio] {
        puts "VIO_PROBE $probe OUTPUT_VALUE=[get_property OUTPUT_VALUE $probe]"
    }
}

close_hw_manager
