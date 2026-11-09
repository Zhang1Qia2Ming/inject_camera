# Sensor8/10/11 UYVY 全链路验证手册

> 更新日期：2026-11-09。本文同时覆盖底层 `nvsipl_camera` 验证和不改动生产
> `camera_service` 的三路实时网页预览。

## 1. 验证目标

验证以下链路：

```text
MCAP/H265 转换文件
  -> 上位机 pcie_uyvy
  -> PCIe Gen3 x4 / XDMA H2C0
  -> 注入卡 DDR
  -> FPGA CSI-2 TX1 / TX2 / TX4
  -> MAX96717 / GMSL2
  -> ThorA MAX96712
  -> NvSIPL ICP
  -> Sensor8 / Sensor10 / Sensor11
```

当前成功合同：

- 图像格式：UYVY422，CSI-2 `DT=0x1E`
- 分辨率：3840×2160
- CSI Word Count：7680 bytes/line
- 帧率：30 fps
- 三路映射：
  - H2C0 / TX1 / Sensor8：前远
  - H2C1 / TX2 / Sensor10：后视
  - H2C2 / TX4 / Sensor11：前广

> 成功镜像已制作成BOOT.bin。验证期间不要复位、热插拔注入卡；若重启后PCIe
> Endpoint未出现，先确认SD卡镜像和PL DONE，再执行PCIe恢复脚本。

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

三个计数应持续增加。当前TX1、TX2、TX4均已通过对应Sensor链路验证。

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

## 5. ThorA运行nvsipl验证

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

三路联合验证使用：

```bash
nvsipl_camera \
  -c X3C_OX08D10_031_16v_hil \
  -m "0x0000 0x0000 0x1101 0x0000" \
  -R -0 -1 -2 -s -r 1800 -v 4 \
  2>&1 | tee /root/nvsipl_sensor8_10_11_manual.log
```

成功时Sensor8、Sensor10、Sensor11均应持续接近30 fps。`-r 1800`用于三路
30分钟稳定性验收。

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
- Sensor8/10/11：三路联合连续30分钟稳定出帧；
- `ICP_CAPTURE_TIMEOUT/BAD_INPUT/CRC/Frame discontinuity`计数均为0。

## 10. 三路独立实时预览

### 10.1 作用与边界

`img_transfer_v2`是独立验证工具，直接消费NvSIPL ICP completion queue中的
UYVY帧，不经过生产`camera_service`的NvSciStream、Img2D或H265发布路径，也
不会替换生产`camera_service`。同一时刻不能让它与`camera_service`或
`nvsipl_camera`共同抢占相机资源。

代码位置：

```text
/home/ubuntu/zhang/hos_dev/multicast_2/hil_preview_direct.cpp
/home/ubuntu/zhang/hos_dev/multicast_2/CHilPreviewWriter.cpp
/home/ubuntu/zhang/img_transfer_v2/
```

ThorA部署位置：

```text
/root/img_transfer_v2/
```

### 10.2 启动、查看和恢复

保持上位机三路`pcie_uyvy`正在发送，然后在ThorA执行：

```bash
/root/img_transfer_v2/main.sh start
/root/img_transfer_v2/main.sh status
```

浏览器访问：

```text
http://172.31.17.9:8089/
```

网页提供三路动态MJPEG：

```text
/stream/sensor8.mjpg
/stream/sensor10.mjpg
/stream/sensor11.mjpg
```

网页预览主动限频到约10 fps，因此状态中的`9.98 fps`是预期值，不能与底层
30 fps链路吞吐混为一谈。实测停止`pcie_uyvy`后，约5秒内三路网页FPS归零；
恢复发送后自动恢复约9.98 fps，JPEG内容和时间戳均持续变化。

结束验证并恢复原业务环境：

```bash
/root/img_transfer_v2/main.sh stop
```

### 10.3 状态判据

```bash
/root/img_transfer_v2/main.sh status
```

正常输出应包含：

```text
preview: running
web:     running
Sensor8_Out0  Frame rate (fps): 约9.98
Sensor10_Out0 Frame rate (fps): 约9.98
Sensor11_Out0 Frame rate (fps): 约9.98
```

若网页仍显示旧画面但`fps_fresh=false`或FPS为0，表示没有新帧，不得把缓存的
最后一张JPEG误判为链路仍在传输。

## 11. 预览偏色问题及修复依据

2026-11-09曾出现红色货车在网页中显示成紫色。抓取Sensor8的ICP原始帧后，
按3840×2166 UYVY解码（裁掉顶部2行和底部4行）可得到正常红色，证明：

- FPGA、GMSL和NvSIPL输出的U/V顺序正确；
- 原始格式确实是packed UYVY，即`U,Y0,V,Y1`；
- 问题不在FPGA、MAX96717或域控驱动。

根因是旧预览代码将交错UYVY直接从3840×2160缩放到960×540，再转换BGR。
横向缩放会把交替存放的U、V色度分量相互插值，造成紫绿偏色。

修复后的处理顺序为：

```text
3840×2160 packed UYVY
  -> OpenCV COLOR_YUV2BGR_UYVY
  -> BGR缩放至960×540
  -> JPEG编码
  -> MJPEG发布
```

修复后Sensor8红色货车、Sensor10灰色建筑和Sensor11绿色树木均与上位机
UYVY源帧颜色一致。颜色回归测试使用饱和红色UYVY块，专门防止再次出现
“先缩放交错UYVY”的错误。

## 12. 三层验证结论不得混用

- `pcie_uyvy`的lane计数：只能证明服务器持续向XDMA写完整帧；
- `nvsipl_camera`约30 fps且错误计数为0：证明PCIe→DDR→CSI/GMSL→ICP底层
  三路链路打通；
- `img_transfer_v2`约10 fps且画面持续变化：证明ICP帧可被独立应用消费并
  实时发布MJPEG；
- 以上结果仍不等于生产`camera_service`的H265发布链已经打通。生产路径需要
  单独完成NvSciStream/Img2D/编码器验证。

