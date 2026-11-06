# UYVY422 Host and FPGA Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在不修改域控软件的前提下，保留现有RAW12链路并新增三路3840×2160@30 UYVY422的MCAP转换、PCIe发送、DDR缓存和CSI-2输出实现。

**Architecture:** Host使用一个格式描述符驱动的共享三路发送核心，`pcie_raw12`与`pcie_uyvy`仅绑定不同格式。Python共享MCAP/H.265抽取流程，通过格式策略生成RAW12或UYVY。FPGA使用独立UYVY构建配置：128bit H2C/VDMA保持不变，新增128→64bit UYVY gearbox，CSI TX配置为YUV422 8-bit/DT 0x1E。

**Tech Stack:** C++17、Python 3、ffmpeg、Verilog、Xilinx Vivado/Vitis 2020.2、XDMA、AXI VDMA、MIPI CSI-2 TX。

## Global Constraints

- 不修改`/home/ubuntu/zhang/hos_dev`、域控Query或DevBlk驱动。
- 保留现有RAW12行为：12,441,600字节/帧、5760字节/行、360个128bit beat/行。
- UYVY为packed `U,Y0,V,Y1`：16,588,800字节/帧、7680字节/行、480个128bit beat/行。
- 三路物理输出仍为30fps；lane0/lane2源帧重复3次，lane1重复1次。
- UYVY使用独立bitstream/BOOT产物，不在运行时切换CSI IP像素格式。
- 每项生产代码必须先有失败测试；RTL配置文件除外，但相关数据通路必须先有RTL testbench。
- 不覆盖现有成功版BOOT.bin或bitstream。

---

### Task 1: Host格式描述符与共享发送核心

**Files:**
- Create: `host/frame_format.h`
- Create: `host/frame_buffer.h`
- Create: `host/xdma_h2c.h`
- Create: `host/triple_sender.h`
- Create: `host/pcie_uyvy.cpp`
- Create: `host/test_frame_format.cpp`
- Create: `host/test_frame_buffer.cpp`
- Modify: `host/pcie_raw12.cpp`

**Interfaces:**
- Produces: `FrameFormat{name,width,height,line_bytes,frame_bytes,line_beats}`。
- Produces: `load_frame_file(path, format, max_bytes, bytes)`，仅加载完整帧。
- Produces: `write_full_frame(fd, data, frame_bytes)`，处理短写和`EINTR`。
- Produces: `run_triple_sender(argc, argv, format)`，保留现有三lane与stdin控制。

- [ ] **Step 1: 写格式和帧加载失败测试**

测试RAW12与UYVY常量、非法文件长度拒绝、budget向下对齐完整帧。

- [ ] **Step 2: 运行测试确认因接口不存在而失败**

```bash
g++ -std=c++17 -Wall -Wextra -Werror host/test_frame_format.cpp -Ihost -o /tmp/test_frame_format
g++ -std=c++17 -Wall -Wextra -Werror host/test_frame_buffer.cpp -Ihost -o /tmp/test_frame_buffer
```

- [ ] **Step 3: 实现最小格式与加载接口并使测试通过**

RAW12常量为`5760/12441600/360`；UYVY常量为`7680/16588800/480`。

- [ ] **Step 4: 写XDMA短写失败测试**

通过注入write函数验证`EINTR`重试、短写累计、0字节和错误返回失败。

- [ ] **Step 5: 实现共享发送核心和两个薄入口**

`pcie_raw12.cpp`与`pcie_uyvy.cpp`只调用`run_triple_sender`；共享核心继续使用现有`FramePacer`和`FrameRepeater`。

- [ ] **Step 6: 编译回归**

```bash
g++ -O2 -std=c++17 -Wall -Wextra -Werror -pthread host/pcie_raw12.cpp -o /tmp/pcie_raw12
g++ -O2 -std=c++17 -Wall -Wextra -Werror -pthread host/pcie_uyvy.cpp -o /tmp/pcie_uyvy
```

---

### Task 2: 统一MCAP转换器与UYVY格式验证

**Files:**
- Create: `host/mcap_convert.py`
- Create: `host/mcap_formats.py`
- Create: `host/mcap_to_uyvy.py`
- Create: `host/test_mcap_to_uyvy.py`
- Modify: `host/mcap_to_raw12.py`
- Modify: `host/test_mcap_to_raw12.py`

**Interfaces:**
- Produces: `FORMAT_SPECS["raw12"|"uyvy422"]`。
- Produces: `convert_mcap(mcap, out_dir, format_name)`。
- UYVY路径调用ffmpeg `-pix_fmt uyvy422`，输出紧密排列的`U,Y0,V,Y1`。

- [ ] **Step 1: 写UYVY字节序和帧长失败测试**

使用2×2已知YUV样本或受控ffmpeg lavfi输出，断言每个macropixel为`U,Y0,V,Y1`且帧长=`w*h*2`。

- [ ] **Step 2: 运行测试确认缺少UYVY策略而失败**

```bash
python3 host/test_mcap_to_uyvy.py
```

- [ ] **Step 3: 抽取共享MCAP/H.265逻辑并实现UYVY策略**

RAW12继续走`rgb24 -> pack_bayer_bggr`；UYVY直接由ffmpeg输出`uyvy422`，不经RGB往返。

- [ ] **Step 4: 保留兼容入口**

`mcap_to_raw12.py <mcap> <out>`行为不变；新增`mcap_to_uyvy.py <mcap> <out>`；统一入口支持`--format`。

- [ ] **Step 5: Python回归**

```bash
python3 host/test_mcap_to_raw12.py
python3 host/test_mcap_to_uyvy.py
python3 host/test_raw12_to_png.py
```

---

### Task 3: UYVY 128→64bit gearbox与lane数据通路

**Files:**
- Create: `project_1.srcs/sources_1/new/uyvy_gearbox.v`
- Create: `project_1.srcs/sim_1/new/tb_uyvy_gearbox.v`
- Create: `project_1.srcs/sources_1/new/lane_inject_uyvy.v`
- Create: `project_1.srcs/sim_1/new/tb_lane_uyvy.v`

**Interfaces:**
- `uyvy_gearbox`: 128bit AXIS输入，每拍按低64bit、再高64bit顺序输出两个64bit beat，正确传播反压。
- `lane_inject_uyvy`: 保留现有H2C/VDMA/frame_slot控制，默认`LINE_BEATS=480`，输出64bit像素流。

- [ ] **Step 1: 写gearbox失败testbench**

覆盖连续输入、输出反压、同时push/pop、reset，并断言字节顺序不变。

- [ ] **Step 2: 运行仿真确认模块缺失而失败**

优先使用`iverilog`；若仅有Vivado工具，则使用`xvlog/xelab/xsim`。

- [ ] **Step 3: 实现最小两级64bit缓冲并使仿真通过**

禁止组合丢数；当第二半拍未消费时必须拉低`s_tready`。

- [ ] **Step 4: 写lane 480 beat/行失败testbench**

断言输入480拍时S2MM在第480拍产生行TLAST，2160行结束一帧；MM2S数据经gearbox成为960拍/行。

- [ ] **Step 5: 实现UYVY lane wrapper并通过仿真**

不修改RAW12 `lane_inject.v`，避免破坏现有bitstream。

---

### Task 4: UYVY MIPI生成器、SerDes和PS VDMA参数

**Files:**
- Create: `project_1.srcs/sources_1/new/mipi_gen_uyvy.v`
- Create: `project_1.srcs/sim_1/new/tb_mipi_gen_uyvy.v`
- Create: `vitis/iic_test/src/video_format.h`
- Modify: `vitis/iic_test/src/display_demo.c`
- Modify: `vitis/iic_test/src/maxchip.c`
- Create: `create_uyvy_design.tcl`

**Interfaces:**
- `mipi_gen_uyvy`: 64bit输入，960 beat/有效行，`BYTENUM=7680`，图像DT=`0x1E`。
- `video_format.h`: 构建宏选择RAW12或UYVY的frame/line常量。
- `create_uyvy_design.tcl`: 复制/变换当前BD为UYVY配置，不覆盖RAW12工程。

- [ ] **Step 1: 写MIPI raster失败testbench**

断言图像区2160行、每行960 beat、word count 7680、DT 0x1E、SOF/TLAST位置。

- [ ] **Step 2: 实现UYVY MIPI生成器**

先生成图像区；embedded 2+4行沿用已确认的行数约束，但内容与DT必须作为独立逻辑，不假装已得到OX08D线级抓包。

- [ ] **Step 3: 参数化PS VDMA**

UYVY构建使用`FRAME_BYTES=16588800`、`HSIZE/STRIDE=7680`、`VSIZE=2160`、三槽地址步进49,766,400字节。

- [ ] **Step 4: 增加MAX96717 UYVY寄存器表**

保留RAW12表；UYVY构建将映射datatype从0x2C切换为0x1E。实际寄存器位域值需由数据手册/997成功表交叉确认，禁止仅按注释猜写。

- [ ] **Step 5: 创建独立UYVY BD Tcl**

三路lane替换为64bit版本；CSI TX配置YUV422 8-bit、4 lane、初始1.2Gbps/lane；subset converter按IP要求重配。

---

### Task 5: 验证、构建产物与文档

**Files:**
- Modify: `docs/PCIe-DDR-MIPI三路注入全流程报告.md`
- Modify: `docs/PCIe-DDR-MIPI使用说明.md`
- Create: `docs/UYVY422验证记录.md`

- [ ] **Step 1: 运行全部host和RTL测试**

记录测试命令、通过数量和版本。

- [ ] **Step 2: Vivado综合/实现**

运行独立UYVY Tcl工程，要求`route_design`成功、WNS/WHS非负，并记录LUT/FF/BRAM与RAW12基线差异。

- [ ] **Step 3: 带宽与接口静态检查**

确认三路PCIe payload 1,492,992,000 B/s、DDR最少读写2,985,984,000 B/s；CSI每路payload 3.981312Gbps小于4.8Gbps，但必须通过ILA验证`tready`无持续欠载。

- [ ] **Step 4: 生成独立命名产物**

使用`design_1_wrapper_uyvy.bit`、`BOOT_uyvy.bin`或带时间戳名称，禁止覆盖`BOOT_final.bin`。

- [ ] **Step 5: 更新启动与验证文档**

文档明确RAW12/UYVY的匹配关系、命令、帧长、bitstream、ILA检查点和域控尚未修改的限制。

- [ ] **Step 6: 最终回归**

```bash
git diff --check
git status --short
```

并重新运行全部host测试、RTL仿真及可用的Vivado检查。
