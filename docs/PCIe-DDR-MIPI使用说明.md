# PCIe → DDR → MIPI 三路注入使用说明

> 本文用于现场启动和验证。设计原理、完整时序和故障分析见《PCIe → DDR → MIPI 三路 RAW12 注入全流程报告》。

## 1. 当前适用范围

当前已验证的启动方式包括 JTAG 下载和 SD 冷启动。SD 卡中的新 `BOOT.bin` 已于 2026-10-29 完成三路连续发送回归。

SD 冷启动流程是：

```text
注入卡上电
→ BOOT.bin自动配置PL并启动A53
→ 检查PCIe Gen3 x4
→ 必要时执行Root Port rescan
→ 加载XDMA驱动
→ 三路发送RAW12
```

JTAG 调试流程是：

```text
JTAG下载bitstream
→ XSDB运行A53裸机程序
→ 检查PCIe Gen3 x4
→ 加载XDMA驱动
→ 三路发送RAW12
→ 检查VDMA、ILA和内核日志
```

当前 SD `BOOT.bin` 校验：

```text
001462cf7c66a07fc86b71170b543781
```

如果使用 SD 冷启动，第 3、4 节的 JTAG 下载步骤可以跳过。

## 2. 操作前检查

工程目录：

```bash
export ROOT=/data/work/gmsl_4ev/code/mipi_gmsl/zu4_pcie_gmsl_tx1rx1_6gloop
cd "$ROOT"
```

确认：

- 注入卡正常插在 PCIe 插槽中。
- JTAG 和串口已连接。
- 串口波特率为 115200。
- 不进行 PCIe 热插拔。
- 当前没有残留发送进程。

```bash
pgrep -a pcie_raw12 || echo "no sender"
```

## 3. 下载 FPGA bitstream

```bash
cd "$ROOT"
source /data/xilinx/Vivado/2020.2/settings64.sh
vivado -mode batch -source program_inject_debug.tcl
```

正确输出应包含：

```text
PROGRAMMED_DEVICE xczu4_0
HW_ILAS hw_ila_1
HW_VIOS hw_vio_1
```

当前已验证文件：

```text
project_1.runs/impl_tx2/design_1_wrapper.bit
MD5：7775412bc392f27ba792508ccfb9bcaf
```

可手动核对：

```bash
md5sum "$ROOT/project_1.runs/impl_tx2/design_1_wrapper.bit"
```

## 4. 启动 A53 初始化程序

不要执行 `rst -processor`：

```bash
printf '%s\n' \
  'connect -url tcp:127.0.0.1:3121' \
  'targets -set -filter {name =~ "*Cortex-A53*#0"}' \
  'stop' \
  "dow $ROOT/vitis/iic_test/pcie3_build/iic_test.elf" \
  'con' \
  'after 7000' \
  'exit' | /data/xilinx/Vitis/2020.2/bin/xsdb
```

串口应出现：

```text
vdma status
max_9296_done!
max_96717_done!
max_9296_mipien!
vdma restart after pcie clock
gmsl_debug_loop_start!
```

## 5. 验证 PCIe 枚举

### 5.1 查找设备

```bash
lspci -d 10ee: -nn
lspci -t
```

应找到：

```text
Xilinx Device 10ee:9034
```

不要假定 BDF 永远相同。下面命令以本机当前 `04:00.0` 为例，实际操作时替换成 `lspci` 查到的 BDF。

### 5.2 检查链路速度和宽度

```bash
EP=0000:04:00.0

cat /sys/bus/pci/devices/$EP/current_link_speed
cat /sys/bus/pci/devices/$EP/current_link_width
lspci -s ${EP#0000:} -vv | \
  rg 'LnkCap:|LnkSta:|Region 0:|DevSta:|Kernel driver'
```

成功标准：

```text
current_link_speed = 8.0 GT/s PCIe
current_link_width = 4
LnkSta包含Speed 8GT/s, Width x4
BAR0已分配
```

### 5.3 检查 COMMAND

```bash
sudo setpci -s ${EP#0000:} COMMAND.w
```

本机正常值为：

```text
0006
```

它表示 Memory Space Enable 和 Bus Master Enable 已置位。

如果设备不存在、速度不是 Gen3、宽度不是 x4，停止操作，不要继续发送数据。

如果 Root Port 已经是 Gen3 x4，但 `lspci -d 10ee:` 没有 Endpoint，并且注入卡是在主机启动后才上电，可执行：

```bash
echo 1 | sudo tee /sys/bus/pci/devices/0000:00:1c.0/rescan
lspci -d 10ee: -nn
```

Root Port BDF 必须先通过 `lspci -t` 确认，不能在其他机器上固定照抄 `00:1c.0`。

## 6. 加载 XDMA 驱动

确认没有发送程序后：

```bash
sudo rmmod xdma 2>/dev/null || true

sudo insmod \
  /data/work/gmsl_4ev/code/Pcie/pcie_test/dma_ip_drivers-master/XDMA/linux-kernel/xdma/xdma.ko \
  h2c_timeout=3
```

检查：

```bash
lsmod | rg '^xdma'
ls -l /dev/xdma0_h2c_0 /dev/xdma0_h2c_1 /dev/xdma0_h2c_2
dmesg | rg 'xdma' | tail -n 20
```

授权当前用户：

```bash
sudo chown "$USER":"$USER" \
  /dev/xdma0_h2c_0 /dev/xdma0_h2c_1 /dev/xdma0_h2c_2
sudo chmod 660 \
  /dev/xdma0_h2c_0 /dev/xdma0_h2c_1 /dev/xdma0_h2c_2
```

成功标准：

- `xdma` 模块已加载。
- 三个 H2C 节点都存在。
- 最新日志没有 probe failure、timeout 或 IOMMU fault。

## 7. 检查 RAW12 输入文件

```bash
stat -c '%n %s' \
  "$ROOT/host/frames/tx1_forward_far.raw" \
  "$ROOT/host/frames/tx2_forward_wide.raw" \
  "$ROOT/host/frames/tx4_backward.raw"
```

每个文件必须满足：

```text
文件大小 % 12,441,600 = 0
```

一次 `write()` 必须是一帧 3840×2160 RAW12。不要使用 4 KB 或其他任意长度短包进行验证。

## 8. 启动三路发送

```bash
"$ROOT/host/pcie_raw12" \
  "$ROOT/host/frames/tx1_forward_far.raw" \
  "$ROOT/host/frames/tx2_forward_wide.raw" \
  "$ROOT/host/frames/tx4_backward.raw"
```

通道对应关系：

```text
lane 0 / H2C0 → TX1 前视30
lane 1 / H2C1 → TX2 前向120
lane 2 / H2C2 → TX4 后向120
```

正常输出：

```text
lane 0 frames 30
lane 1 frames 30
lane 2 frames 30
...
```

每路应约 30 fps，三个计数持续增长且基本一致。

## 9. 运行控制

在发送程序标准输入中执行：

```text
stop 0
stop 1
stop 2
quit
```

`stop N` 只停止对应一路；另外两路必须继续发送。`quit` 停止全部通道并退出。

## 10. 验证 VDMA

```bash
printf '%s\n' \
  'connect -url tcp:127.0.0.1:3121' \
  'targets -set -filter {name =~ "*Cortex-A53*#0"}' \
  'stop' \
  'foreach base {0x80000000 0x80020000 0x80030000} { puts [format "VDMA 0x%08X" $base]; puts [mrd -force [expr {$base+0x00}] 2]; puts [mrd -force [expr {$base+0x30}] 2] }' \
  'con' \
  'exit' | /data/xilinx/Vitis/2020.2/bin/xsdb
```

正常值：

```text
MM2S CR = 00010003
MM2S SR = 00011000
S2MM CR = 00010003
S2MM SR = 00011000
```

三个 VDMA 的六个通道都应运行，`SR & 0x0FF0` 必须为 0。

## 11. 抓取 ILA

```bash
cd "$ROOT"
source /data/xilinx/Vivado/2020.2/settings64.sh
vivado -mode batch -source inspect_inject_debug.tcl
```

CSV 输出：

```text
/tmp/pcie_diag_capture.csv
```

正常情况下必须见到：

- S2MM fsync。
- H2C valid/ready 握手。
- S2MM valid/ready 握手。
- `wr_start`。
- `wr_done`。
- 行末 `TLAST`。
- 不出现 `wr_abort`。

最终验证时的状态为：

```text
lane_status = 0x2bf6
lane_seen = 0xfb
```

## 12. 检查内核错误

```bash
dmesg | rg -i \
  'xdma.*(timeout|fail|abort|error)|iommu.*fault|aer.*uncorrect'
```

注意区分旧日志与本次驱动加载后的新日志。验收窗口内不能新增 XDMA timeout、abort、IOMMU fault 或 AER Uncorrectable Error。

## 13. 验收标准

一次板内链路测试通过必须同时满足：

```text
PCIe Endpoint成功枚举
PCIe链路为Gen3 x4
三个H2C节点存在
三路完整write()持续成功
三路帧率约30 fps
六个VDMA通道运行且错误字段为0
ILA见到完整帧写入事件
ILA未见wr_abort
测试期间没有新增DMA或PCIe不可纠正错误
```

当前最终实测：

```text
测试时间：30.064秒
lane 0：900帧
lane 1：900帧
lane 2：900帧
总有效载荷：33,592,320,000字节
平均有效吞吐：1.117 GB/s
```

## 14. 常见异常

### 设备没有枚举

- 检查注入卡供电、PCIe 插槽、PERST# 和参考时钟。
- 重新通过 JTAG 下载 bitstream。
- 不要直接反复加载 XDMA 驱动。

### 枚举成功但第一帧超时

- 检查是否为 Gen3 x4。
- 检查三个 H2C 节点。
- 检查 ILA：如果 `h2c_tready=1` 但始终没有 `h2c_tvalid`，优先怀疑主机 DMA 状态。
- 如果此前进行过 PCIe 热插拔，执行总线复位；仍失败则整机冷关机断电。

### 恰好三帧后停止

三个 DDR 帧槽已满但没有被读侧释放。检查 MM2S、`frame_start`、`mm2s_fsync`、`pix_valid`、MIPI TX `tready` 和 `frame_done`。

### VDMA 错误

检查：

```text
HSIZE = 5760
STRIDE = 5760
VSIZE = 2160
单帧大小 = 12,441,600
```

## 15. 停止与下电

1. 在发送程序输入 `quit`。
2. 确认程序退出：

```bash
pgrep -a pcie_raw12 || echo "sender stopped"
```

3. 卸载驱动：

```bash
sudo rmmod xdma
```

4. 再进行整机下电。

不要在发送程序运行或 XDMA 描述符在途时热插拔注入卡。
