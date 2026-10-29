# PCIe 注入卡本地恢复脚本实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在服务器本地提供一个安全的一键脚本，恢复 Xilinx `10ee:9034` 注入卡的 PCIe Gen3 x4 枚举、XDMA 驱动及三路 H2C 节点。

**Architecture:** 主脚本固定 Root Port、设备 ID 和 XDMA 模块路径，通过 sysfs remove、Secondary Bus Reset、rescan 完成恢复。测试脚本在临时目录中模拟 sysfs 和 `/dev`，并用 PATH 中的替身命令记录副作用，确保测试不会操作真实 PCIe 硬件。

**Tech Stack:** Bash、Linux sysfs、pciutils、kmod、XDMA Reference Driver。

## Global Constraints

- 仅操作 Root Port `0000:00:1c.0` 下的 Xilinx Endpoint `10ee:9034`。
- XDMA 模块固定为 `/data/work/gmsl_4ev/code/Pcie/pcie_test/dma_ip_drivers-master/XDMA/linux-kernel/xdma/xdma.ko`，参数为 `h2c_timeout=3`。
- 成功状态必须是 PCIe Gen3 x4、绑定 `xdma`，且 `/dev/xdma0_h2c_{0,1,2}` 全部存在。
- 检测到 `pcie_raw12` 时拒绝复位。
- 不下载 bitstream、不重启 A53、不修改 SD 卡、不提交 Git。

---

### Task 1: 隔离测试框架和安全保护

**Files:**
- Create: `/home/ubuntu/zhang/tests/test_recover_pcie_inject.sh`
- Create: `/home/ubuntu/zhang/recover_pcie_inject.sh`

**Interfaces:**
- Consumes: 环境变量 `RECOVERY_TEST_MODE=1`、`RECOVERY_SYSFS_ROOT`、`RECOVERY_DEV_ROOT`、`RECOVERY_EUID`，仅供隔离测试覆盖文件系统与身份。
- Produces: `recover_pcie_inject.sh`，成功返回 0，任何安全检查或恢复阶段失败返回非零。

- [ ] **Step 1: 编写安全保护失败测试**

测试脚本创建临时 PCI sysfs 树和替身命令，覆盖以下断言：

```bash
run_recovery RECOVERY_EUID=1000
assert_failed "必须以 root 身份运行"

write_device_id "1234:5678"
run_recovery RECOVERY_EUID=0
assert_failed "目标设备 ID 不符"
assert_log_excludes "setpci"

write_device_id "10ee:9034"
export FAKE_PGREP_MATCH=pcie_raw12
run_recovery RECOVERY_EUID=0
assert_failed "pcie_raw12"
assert_log_excludes "setpci"
```

- [ ] **Step 2: 运行测试并确认 RED**

Run: `bash /home/ubuntu/zhang/tests/test_recover_pcie_inject.sh`

Expected: FAIL，原因是 `/home/ubuntu/zhang/recover_pcie_inject.sh` 尚不存在。

- [ ] **Step 3: 实现最小安全检查**

主脚本使用 `set -Eeuo pipefail`，校验 root、Root Port、Endpoint vendor/device 和 `pcie_raw12`；测试覆盖变量只在 `RECOVERY_TEST_MODE=1` 时生效，普通执行无法重定向真实路径。

- [ ] **Step 4: 运行测试并确认安全保护通过**

Run: `bash /home/ubuntu/zhang/tests/test_recover_pcie_inject.sh`

Expected: 安全保护用例 PASS；正常恢复用例尚未加入。

### Task 2: 恢复流程、验收检查及实机验证

**Files:**
- Modify: `/home/ubuntu/zhang/tests/test_recover_pcie_inject.sh`
- Modify: `/home/ubuntu/zhang/recover_pcie_inject.sh`

**Interfaces:**
- Consumes: Root Port `0000:00:1c.0`、目标设备 `10ee:9034`、XDMA 模块和三个 H2C 节点。
- Produces: 按 `rmmod → remove → SBR → rescan → insmod → chmod/chown → verify` 顺序执行的恢复工具。

- [ ] **Step 1: 编写恢复与验收失败测试**

新增断言：

```bash
assert_order "rmmod xdma" "remove" "setpci SBR-on" "setpci SBR-off" "rescan" \
             "insmod xdma.ko h2c_timeout=3"
assert_failed_when_node_missing "/dev/xdma0_h2c_2"
assert_failed_when_link_speed_is "5.0 GT/s PCIe"
assert_failed_when_link_width_is "2"
assert_success_when_gen3_x4_and_three_nodes_exist
```

- [ ] **Step 2: 运行新增测试并确认 RED**

Run: `bash /home/ubuntu/zhang/tests/test_recover_pcie_inject.sh`

Expected: FAIL，指出 remove/SBR/rescan/insmod 流程尚未实现。

- [ ] **Step 3: 实现最小完整恢复流程**

实现内容：

```text
卸载 xdma
写 Endpoint remove
保存 Bridge Control
置位并清除 Secondary Bus Reset
写 Root Port rescan
等待 10ee:9034 和三个 H2C 节点
insmod xdma.ko h2c_timeout=3
把节点设为调用 sudo 的用户、模式 660
校验 driver、current_link_speed、current_link_width
```

- [ ] **Step 4: 运行完整隔离测试**

Run: `bash -n /home/ubuntu/zhang/recover_pcie_inject.sh && bash /home/ubuntu/zhang/tests/test_recover_pcie_inject.sh`

Expected: shell 语法检查退出 0；全部隔离测试 PASS。

- [ ] **Step 5: 在真实设备执行并采集证据**

Run: `sudo /home/ubuntu/zhang/recover_pcie_inject.sh`

Expected: 输出 `10ee:9034`、`Kernel driver in use: xdma`、`8.0 GT/s PCIe`、宽度 `4` 和三个 H2C 节点，退出码 0。若检测到发送进程，先报告并停止，不强制终止进程。

- [ ] **Step 6: 独立复核恢复状态**

Run:

```bash
lspci -s 04:00.0 -nnk
cat /sys/bus/pci/devices/0000:04:00.0/current_link_speed
cat /sys/bus/pci/devices/0000:04:00.0/current_link_width
ls -l /dev/xdma0_h2c_0 /dev/xdma0_h2c_1 /dev/xdma0_h2c_2
```

Expected: 设备为 `10ee:9034`、驱动为 `xdma`、链路为 Gen3 x4、三个节点均存在。
