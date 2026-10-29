open_project /data/work/gmsl_4ev/code/mipi_gmsl/zu4_pcie_gmsl_tx1rx1_6gloop/project_1.xpr
open_bd_design [get_files design_1.bd]
set bd [get_files design_1.bd]
reset_target simulation $bd
generate_target simulation $bd -force
puts "SIM_DONE"
exit 0
