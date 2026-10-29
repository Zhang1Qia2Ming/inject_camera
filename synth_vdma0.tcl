open_project /data/work/gmsl_4ev/code/mipi_gmsl/zu4_pcie_gmsl_tx1rx1_6gloop/project_1.xpr
reset_run design_1_axi_vdma_0_0_synth_1
launch_runs design_1_axi_vdma_0_0_synth_1 -jobs 8
wait_on_run design_1_axi_vdma_0_0_synth_1
puts "VDMA_SYNTH [get_property STATUS [get_runs design_1_axi_vdma_0_0_synth_1]]"
exit 0
