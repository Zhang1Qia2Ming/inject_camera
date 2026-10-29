open_project project_1.xpr
open_run impl_tx2

set meta_cells [get_cells -hierarchical -filter \
    {NAME =~ *pcie_diag_0*axi_gray_meta_reg*}]
set meta_pins [get_pins -of_objects $meta_cells -filter {REF_PIN_NAME == D}]
puts "PCIE_DIAG_META_CELLS [llength $meta_cells]"
puts "PCIE_DIAG_META_PINS [llength $meta_pins]"
if {[llength $meta_pins] != 16} {
    error "expected 16 PCIe diagnostic CDC first-stage pins"
}

set lane_meta_cells [get_cells -hierarchical -filter \
    {NAME =~ *pcie_diag_0*lane_status_meta_reg*}]
set lane_meta_pins [get_pins -of_objects $lane_meta_cells \
    -filter {REF_PIN_NAME == D}]
puts "LANE_DIAG_META_CELLS [llength $lane_meta_cells]"
puts "LANE_DIAG_META_PINS [llength $lane_meta_pins]"
if {[llength $lane_meta_pins] != 16} {
    error "expected 16 lane diagnostic CDC first-stage pins"
}

report_exceptions -coverage -file /tmp/pcie_diag_exceptions.rpt
report_timing_summary -file /tmp/pcie_diag_timing_summary.rpt
report_route_status -file /tmp/pcie_diag_route_status.rpt

set worst_max [get_timing_paths -delay_type max -max_paths 1 -nworst 1]
set worst_min [get_timing_paths -delay_type min -max_paths 1 -nworst 1]
puts "FINAL_WNS [get_property SLACK $worst_max]"
puts "FINAL_WHS [get_property SLACK $worst_min]"

close_project
