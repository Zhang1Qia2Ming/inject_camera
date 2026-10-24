# Three H2C channels into three VDMA frame queues, then the existing RAW12 CSI TX.
# Synthesis and bitstream stay in the Vivado GUI. This script only updates the BD.

open_project /data/work/gmsl_4ev/code/mipi_gmsl/zu4_pcie_gmsl_tx1rx1_6gloop/project_1.xpr
open_bd_design [get_files design_1.bd]

if {[llength [get_bd_cells -quiet xdma_0]] && [llength [get_bd_cells -quiet axi_vdma_2]]} {
  set need_width [expr {[get_property CONFIG.c_s_axis_s2mm_tdata_width [get_bd_cells axi_vdma_0]] != 128}]
  if {!$need_width} {
    puts "xdma_0 already exists"
    exit 0
  }
  puts "widening VDMA streams to 128 bits"
  proc unhook {pinpath} {
    set pin [get_bd_pins $pinpath]
    foreach n [get_bd_nets -quiet -of_objects $pin] {
      disconnect_bd_net $n $pin
    }
  }
  foreach i {0 1 2} {
    foreach p {s_axis_s2mm_tdata s_axis_s2mm_tvalid s_axis_s2mm_tlast s_axis_s2mm_tuser s_axis_s2mm_tready m_axis_mm2s_tdata m_axis_mm2s_tvalid m_axis_mm2s_tlast m_axis_mm2s_tuser m_axis_mm2s_tready} {
      unhook axi_vdma_$i/$p
    }
    foreach p {s2mm_tdata s2mm_tvalid s2mm_tlast s2mm_tuser s2mm_tready mm2s_tdata mm2s_tvalid mm2s_tlast mm2s_tuser mm2s_tready} {
      unhook lane_inject_$i/$p
    }
    connect_bd_intf_net [get_bd_intf_pins lane_inject_$i/s2mm] [get_bd_intf_pins axi_vdma_$i/S_AXIS_S2MM]
    connect_bd_intf_net [get_bd_intf_pins axi_vdma_$i/M_AXIS_MM2S] [get_bd_intf_pins lane_inject_$i/mm2s]
    set_property CONFIG.ASSOCIATED_BUSIF {h2c:s2mm} [get_bd_pins lane_inject_$i/h2c_clk]
    set_property CONFIG.ASSOCIATED_BUSIF {mm2s} [get_bd_pins lane_inject_$i/pix_clk]
    puts "vdma_$i before validate s2mm=[get_property CONFIG.c_s_axis_s2mm_tdata_width [get_bd_cells axi_vdma_$i]] mm2s=[get_property CONFIG.c_m_axis_mm2s_tdata_width [get_bd_cells axi_vdma_$i]]"
  }
  validate_bd_design
  set w [get_property CONFIG.c_s_axis_s2mm_tdata_width [get_bd_cells axi_vdma_0]]
  puts "after validate s2mm=$w mm2s=[get_property CONFIG.c_m_axis_mm2s_tdata_width [get_bd_cells axi_vdma_0]]"
  if {$w != 128} {
    error "s2mm stream stayed $w"
  }
  save_bd_design
  make_wrapper -files [get_files design_1.bd] -top -force
  set gen_wrap [file dirname [get_files design_1.bd]]/hdl/design_1_wrapper.v
  set top_wrap /data/work/gmsl_4ev/code/mipi_gmsl/zu4_pcie_gmsl_tx1rx1_6gloop/project_1.srcs/sources_1/imports/hdl/design_1_wrapper.v
  file copy -force $gen_wrap $top_wrap
  puts "VDMA width repair saved"
  exit 0
}

set rtl_dir /data/work/gmsl_4ev/code/mipi_gmsl/zu4_pcie_gmsl_tx1rx1_6gloop/project_1.srcs/sources_1/new
set sim_dir /data/work/gmsl_4ev/code/mipi_gmsl/zu4_pcie_gmsl_tx1rx1_6gloop/project_1.srcs/sim_1/new
add_files -norecurse [list \
  $rtl_dir/pulse_sync.v \
  $rtl_dir/frame_slot.v \
  $rtl_dir/raw12_gearbox.v \
  $rtl_dir/h2c_line_adapt.v \
  $rtl_dir/lane_inject.v]
add_files -fileset sim_1 -norecurse $sim_dir/tb_mipi_pcie.v
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# The cached module reference does not follow the HDL on its own.
# Rebuild the cell from the current mipi_gen ports, then put the three
# video interfaces and the pixel clock back.
proc reconnect_mipi_gen {} {
  if {[llength [get_bd_pins -quiet mipi_gen_0/tx1_pix_data]]} {
    return
  }
  puts "recreating mipi_gen_0 so the new frame and pixel ports exist"
  update_ip_catalog -rebuild -scan_changes
  delete_bd_objs [get_bd_cells mipi_gen_0]
  set cell [create_bd_cell -type module -reference mipi_gen mipi_gen_0]
  set_property -dict [list \
    CONFIG.H_Total {2274} \
    CONFIG.H_Active {960} \
    CONFIG.V_Total {2200} \
    CONFIG.V_Active {2166} \
    CONFIG.BYTENUM {5760} \
  ] $cell
  connect_bd_net [get_bd_pins clk_wiz_0/clk_out2] [get_bd_pins mipi_gen_0/clk]
  connect_bd_intf_net [get_bd_intf_pins mipi_gen_0/video_out] [get_bd_intf_pins axis_subset_converter_0/S_AXIS]
  connect_bd_intf_net [get_bd_intf_pins mipi_gen_0/video2] [get_bd_intf_pins axis_subset_converter_1/S_AXIS]
  connect_bd_intf_net [get_bd_intf_pins mipi_gen_0/video4] [get_bd_intf_pins axis_subset_converter_2/S_AXIS]
}

reconnect_mipi_gen
if {[llength [get_bd_pins -quiet mipi_gen_0/tx1_pix_data]] == 0} {
  puts "mipi_gen_0 pins:"
  foreach p [lsort [get_bd_pins mipi_gen_0/*]] { puts "  $p" }
  error "mipi_gen_0 did not pick up tx1_pix_data"
}

set ps [get_bd_cells zynq_ultra_ps_e_0]
set_property -dict [list \
  CONFIG.PSU__USE__S_AXI_GP2 {1} \
  CONFIG.PSU__USE__S_AXI_GP3 {1} \
  CONFIG.PSU__USE__S_AXI_GP4 {1} \
  CONFIG.PSU__SAXIGP2__DATA_WIDTH {128} \
  CONFIG.PSU__SAXIGP3__DATA_WIDTH {128} \
  CONFIG.PSU__SAXIGP4__DATA_WIDTH {128} \
] $ps

set xdma [create_bd_cell -type ip -vlnv xilinx.com:ip:xdma:4.1 xdma_0]
set_property -dict [list \
  CONFIG.axi_data_width {128_bit} \
  CONFIG.axisten_freq {250} \
  CONFIG.xdma_axi_intf_mm {AXI_Stream} \
  CONFIG.pf0_device_id {9034} \
  CONFIG.pl_link_cap_max_link_speed {8.0_GT/s} \
  CONFIG.pl_link_cap_max_link_width {X4} \
  CONFIG.pcie_blk_locn {X0Y0} \
  CONFIG.plltype {QPLL1} \
  CONFIG.xdma_rnum_chnl {3} \
  CONFIG.xdma_wnum_chnl {1} \
  CONFIG.xdma_num_usr_irq {4} \
  CONFIG.pf0_msi_enabled {true} \
  CONFIG.enable_gen4 {true} \
] $xdma

set ds [create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.1 util_ds_buf_pcie]
set_property CONFIG.C_BUF_TYPE {IBUFDSGTE} $ds
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 pcie_ref
set_property CONFIG.FREQ_HZ 100000000 [get_bd_intf_ports pcie_ref]
connect_bd_intf_net [get_bd_intf_ports pcie_ref] [get_bd_intf_pins util_ds_buf_pcie/CLK_IN_D]
connect_bd_net [get_bd_pins util_ds_buf_pcie/IBUF_DS_ODIV2] [get_bd_pins xdma_0/sys_clk]
connect_bd_net [get_bd_pins util_ds_buf_pcie/IBUF_OUT] [get_bd_pins xdma_0/sys_clk_gt]

create_bd_port -dir I pcie_rst_n
connect_bd_net [get_bd_ports pcie_rst_n] [get_bd_pins xdma_0/sys_rst_n]
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie_7x_mgt_rtl:1.0 pcie_mgt
connect_bd_intf_net [get_bd_intf_ports pcie_mgt] [get_bd_intf_pins xdma_0/pcie_mgt]

set rst250 [create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_pcie]
connect_bd_net [get_bd_pins xdma_0/axi_aclk] [get_bd_pins proc_sys_reset_pcie/slowest_sync_clk]
connect_bd_net [get_bd_pins xdma_0/axi_aresetn] [get_bd_pins proc_sys_reset_pcie/ext_reset_in]

set c2h0 [create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_c2h]
set_property -dict [list CONFIG.CONST_WIDTH {1} CONFIG.CONST_VAL {0}] $c2h0

proc connect_h2c {idx lane} {
  set xdma xdma_0
  foreach pin {tdata tvalid tlast tready} {
    set src [get_bd_pins -quiet $xdma/m_axis_h2c_${pin}_${idx}]
    if {$src eq ""} {
      set src [get_bd_pins -quiet $xdma/m_axis_h2c_${idx}_${pin}]
    }
    if {$src eq ""} {
      puts "XDMA pins:"
      foreach p [lsort [get_bd_pins $xdma/*]] { puts "  $p" }
      error "missing H2C${idx} $pin"
    }
    connect_bd_net $src [get_bd_pins ${lane}/h2c_${pin}]
  }
}

proc connect_axis_pair {src_cell src_prefix dst_cell dst_prefix pins} {
  foreach pin $pins {
    set s [get_bd_pins -quiet ${src_cell}/${src_prefix}${pin}]
    set d [get_bd_pins -quiet ${dst_cell}/${dst_prefix}${pin}]
    if {$s eq "" || $d eq ""} {
      error "cannot connect ${src_cell}/${src_prefix}${pin} -> ${dst_cell}/${dst_prefix}${pin}"
    }
    connect_bd_net $s $d
  }
}

set lanes {tx1 tx2 tx4}
set hps {S_AXI_HP0_FPD S_AXI_HP1_FPD S_AXI_HP2_FPD}
set hpclks {saxihp0_fpd_aclk saxihp1_fpd_aclk saxihp2_fpd_aclk}

for {set i 0} {$i < 3} {incr i} {
  set lane [create_bd_cell -type module -reference lane_inject lane_inject_$i]
  set vdma [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vdma:6.3 axi_vdma_$i]
  set_property -dict [list \
    CONFIG.c_num_fstores {3} \
    CONFIG.c_include_mm2s {1} \
    CONFIG.c_include_s2mm {1} \
    CONFIG.c_m_axi_mm2s_data_width {128} \
    CONFIG.c_m_axi_s2mm_data_width {128} \
    CONFIG.c_mm2s_linebuffer_depth {512} \
    CONFIG.c_s2mm_linebuffer_depth {512} \
    CONFIG.c_mm2s_genlock_mode {0} \
    CONFIG.c_s2mm_genlock_mode {0} \
    CONFIG.c_use_mm2s_fsync {1} \
    CONFIG.c_use_s2mm_fsync {2} \
    CONFIG.c_include_s2mm_sf {0} \
    CONFIG.c_include_mm2s_dre {0} \
    CONFIG.c_include_s2mm_dre {0} \
  ] $vdma
  set_property CONFIG.c_m_axis_mm2s_tdata_width 128 $vdma
  set_property CONFIG.c_s_axis_s2mm_tdata_width 128 $vdma
  puts "vdma_$i axis mm2s=[get_property CONFIG.c_m_axis_mm2s_tdata_width $vdma] s2mm=[get_property CONFIG.c_s_axis_s2mm_tdata_width $vdma] mem mm2s=[get_property CONFIG.c_m_axi_mm2s_data_width $vdma] s2mm=[get_property CONFIG.c_m_axi_s2mm_data_width $vdma]"

  set sc [create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_hp_$i]
  set_property -dict [list CONFIG.NUM_SI {2} CONFIG.NUM_MI {1}] $sc

  connect_bd_net [get_bd_pins xdma_0/axi_aclk] [get_bd_pins lane_inject_$i/h2c_clk]
  connect_bd_net [get_bd_pins proc_sys_reset_pcie/peripheral_reset] [get_bd_pins lane_inject_$i/h2c_rst]
  connect_bd_net [get_bd_pins clk_wiz_0/clk_out2] [get_bd_pins lane_inject_$i/pix_clk]
  connect_bd_net [get_bd_pins proc_sys_reset_mipi/peripheral_reset] [get_bd_pins lane_inject_$i/pix_rst]
  connect_h2c $i lane_inject_$i

  connect_bd_net [get_bd_pins xdma_0/axi_aclk] [get_bd_pins axi_vdma_$i/s_axis_s2mm_aclk]
  connect_bd_net [get_bd_pins xdma_0/axi_aclk] [get_bd_pins axi_vdma_$i/m_axi_s2mm_aclk]
  connect_bd_net [get_bd_pins xdma_0/axi_aclk] [get_bd_pins axi_vdma_$i/m_axi_mm2s_aclk]
  connect_bd_net [get_bd_pins clk_wiz_0/clk_out2] [get_bd_pins axi_vdma_$i/m_axis_mm2s_aclk]
  connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_vdma_$i/s_axi_lite_aclk]
  connect_bd_net [get_bd_pins proc_sys_reset_pcie/peripheral_aresetn] [get_bd_pins axi_vdma_$i/axi_resetn]

  connect_bd_net [get_bd_pins lane_inject_$i/s2mm_tdata]  [get_bd_pins axi_vdma_$i/s_axis_s2mm_tdata]
  connect_bd_net [get_bd_pins lane_inject_$i/s2mm_tvalid] [get_bd_pins axi_vdma_$i/s_axis_s2mm_tvalid]
  connect_bd_net [get_bd_pins lane_inject_$i/s2mm_tlast]  [get_bd_pins axi_vdma_$i/s_axis_s2mm_tlast]
  connect_bd_net [get_bd_pins lane_inject_$i/s2mm_tuser]  [get_bd_pins axi_vdma_$i/s_axis_s2mm_tuser]
  connect_bd_net [get_bd_pins axi_vdma_$i/s_axis_s2mm_tready] [get_bd_pins lane_inject_$i/s2mm_tready]

  connect_bd_net [get_bd_pins axi_vdma_$i/m_axis_mm2s_tdata]  [get_bd_pins lane_inject_$i/mm2s_tdata]
  connect_bd_net [get_bd_pins axi_vdma_$i/m_axis_mm2s_tvalid] [get_bd_pins lane_inject_$i/mm2s_tvalid]
  connect_bd_net [get_bd_pins axi_vdma_$i/m_axis_mm2s_tlast]  [get_bd_pins lane_inject_$i/mm2s_tlast]
  connect_bd_net [get_bd_pins axi_vdma_$i/m_axis_mm2s_tuser]  [get_bd_pins lane_inject_$i/mm2s_tuser]
  connect_bd_net [get_bd_pins lane_inject_$i/mm2s_tready] [get_bd_pins axi_vdma_$i/m_axis_mm2s_tready]
  connect_bd_net [get_bd_pins lane_inject_$i/mm2s_fsync] [get_bd_pins axi_vdma_$i/mm2s_fsync]

  set name [lindex $lanes $i]
  connect_bd_net [get_bd_pins lane_inject_$i/frame_ok]    [get_bd_pins mipi_gen_0/${name}_frame_ok]
  connect_bd_net [get_bd_pins mipi_gen_0/${name}_frame_start] [get_bd_pins lane_inject_$i/frame_start]
  connect_bd_net [get_bd_pins mipi_gen_0/${name}_frame_done]  [get_bd_pins lane_inject_$i/frame_done]
  connect_bd_net [get_bd_pins lane_inject_$i/pix_data]  [get_bd_pins mipi_gen_0/${name}_pix_data]
  connect_bd_net [get_bd_pins lane_inject_$i/pix_valid] [get_bd_pins mipi_gen_0/${name}_pix_valid]
  connect_bd_net [get_bd_pins mipi_gen_0/${name}_pix_ready] [get_bd_pins lane_inject_$i/pix_ready]

  connect_bd_intf_net [get_bd_intf_pins axi_vdma_$i/M_AXI_S2MM] [get_bd_intf_pins smartconnect_hp_$i/S00_AXI]
  connect_bd_intf_net [get_bd_intf_pins axi_vdma_$i/M_AXI_MM2S] [get_bd_intf_pins smartconnect_hp_$i/S01_AXI]
  connect_bd_intf_net [get_bd_intf_pins smartconnect_hp_$i/M00_AXI] [get_bd_intf_pins zynq_ultra_ps_e_0/[lindex $hps $i]]
  connect_bd_net [get_bd_pins xdma_0/axi_aclk] [get_bd_pins smartconnect_hp_$i/aclk]
  connect_bd_net [get_bd_pins proc_sys_reset_pcie/peripheral_aresetn] [get_bd_pins smartconnect_hp_$i/aresetn]
  connect_bd_net [get_bd_pins xdma_0/axi_aclk] [get_bd_pins zynq_ultra_ps_e_0/[lindex $hpclks $i]]
}

# One unused C2H channel. tvalid stays low, so nothing is read back.
set c2h_valid [get_bd_pins -quiet xdma_0/s_axis_c2h_tvalid_0]
set c2h_last [get_bd_pins -quiet xdma_0/s_axis_c2h_tlast_0]
if {$c2h_valid eq ""} {
  puts "XDMA pins:"
  foreach p [lsort [get_bd_pins xdma_0/*]] { puts "  $p" }
  error "missing C2H tvalid"
}
connect_bd_net [get_bd_pins xlconstant_c2h/dout] $c2h_valid
if {$c2h_last ne ""} {
  connect_bd_net [get_bd_pins xlconstant_c2h/dout] $c2h_last
}

set nmi [get_property CONFIG.NUM_MI [get_bd_cells axi_interconnect_0]]
set_property CONFIG.NUM_MI [expr {$nmi + 3}] [get_bd_cells axi_interconnect_0]
for {set k 0} {$k < 3} {incr k} {
  set mi [format M%02d_AXI [expr {$nmi + $k}]]
  set ack [format M%02d_ACLK [expr {$nmi + $k}]]
  set arst [format M%02d_ARESETN [expr {$nmi + $k}]]
  connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/$mi] [get_bd_intf_pins axi_vdma_$k/S_AXI_LITE]
  connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_interconnect_0/$ack]
  connect_bd_net [get_bd_pins proc_sys_reset_100m/peripheral_aresetn] [get_bd_pins axi_interconnect_0/$arst]
}

assign_bd_address
set vdma_off {0x80000000 0x80020000 0x80030000}
for {set i 0} {$i < 3} {incr i} {
  set segs [get_bd_addr_segs -of_objects [get_bd_intf_pins axi_vdma_$i/S_AXI_LITE]]
  if {[llength $segs] == 0} {
    puts "addr segs:"
    foreach s [get_bd_addr_segs] { puts "  $s" }
    error "no address segment for axi_vdma_$i"
  }
  set_property offset [lindex $vdma_off $i] $segs
  set_property range 64K $segs
}

validate_bd_design
save_bd_design
make_wrapper -files [get_files design_1.bd] -top -force
set gen_wrap [file dirname [get_files design_1.bd]]/hdl/design_1_wrapper.v
set top_wrap /data/work/gmsl_4ev/code/mipi_gmsl/zu4_pcie_gmsl_tx1rx1_6gloop/project_1.srcs/sources_1/imports/hdl/design_1_wrapper.v
file copy -force $gen_wrap $top_wrap
puts "BD saved. Wrapper copied to $top_wrap"
exit 0
