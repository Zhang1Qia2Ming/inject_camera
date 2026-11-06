# Sensor8 UYVY 全链路验证手册

## 1. 验证目标

验证以下链路：

```text
MCAP/H265 转换文件
  -> 上位机 pcie_uyvy
  -> PCIe Gen3 x4 / XDMA H2C0
  -> 注入卡 DDR
  -> FPGA CSI-2 TX1
  -> MAX96717 / GMSL2
  -> ThorA MAX96712
  -> nvsipl_camera Sensor8_Out0
```

当前成功合同：

- 图像格式：UYVY422，CSI-2 `DT=0x1E`
- 分辨率：3840×2160
- CSI Word Count：7680 bytes/line
- 帧率：30 fps
- Sensor8对应：服务器H2C0、注入卡TX1、域控Sensor8

> 当前成功镜像通过JTAG加载。验证期间不要重启注入卡或服务器；重启后若SD卡
> 仍不是该镜像，需要重新JTAG加载或更新BOOT.bin。

## 2. 准备两个终端

- 终端A：服务器本机，检查PCIe并发送视频。
- 终端B：通过TBOX进入ThorA，运行`nvsipl_camera`。

开始前确认没有遗留进程：

```bash
pgrep -af pcie_uyvy
```

若有旧发送进程：

```bash
sudo pkill -TERM -f '^./host/pcie_uyvy'
```

## 3. 服务器检查PCIe

在终端A执行：

```bash
cd ~/zhang
sudo ./recover_pcie_inject.sh
```

成功输出必须包含：

```text
PCIe 注入卡通信恢复成功
Endpoint: 0000:04:00.0 (10ee:9034)
Kernel driver in use: xdma
Link: 8.0 GT/s PCIe, x4
```

再独立复核：

```bash
lspci -nnk -s 04:00.0
cat /sys/bus/pci/devices/0000:04:00.0/current_link_speed
cat /sys/bus/pci/devices/0000:04:00.0/current_link_width
ls -l /dev/xdma0_h2c_{0,1,2}
```

成功判据：

```text
10ee:9034
Kernel driver in use: xdma
8.0 GT/s PCIe
4
/dev/xdma0_h2c_0
/dev/xdma0_h2c_1
/dev/xdma0_h2c_2
```

若只有`2.5 GT/s`、端点消失或设备节点不存在，不要启动发送器；先复位注入卡，
再重新执行`recover_pcie_inject.sh`。

## 4. 上位机发送视频

进入工程：

```bash
cd /data/work/gmsl_4ev/code/mipi_gmsl/zu4_pcie_gmsl_tx1rx1_6gloop
```

确认三路输入文件存在：

```bash
ls -lh \
  host/frames_uyvy/tx1_forward_far.uyvy \
  host/frames_uyvy/tx2_forward_wide.uyvy \
  host/frames_uyvy/tx4_backward.uyvy
```

启动三路发送：

```bash
./host/pcie_uyvy \
  host/frames_uyvy/tx1_forward_far.uyvy \
  host/frames_uyvy/tx2_forward_wide.uyvy \
  host/frames_uyvy/tx4_backward.uyvy
```

程序需要先加载较大的帧文件，约等待1～3分钟。成功后应看到：

```text
lane 0 frames 30
lane 1 frames 30
lane 2 frames 30
```

三个计数应持续增加。Sensor8只依赖lane 0；lane 1/2当前还受TX2/TX4
GMSL物理支路状态影响。

以下信息表示发送失败：

```text
incomplete frame write
stopped after 0 frames
```

这种情况通常是JTAG重新下载后XDMA驱动仍绑定旧端点。停止发送器，重新执行：

```bash
cd ~/zhang
sudo ./recover_pcie_inject.sh
```

## 5. ThorA运行nvsipl验证Sensor8

在终端B登录：

```bash
cd ~/zhang
./enter_thorA_through_TBOX.sh
```

进入注入卡工作环境：

```bash
/root/pcie_inject_nvsipl_env.sh start
pkill -x nvsipl_camera 2>/dev/null || true
```

执行Sensor8单路采集：

```bash
nvsipl_camera \
  -c X3C_OX08D10_031_16v_hil \
  -m "0x0000 0x0000 0x0001 0x0000" \
  -R -0 -1 -2 -s -r 600 -v 4 \
  2>&1 | tee /root/nvsipl_sensor8_manual.log
```

`-r 600`用于约10分钟稳定性验证。成功时持续出现：

```text
Sensor8_Out0  Frame rate (fps): 29.999
```

第一次统计可能是约`28.999`或`29.499`，后续应稳定接近30 fps。

## 6. 验证结果统计

采集结束后在ThorA执行：

```bash
grep "Sensor8_Out0.*Frame rate" /root/nvsipl_sensor8_manual.log | tail -20

for p in \
  ICP_CAPTURE_TIMEOUT \
  BAD_INPUT \
  "CRC Error" \
  "Frame discontinuity"
do
  printf '%s=' "$p"
  grep -c "$p" /root/nvsipl_sensor8_manual.log || true
done
```

通过标准：

- Sensor8持续约30 fps；
- `ICP_CAPTURE_TIMEOUT=0`；
- `BAD_INPUT=0`；
- `CRC Error=0`；
- `Frame discontinuity=0`；
- 服务器lane 0计数持续增加；
- PCIe始终保持8.0 GT/s、x4。

当前HIL应用会打印`Queue timeout`，但在Sensor8_Out0持续30 fps且上述四类链路错误
均为0时，它不是ICP丢帧证据。不要只凭这一行判定链路失败。

## 7. MAX96717底层辅助证据

停止`nvsipl_camera`后，可执行：

```bash
/root/read_ser_0x42 /dev/i2c-9
```

成功链路应看到：

```text
link0 locked
ser addr=0x43 reg=0x000d data=0xbf
ser addr=0x43 reg=0x0112 data=0x8a
```

其中：

- `0x0112=0x8A`：MAX96717检测到有效CSI像素时钟和合法长包；
- `0x0112=0x0A`：未检测到有效输入，应检查发送进程、XDMA重绑和FPGA CSI输出。

## 8. 结束和恢复

服务器发送器按`Ctrl+C`停止。

ThorA恢复日常环境：

```bash
pkill -x nvsipl_camera 2>/dev/null || true
/root/pcie_inject_nvsipl_env.sh recover
```

不要在发送进程运行时复位、热插拔注入卡或执行PCIe恢复脚本。

## 9. 本次已验证证据

- PCIe：`10ee:9034`，XDMA，8.0 GT/s，x4；
- FPGA ILA：PG260入口`DT=0x1E`、`WC=7680`、`TVALID=TREADY=1`；
- MAX96717：`0x0112=0x8A`；
- Sensor8：连续约10分钟29.999 fps；
- `ICP_CAPTURE_TIMEOUT/BAD_INPUT/CRC/Frame discontinuity`计数均为0。

