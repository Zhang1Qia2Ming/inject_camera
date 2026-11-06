set root [file dirname [file normalize [info script]]]
read_mem [file join $root project_1.srcs sources_1 new 997_uyvy_reserved_64.mem]
read_verilog [file join $root project_1.srcs sources_1 new mipi_gen_uyvy.v]
synth_design -top mipi_gen_uyvy -part xczu4ev-sfvc784-2-i
report_utilization -file [file join $root mipi_gen_ebd_utilization.rpt]
set brams [llength [get_cells -hierarchical -filter {
  PRIMITIVE_TYPE =~ BLOCKRAM.*
}]]
set luts [llength [get_cells -hierarchical -filter {
  PRIMITIVE_TYPE =~ CLB.LUT.*
}]]
puts "UYVY_RESERVED_PREFLIGHT_BRAM_CELLS $brams"
puts "UYVY_RESERVED_PREFLIGHT_LUT_CELLS $luts"
if {$brams == 0} {
  error "UYVY reserved-row ROM preflight failed: no block RAM primitive was inferred"
}
