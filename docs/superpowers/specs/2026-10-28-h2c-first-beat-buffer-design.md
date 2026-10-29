# H2C 首拍缓冲修复设计

## 目标

消除 `lane_inject` 首帧启动时的 AXI-Stream 互等：即 XDMA 等待
`h2c_tready`，而 RTL 等待 `h2c_tvalid` 后才发 S2MM fsync 并拉高
`h2c_tready`。

## 证据

- 上层应用三路均在第一个 `write()` 超时，完成帧数为 0。
- XDMA 三路描述符均已提交，但 `completed_desc_count=0`。
- 在途 ILA 高 16 位为 `0x0a02`：`wr_ready=1`、
  `s2mm_tready=1`，但没有 `h2c_tvalid/tready`、fsync 或任一数据握手。
- 三路 VDMA MM2S/S2MM 均为 `CR=0x00010003`、
  `SR=0x00010000`，运行且无错误。

## 设计

在 `lane_inject` 内增加一个仅用于帧首拍的寄存器缓冲和四态控制：

1. `IDLE`：帧槽可用且首拍缓冲为空时向 XDMA拉高 ready。
2. 首拍握手：保存 `tdata/tlast`，同拍产生一次 S2MM fsync。
3. `WAIT_ARM`：对 XDMA反压16拍，不把缓存数据送给行适配器。
4. `FORWARD_FIRST`：把缓存首拍送给 `h2c_line_adapt`；其接受后进入
   `STREAM`，后续拍直接透传。
5. `wr_done` 或 `wr_abort` 后回到 `IDLE`，下一帧重复。

首拍在 fsync 前只进入本地寄存器，不进入 VDMA，因此不会破坏
S2MM 帧边界。保留现有 VIO fsync 覆盖和调试总线定义。

## 不采用的方案

- 空闲时预发 fsync：可能在 VDMA 尚未初始化时发出并永久丢失。
- 新增 VDMA AXI-Lite 运行状态输入：需要额外 BD 接线，超出最小修复范围。

## 验证

1. 新仿真令上游只有看到 ready 才给 valid；旧 RTL 必须因无 fsync而失败。
2. 修复后要求 fsync 先于首拍进入 S2MM，首拍内容和 TLAST 不变。
3. 现有 `tb_lane_s2mm_arm` 和全链路仿真继续通过。
4. 综合、实现、DRC 和时序通过。
5. JTAG 下载 bitstream，重启 A53 初始化后恢复 PCIe Gen3 x4。
6. 三路应用连续完成至少30帧；ILA必须见到 fsync、H2C/S2MM握手、
   `wr_start/wr_done/TLAST`，且不能见到 abort。

## 约束

- 不覆盖 SD 卡上的 `BOOT.bin`。
- 不进行 PCIe 热插拔。
- 不提交 Git。
