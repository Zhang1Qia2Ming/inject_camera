open_project project_1.xpr

update_compile_order -fileset sources_1

open_bd_design project_1.srcs/sources_1/bd/design_uyvy/design_uyvy.bd
update_module_reference [get_ips design_uyvy_mipi_gen_0_0]

proc disconnect_pin {pin_name} {
	set pin [get_bd_pins $pin_name]
	foreach net [get_bd_nets -quiet -of_objects $pin] {
		disconnect_bd_net $net $pin
	}
}

disconnect_pin ila_0/clk
disconnect_pin ila_0/probe0
disconnect_pin mipi_gen_0/dbg_clk

set_property -dict [list \
	CONFIG.C_NUM_OF_PROBES {4} \
	CONFIG.C_PROBE0_WIDTH {96} \
	CONFIG.C_PROBE1_WIDTH {1} \
	CONFIG.C_PROBE2_WIDTH {1} \
	CONFIG.C_PROBE3_WIDTH {1}] [get_bd_cells ila_0]

# Probe the actual PG260-facing AXIS signals after the subset converter.
# This distinguishes generator-side intent from the values accepted by CSI TX.
connect_bd_net [get_bd_pins clk_wiz_0/clk_out2] \
	[get_bd_pins ila_0/clk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] \
	[get_bd_pins mipi_gen_0/dbg_clk]
connect_bd_net \
	[get_bd_pins axis_subset_converter_0/m_axis_tuser] \
	[get_bd_pins mipi_csi2_tx_subsyst_0/s_axis_tuser] \
	[get_bd_pins ila_0/probe0]
connect_bd_net \
	[get_bd_pins axis_subset_converter_0/m_axis_tvalid] \
	[get_bd_pins mipi_csi2_tx_subsyst_0/s_axis_tvalid] \
	[get_bd_pins ila_0/probe1]
connect_bd_net \
	[get_bd_pins mipi_csi2_tx_subsyst_0/s_axis_tready] \
	[get_bd_pins axis_subset_converter_0/m_axis_tready] \
	[get_bd_pins ila_0/probe2]
connect_bd_net \
	[get_bd_pins axis_subset_converter_0/m_axis_tlast] \
	[get_bd_pins mipi_csi2_tx_subsyst_0/s_axis_tlast] \
	[get_bd_pins ila_0/probe3]

validate_bd_design
save_bd_design
generate_target all \
	[get_files project_1.srcs/sources_1/bd/design_uyvy/design_uyvy.bd]
set wrappers [make_wrapper -files \
	[get_files project_1.srcs/sources_1/bd/design_uyvy/design_uyvy.bd] -top]
foreach wrapper $wrappers {
	if {![llength [get_files -quiet $wrapper]]} {
		add_files -norecurse $wrapper
	}
}
set source_set [get_filesets sources_1]
set original_top [get_property TOP $source_set]
set_property TOP design_uyvy_wrapper $source_set
update_compile_order -fileset sources_1

if {![llength [get_runs -quiet synth_uyvy_mipi_diag]]} {
	create_run synth_uyvy_mipi_diag \
		-part xczu4ev-sfvc784-2-i \
		-flow {Vivado Synthesis 2020} \
		-strategy {Vivado Synthesis Defaults} \
		-constrset constrs_1
	set_property SRCSET sources_1 [get_runs synth_uyvy_mipi_diag]
}
if {![llength [get_runs -quiet impl_uyvy_mipi_diag]]} {
	create_run impl_uyvy_mipi_diag \
		-parent_run synth_uyvy_mipi_diag \
		-flow {Vivado Implementation 2020} \
		-strategy {Vivado Implementation Defaults}
}
set_property INCREMENTAL_CHECKPOINT \
	[file normalize project_1.runs/impl_uyvy/design_uyvy_wrapper_routed.dcp] \
	[get_runs impl_uyvy_mipi_diag]

reset_run synth_uyvy_mipi_diag
launch_runs synth_uyvy_mipi_diag -jobs 2
wait_on_run synth_uyvy_mipi_diag
set synth_status [get_property STATUS [get_runs synth_uyvy_mipi_diag]]
puts "SYNTH_STATUS $synth_status"
if {$synth_status ne "synth_design Complete!"} {
	error "MIPI ILA synthesis failed: $synth_status"
}

launch_runs impl_uyvy_mipi_diag -to_step write_bitstream -jobs 2
wait_on_run impl_uyvy_mipi_diag
set impl_status [get_property STATUS [get_runs impl_uyvy_mipi_diag]]
puts "IMPL_STATUS $impl_status"
puts "IMPL_WNS [get_property STATS.WNS [get_runs impl_uyvy_mipi_diag]]"
if {$impl_status ne "write_bitstream Complete!"} {
	error "MIPI ILA implementation failed: $impl_status"
}

set_property TOP $original_top $source_set
update_compile_order -fileset sources_1
close_project
