# PCIe 注入卡本地恢复脚本设计

## 目标

提供服务器本地的一键恢复脚本，用于注入卡冷启动或热插拔后，恢复 Xilinx PCIe Endpoint 的枚举、BAR 访问和 XDMA 三路 H2C 通信。

脚本路径：

```text
/home/ubuntu/zhang/recover_pcie_inject.sh
```

执行方式：

```bash
sudo /home/ubuntu/zhang/recover_pcie_inject.sh
```

## 固定环境

- Root Port：`0000:00:1c.0`
- Endpoint：默认 `0000:04:00.0`
- 目标设备 ID：`10ee:9034`
- XDMA 驱动：

```text
/data/work/gmsl_4ev/code/Pcie/pcie_test/dma_ip_drivers-master/XDMA/linux-kernel/xdma/xdma.ko
```

- 期望链路：PCIe Gen3 x4
- 期望节点：
  - `/dev/xdma0_h2c_0`
  - `/dev/xdma0_h2c_1`
  - `/dev/xdma0_h2c_2`

## 恢复流程

1. 要求以 root 身份运行。
2. 确认 Root Port 存在，并校验其下游目标是 `10ee:9034`。
3. 若存在 `pcie_raw12` 发送进程则拒绝复位，避免破坏正在进行的传输。
4. 卸载当前 `xdma` 模块。
5. 从 sysfs 移除目标 Endpoint。
6. 读取 Root Port 的 Bridge Control，置位 Secondary Bus Reset。
7. 等待 200 ms 后恢复原 Bridge Control。
8. 从 Root Port 发起 rescan，并等待 Endpoint 重新出现。
9. 校验重新枚举的设备 ID 仍为 `10ee:9034`。
10. 加载指定 XDMA Reference Driver，并设置 `h2c_timeout=3`。
11. 等待三个 H2C 节点生成，将其所有者改为调用 sudo 的原用户，权限设为 `660`。
12. 验证驱动绑定、链路速度、链路宽度和三个设备节点。

## 安全边界

- 只允许操作 `0000:00:1c.0` 下的 `10ee:9034`。
- 不扫描或复位 NVMe、GPU、网卡所在 Root Port。
- 设备 ID 不符时立即退出。
- Root Port 不存在时立即退出。
- 发送进程仍在运行时立即退出。
- 驱动文件不存在或内核版本不匹配时立即退出。
- 不执行 FPGA bitstream 下载，不重启 A53，不修改 SD 卡。
- 不使用 `git reset`、不提交 Git。

## 输出与错误处理

脚本逐步打印：

- Root Port 和 Endpoint
- 设备 ID
- Secondary Bus Reset 状态
- Endpoint 重枚举结果
- XDMA 模块加载结果
- 当前链路速度和宽度
- 三个 H2C 节点

任一步失败时返回非零状态，并保留明确的失败阶段。

## 成功标准

脚本退出码为 0，且同时满足：

```text
Endpoint = 10ee:9034
Kernel driver in use = xdma
current_link_speed = 8.0 GT/s PCIe
current_link_width = 4
/dev/xdma0_h2c_0 存在
/dev/xdma0_h2c_1 存在
/dev/xdma0_h2c_2 存在
```

脚本只证明服务器到 XDMA 的 PCIe 通信已恢复，不证明 VDMA、MIPI、GMSL 或域控采集已经成功。

## 验证设计

实现时先编写隔离测试，使用临时 sysfs 目录和替身命令验证：

1. 非 root 执行被拒绝。
2. 设备 ID 不符时不触发复位。
3. 有发送进程时不触发复位。
4. 正常路径按顺序执行 remove、Secondary Bus Reset、rescan、insmod。
5. 缺少任一 H2C 节点时失败。
6. 链路不是 Gen3 x4 时失败。
7. 正常条件下退出码为 0。

隔离测试通过后，再在当前真实注入卡上运行一次脚本，确认能够恢复 `10ee:9034`、XDMA 和三路 H2C 节点。
