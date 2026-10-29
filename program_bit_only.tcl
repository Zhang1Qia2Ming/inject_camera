if {$argc != 1} {
    error "usage: program_bit_only.tcl <bit-file>"
}
set bit_file [lindex $argv 0]

open_hw_manager
connect_hw_server -url 127.0.0.1:3121
open_hw_target

set dev [lindex [get_hw_devices xczu4_0] 0]
if {$dev eq ""} {
    set dev [lindex [get_hw_devices] 0]
}
current_hw_device $dev
set_property PROGRAM.FILE $bit_file $dev
program_hw_devices $dev
puts "PROGRAMMED_BIT $bit_file"

close_hw_manager
