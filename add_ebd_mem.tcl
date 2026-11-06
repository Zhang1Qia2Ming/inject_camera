set root [file normalize [file dirname [info script]]]
open_project [file join $root project_1.xpr]

set mem_file [file join $root \
  project_1.srcs sources_1 new 997_uyvy_reserved_64.mem]
if {[llength [get_files -quiet $mem_file]] == 0} {
  add_files -norecurse -fileset sources_1 $mem_file
}
set_property FILE_TYPE {Memory Initialization Files} [get_files $mem_file]
set_property USED_IN {synthesis implementation simulation} [get_files $mem_file]

update_compile_order -fileset sources_1
close_project
puts "UYVY_RESERVED_MEM_ADDED $mem_file"
