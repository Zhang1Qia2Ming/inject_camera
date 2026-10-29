# 第 0 路 S2MM 安全诊断设计

## 目标

在不让 ILA/VIO 直接加载 XDMA `axi_aclk` 的前提下，定位第 0 路首帧写入是否依次经过 `s2mm_fsync`、`s2mm_tready`、AXI-Stream 握手以及写完成。

## 范围与约束

- 保留现有 PCIe 独立诊断能力和低 32 位总线定义。
- 只观测 `lane_inject_0`，不启动三路全量发送。
- ILA、VIO 和调试桥输出域继续使用 PS `pl_clk0`。
- 观测逻辑不参与功能控制，不改变 XDMA、VDMA 或 MIPI 数据路径。
- 先通过 JTAG 下载验证，不覆盖 SD 卡上的现有 BOOT。
- 不进行 PCIe 热插拔，不提交 Git。

## 方案

扩展现有 `pcie_diag`，输入第 0 路 48 位 `dbg_bus`。在 XDMA `axi_aclk` 域中把短脉冲转换为粘滞事件，再经两级同步器送入 `pl_clk0` 域；持续电平也经两级同步后输出。ILA 继续采样 `pcie_diag` 的 48 位总线，因此不会直接给 XDMA 用户时钟增加 ILA/VIO 时钟负载。

高 16 位定义如下：

- bit 47：当前 `h2c_rst`
- bit 46：当前 `h2c_tvalid`
- bit 45：当前 `h2c_tready`
- bit 44：当前 `s2mm_tvalid`
- bit 43：当前 `s2mm_tready`
- bit 42：当前 `in_frame`
- bit 41：当前 `wr_ready`
- bit 40：见过 `s2mm_fsync`
- bit 39：见过 H2C 握手
- bit 38：见过 S2MM 握手
- bit 37：见过 `wr_start`
- bit 36：见过 `wr_done`
- bit 35：见过 `wr_abort`
- bit 34：见过 `s2mm_tlast`
- bit 33：见过 `s2mm_tready`
- bit 32：保留为 0

低 32 位维持 PCIe `axi_aclk` Gray 心跳、PERST#、链路和时钟存活状态的现有定义。

## 判定

1. 见过 fsync，但未见过 ready：VDMA S2MM 未完成帧同步装载。
2. 见过 ready，但无 H2C/S2MM 握手：检查主机 H2C 是否真正产生 `tvalid`。
3. 有 H2C 握手但无 S2MM 握手：检查 `lane_inject` 适配器输出。
4. 有 S2MM 握手但无完成，且出现 abort：检查帧长度、TLAST 和输入中断。
5. 出现完成：首帧已写入 DDR，再检查 MM2S 读出路径。

## 验证

1. 仿真证明每个短脉冲都能形成粘滞事件，并在 `pl_clk0` 域稳定可见。
2. 结构检查证明 ILA/VIO 仍由 `pl_clk0` 驱动，诊断桥接入第 0 路总线。
3. 完整综合、实现、DRC 和时序检查。
4. JTAG 下载后先确认 PCIe 仍能 Gen3 x4 枚举。
5. 只向第 0 路发送一帧，采集 ILA 并按上述位定义判断首个阻塞点。
