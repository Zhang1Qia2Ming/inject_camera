# Usage with Vitis IDE:
# In Vitis IDE create a Single Application Debug launch configuration,
# change the debug type to 'Attach to running target' and provide this 
# tcl script in 'Execute Script' option.
# Path of this script: J:\work\minieye\test_mipi\freetech_4ch\zu4_pcie_gmsl_tx1rx1_6gloop\vitis\iic_test_system\_ide\scripts\debugger_iic_test-default.tcl
# 
# 
# Usage with xsct:
# To debug using xsct, launch xsct and run below command
# source J:\work\minieye\test_mipi\freetech_4ch\zu4_pcie_gmsl_tx1rx1_6gloop\vitis\iic_test_system\_ide\scripts\debugger_iic_test-default.tcl
# 
connect -url tcp:127.0.0.1:3121
source E:/Xilinx/Vitis/2020.2/scripts/vitis/util/zynqmp_utils.tcl
targets -set -nocase -filter {name =~"APU*"}
rst -system
after 3000
targets -set -filter {jtag_cable_name =~ "Digilent JTAG-HS3 210299011758" && level==0 && jtag_device_ctx=="jsn-JTAG-HS3-210299011758-04721093-0"}
fpga -file J:/work/minieye/test_mipi/freetech_4ch/zu4_pcie_gmsl_tx1rx1_6gloop/vitis/iic_test/_ide/bitstream/design_1_wrapper.bit
targets -set -nocase -filter {name =~"APU*"}
loadhw -hw F:/kehu/freetech/zu4ev/code/test_1_2_6ch/zu4_pcie_gmsl_tx1rx1_6gloop/vitis/design_1_wrapper/export/design_1_wrapper/hw/design_1_wrapper.xsa -mem-ranges [list {0x80000000 0xbfffffff} {0x400000000 0x5ffffffff} {0x1000000000 0x7fffffffff}] -regs
configparams force-mem-access 1
targets -set -nocase -filter {name =~"APU*"}
set mode [expr [mrd -value 0xFF5E0200] & 0xf]
targets -set -nocase -filter {name =~ "*A53*#0"}
rst -processor
dow F:/kehu/freetech/zu4ev/code/test_1_2_6ch/zu4_pcie_gmsl_tx1rx1_6gloop/vitis/design_1_wrapper/export/design_1_wrapper/sw/design_1_wrapper/boot/fsbl.elf
set bp_48_12_fsbl_bp [bpadd -addr &XFsbl_Exit]
con -block -timeout 60
bpremove $bp_48_12_fsbl_bp
targets -set -nocase -filter {name =~ "*A53*#0"}
rst -processor
dow J:/work/minieye/test_mipi/freetech_4ch/zu4_pcie_gmsl_tx1rx1_6gloop/vitis/iic_test/Debug/iic_test.elf
configparams force-mem-access 0
targets -set -nocase -filter {name =~ "*A53*#0"}
con
