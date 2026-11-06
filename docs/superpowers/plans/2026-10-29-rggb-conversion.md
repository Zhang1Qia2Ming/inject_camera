# RAW12 RGGB Conversion Implementation Plan

> **状态：历史 A/B 实验，已否定并停止执行。**  
> 域控画面对比确认当前成功版本应使用 BGGR；不要继续执行下列任务，也不要据此修改正式 RAW12 文件。

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将服务器端 RGB→RAW12 转换从 BGGR 改为 RGGB，并生成一帧可发送的前远 A/B 测试数据。

**Architecture:** 保持 RAW12 三字节打包、发送程序和硬件链路不变，只调整 RGB 分量到 Bayer 位置的映射。用独立单元测试解包结果，验证 2×2 像素顺序为 R、G、G、B。

**Tech Stack:** Python 3、NumPy、unittest。

## Global Constraints

- 不修改 FPGA、BOOT、VDMA、MIPI、GMSL 或域控。
- 不覆盖现有 `host/frames/*.raw`。
- A/B 文件必须恰好为一帧，即 `12,441,600` 字节。

---

### Task 1: RGGB 映射测试与实现

**Files:**
- Create: `host/test_mcap_to_raw12.py`
- Modify: `host/mcap_to_raw12.py`

**Interfaces:**
- Produces: `pack_bayer_rggb(rgb) -> bytes`

- [ ] 编写 2×2 RGB 测试，解包后断言 `[R, G, G, B]`。
- [ ] 运行测试，确认旧 BGGR 实现因缺少 `pack_bayer_rggb` 而失败。
- [ ] 将转换函数改为 RGGB，并让输出尺寸根据输入数组计算。
- [ ] 运行单元测试和 `py_compile`，确认全部通过。

### Task 2: 一帧前远 A/B 数据

**Files:**
- Create: `host/test_frames/tx1_forward_far_rggb_1f.raw`（测试素材，不提交 Git）

**Interfaces:**
- Consumes: `host/frames/tx1_forward_far.raw` 的首帧 BGGR。
- Produces: 一帧 RGGB RAW12，通过交换每个 2×2 Bayer 单元的 R/B 样点生成。

- [ ] 流式读取首帧、解包、交换 BGGR 的左上和右下样点、重新打包。
- [ ] 验证输出大小为 `12,441,600` 字节。
- [ ] 解包抽样，确认输出的 RGGB R/B 位置与输入 BGGR 对调、两个 G 位置不变。
