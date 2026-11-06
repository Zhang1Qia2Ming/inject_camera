open_hw_manager
connect_hw_server -url 127.0.0.1:3121
open_hw_target

set dev [lindex [get_hw_devices xczu4_0] 0]
if {$dev eq ""} {
    set dev [lindex [get_hw_devices] 0]
}
current_hw_device $dev

set ltx_file project_1.runs/impl_uyvy_mipi_diag/design_uyvy_wrapper.ltx
set csv_file /tmp/uyvy_mipi_diag.csv
if {$argc >= 1} {
    set ltx_file [lindex $argv 0]
}
if {$argc >= 2} {
    set csv_file [lindex $argv 1]
}
set_property PROBES.FILE $ltx_file $dev
set_property FULL_PROBES.FILE $ltx_file $dev
refresh_hw_device $dev

puts "HW_DEVICE $dev"
puts "HW_ILAS [get_hw_ilas -of_objects $dev]"
foreach ila [get_hw_ilas -of_objects $dev] {
    puts "ILA $ila"
    foreach probe [get_hw_probes -of_objects $ila] {
        puts "ILA_PROBE $probe WIDTH=[get_property WIDTH $probe]"
    }
    run_hw_ila -trigger_now $ila
    wait_on_hw_ila $ila
    set data [upload_hw_ila_data $ila]
    write_hw_ila_data -force -csv_file $csv_file $data
    puts "ILA_CAPTURE $csv_file"
}

close_hw_manager
