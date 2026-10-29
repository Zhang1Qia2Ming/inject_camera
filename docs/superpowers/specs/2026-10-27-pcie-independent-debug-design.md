# PCIe 独立时钟诊断设计

## 目标

在 PCIe 链路无法建立、XDMA `axi_aclk` 不运行时，仍能通过 JTAG ILA 判断 PERST# 是否释放，以及 XDMA PCIe PHY 是否产生工作时钟并建立链路。

## 范围

- 仅生成并通过 JTAG 下载诊断 bit，确认有效前不替换 SD 卡 `BOOT.bin`。
- 不修改 XDMA Gen3 x4 配置、三路 H2C 数据路径、VDMA 配置或 MIPI 注入逻辑。
- 不修改 BSP 库。

## 设计

使用 Zynq UltraScale+ PS `pl_clk0` 作为调试域时钟。该时钟不依赖 PCIe 链路，驱动现有 ILA 和 VIO。

增加一个 PCIe 诊断模块：

- 将外部 `pcie_rst_n` 双触发同步到 `pl_clk0`，记录当前值及是否出现过释放。
- 在 XDMA `axi_aclk` 域运行自由计数器，把高位同步到 `pl_clk0`，形成用户时钟心跳。
- 将 XDMA `user_lnk_up` 同步到 `pl_clk0`。
- 将上述状态组成固定宽度诊断总线接入现有 ILA。

诊断模块的各源时钟计数器不使用 `pl_clk0` 复位，避免待测复位或时钟缺失掩盖结果。跨时钟域信号只用于人工诊断，不参与功能控制。

## 判定规则

- `pcie_rst_n=0`：检查主板 PERST#、引脚 H8 和启动时序。
- 复位已释放但 `axi_aclk` 无心跳：检查 PCIe REFCLK 和 XDMA PCIe PHY/IP 初始化。
- `axi_aclk` 有心跳但 `user_lnk_up=0`：PHY 已获得工作时钟，但链路训练未进入 L0，继续检查 MGT 通道和信号完整性。
- `user_lnk_up=1`：链路已经建立，再检查主机枚举、桥窗口和 BAR。

## 验证

1. 先用结构检查确认 ILA/VIO 时钟来自 `pl_clk0`，诊断总线连接正确。
2. 运行 BD 校验、综合和实现，确认无关键 DRC，时序满足。
3. 只通过 JTAG 下载诊断 bit，刷新 Hardware Manager，确认 ILA 在 PCIe 未枚举时仍可发现。
4. 采集诊断总线，并与主机根端口 `LnkSta` 和 `lspci` 结果交叉验证。

PCIe `IBUFDS_GTE4/ODIV2` 已由 XDMA 内部专用 `BUFG_GT` 使用。器件不允许同一 ODIV2 再驱动控制条件不同的第二颗 `BUFG_GT`，因此诊断逻辑不直接加载参考时钟树，避免影响 PCIe 启动。

## 安全约束

- 不进行 PCIe 带电插拔。
- 端点未枚举前不加载 XDMA 驱动。
- 不覆盖现有 BOOT 文件。
- 不提交 Git。
