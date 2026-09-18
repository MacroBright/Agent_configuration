# agent-config

> 跨 CLI Agent 与 IDE（Codex、Claude Code、OpenCode、Antigravity）的统一版本化配置与工程规则系统。

<p align="left">
  <a href="README.md">English</a> ·
  <a href="README.zh-CN.md">简体中文</a>
</p>

---

## 项目概述

`agent-config` 为多 Agent 开发环境提供分层解耦、可复现的统一配置基础设施。针对多机器、多 Agent 场景下配置文件碎片化、规则冲突、密钥难管理等问题，本仓库采用四层解耦设计：

1. **全局规则层** (`global/AGENTS.md`)：定义跨 Agent 通用的工程原则、非协商条款、任务执行模式与安全红线。
2. **用户画像层** (`global/USER_CONTEXT.md.template`)：定义长期技术方向、工程偏好与协作风格，独立于具体项目生命周期。
3. **领域模板层** (`global/templates/`)：提供通用软件工程与机器人/具身智能专用领域的项目级规则起点。
4. **工具适配层** (`per-agent/`)：按 Agent 分离配置模板与 MCP 服务，无硬编码路径与密钥。

```
                  +-----------------------------------+
                  |        global/AGENTS.md           |  <-- 跨 Agent 通用规则与非协商条款
                  +-----------------------------------+
                                    |
                  +-----------------------------------+
                  |      ~/.codex/USER_CONTEXT.md     |  <-- 用户长期技术画像与工作风格
                  +-----------------------------------+
                                    |
       +----------------------------+----------------------------+
       |                                                         |
       v                                                         v
+-----------------------------+           +---------------------------------------------+
| global/templates/           |           | per-agent/                                  |
| ├── project-AGENTS.md       |           | ├── codex.config.toml.template              |
| └── robotics-AGENTS.md      |           | ├── claude.settings.json.template           |
|     (CAN/ROS2/LeRobot)      |           | ├── claude.mcp.json.template                |
+-----------------------------+           | ├── opencode.jsonc.template                 |
                                          | └── antigravity.mcp_config.json.template    |
                                          +---------------------------------------------+
```

---

## Agent 支持矩阵

| Agent | 目标配置路径 | 部署方式 | 核心特性 |
| :--- | :--- | :--- | :--- |
| **Codex** | `~/.codex/config.toml` | 原生配置 + 本地 `auth.json` | 自定义 Provider、推理深度控制、桌面端插件段 |
| **Claude Code** | `~/.claude/settings.json`<br>`~/.claude/mcp.json` | 增量合并 + 软链 `CLAUDE.md` | 非破坏性 JSON 合并、硬件安全黑名单 (`deny`/`ask`)、MCP 基线 |
| **OpenCode** | `~/.config/opencode/opencode.jsonc` | 原生配置 | CANN 昇腾工具链插件、远程 RAG 检索 MCP 集成 |
| **Antigravity** | `~/.gemini/config/GEMINI.md`<br>`~/.gemini/config/mcp_config.json` | 规则分发 + MCP 基线 | 7 大核心 MCP 服务、`skills.json` 双目录发现机制 |

---

## 目录结构

```text
.
├── global/
│   ├── AGENTS.md                  # 跨 Agent 共享的全局规则层
│   ├── USER_CONTEXT.md.template   # 长期用户画像与工程风格模板
│   └── templates/
│       ├── project-AGENTS.md      # 通用新项目规则起点
│       └── robotics-AGENTS.md     # 机器人/具身智能项目专用规则（CAN/ROS2/LeRobot/硬件安全）
├── per-agent/
│   ├── codex.config.toml.template
│   ├── claude.settings.json.template
│   ├── claude.mcp.json.template
│   ├── opencode.jsonc.template
│   └── antigravity.mcp_config.json.template
├── skills/
│   ├── manifest.yaml              # 第三方 Skill 来源声明清单
│   └── curated.txt                # 98 个活跃、已校验的 Skill 白名单
├── install.sh                     # 交互式一键安装与引导脚本
├── verify.sh                      # 推前密钥扫描与系统完整性校验脚本
├── LICENSE                        # MIT 许可证
├── README.md                      # 英文文档
└── README.zh-CN.md                # 中文文档
```

---

## 快速上手

### 1. 安装与初始化

在新环境或需要同步配置的机器上：

```bash
git clone https://github.com/MacroBright/Agent_configuration.git ~/agent-config
cd ~/agent-config
./install.sh
```

`install.sh` 脚本执行流程：
- 自动检测本机已安装的 Agent 环境（`Codex`、`Claude Code`、`OpenCode`、`Antigravity`）。
- 在修改任何现有配置前，自动建立带时间戳的备份文件（`*.bak-YYYYMMDD`）。
- 交互式获取必要环境参数（模型名、Base URL、API Key、本地知识库路径等）。
- **针对 Claude Code**：采用增量合并策略——保留用户既有环境变量与插件，合并 `deny`/`ask` 安全权限规则，仅补充缺失的 MCP 服务，绝不覆盖或删除既有条目。
- **针对 Antigravity**：自动配置 7 大核心 MCP 服务，写入 `skills.json` 双重技能检索路径。
- 密钥统一写入本地 `~/.codex/auth.json`（权限严格锁定为 `chmod 600`），绝不进入 Git 跟踪。

### 2. 状态校验

在完成配置修改或执行 `git push` 前，运行复检脚本：

```bash
./verify.sh
```

该脚本将自动执行以下检查：
- **密钥扫描**：全仓库扫描高熵密钥、Token 及私钥模式（要求 0 命中）。
- **仓库完整性**：校验所有必须的规则、模板与脚本文件。
- **Agent 安装正确性**：校验 `AGENTS.md` 位置、Claude JSON 语法合法性、`permissions.deny` 规则数及 Antigravity 配置状态。
- **技能可发现性**：校验 `curated.txt` 中 98 个白名单技能在激活区是否均具备合法的 `SKILL.md`。

---

---

## 多 Agent 协同与长程知识图谱共享

本系统原生支持 **Antigravity、Claude Code 与 Codex** 在同一项目上的能力互补协同与持久化知识互通：

### 1. 三智能体能力与角色分工矩阵 (Role Matrix)

各 Agent 底层模型属性与外壳机制形成「看得广、想得深、改得准」的精准互补：

| 智能体 (Agent) | 底层模型 / 核心属性 | 核心定位 | 主责场景与能力专长 |
| :--- | :--- | :--- | :--- |
| **Antigravity** | **Gemini 3.8 Flash**<br>- 1M 巨量上下文<br>- 自动上下文压缩 (~135k 触发)<br>- 原生 Linux 沙箱<br>- 多模态图文解析 (DeepSWE 71.0%) | **「看得广」**<br>广域侦察与全景影响分析 | - **全局依赖扫描**：利用 1M 上下文摸清大型代码库拓扑、跨模块调用与潜在破坏半径。<br>- **多格式规范预研**：消化 PDF 论文、硬件手册、CAN DBC、通信协议，生成出版级架构图与状态机 (`diagram-design`)。<br>- **长程连续迁移**：利用沙箱与自动压缩，执行耗时跨模块重构、环境脚手架初始化与批量迁移。<br>- **全局回归复核**：最终破坏性排查、全景构建验证与文档闭环。 |
| **Claude Code** | **DeepSeek V4.1 Flash**<br>- 1M 上下文窗口<br>- 严密独立 Subagent 体系<br>- 严格权限控制 (`Ask/Deny`) | **「想得深」**<br>深度规划与质量安全裁决 | - **需求拆解与架构规划**：从复杂需求到落地设计，识别领域隐性约束，编写结构化 `implementation_plan.md`。<br>- **独立双轴审查**：派生并行 subagent 执行规范与规格审查 (`two-axis-review`)，严格把关质量与边界。<br>- **复杂系统仲裁**：排查多组件交互死锁、隐蔽竞态与状态机冲突。<br>- **安全与关键操作把关**：对硬件操作、不可逆修改实施最高级别安全审计。 |
| **Codex** | **DeepSeek V4.1 Flash**<br>- 专为代码微调 (16B 激活)<br>- DSCodex 极速专线 (214.4 tok/s)<br>- 终端紧凑原生集成 | **「改得准」**<br>手术刀式精准执行与高吞吐验证 | - **手术刀级精准实现**：在明确方案指导下，高吞吐编写确定性核心代码，单点修改精准无冗余。<br>- **TDD 与协议编解码**：快速落地驱动测试、CAN DBC 序列化、SocketCAN 编解码与硬件驱动脚手架。<br>- **极速对抗挑刺**：利用 200+ tok/s 吞吐进行对抗性代码审查 (Adversarial Review)，质疑边界与假设。<br>- **突发缺陷极速抢修**：单点 Bug 快速复现、定位与一键修补。 |

### 2. 四阶段协同接力闭环 (4-Phase Collaborative Loop)

标准化工程流水线推进各阶段交付物：

```
[Phase 1: 广域侦察] ──> [Phase 2: 深度规划] ──> [Phase 3: 手术执行] ──> [Phase 4: 全局复核]
  (Antigravity)           (Claude Code)             (Codex)              (Antigravity)
   看得广 · 摸脉络         想得深 · 定方案           改得准 · 极速编码       看得广 · 验全景
   沉淀知识图谱            写入接力黑板              双轴交叉审查            闭环归档
```

1. **Phase 1: 广域侦察与影响分析 (Antigravity 主导)**：全局扫描代码库依赖拓扑，消化硬件规范与通信协议，绘制出版级架构图，沉淀架构实体至长程图谱。
2. **Phase 2: 深度规划与质量裁决 (Claude Code 主导)**：纵深剖析业务逻辑，识别隐性约束，拟定 `implementation_plan.md` 并将 Invariants 规则写入 `.agent/SESSION_STATE.md`。
3. **Phase 3: 手术级执行与交叉审查 (Codex 主导 + Claude Code 监督)**：Codex 以 200+ tok/s 快速产出高密度 TDD 单元测试与驱动核心；Claude Code 调度 subagent 实施双轴代码审查并裁决合入。
4. **Phase 4: 全局复核与文档闭环 (Antigravity 主导)**：执行全系统构建与集成测试，验证跨模块稳定性，同步更新 ADR 与工程文档，更新黑板状态归档。

### 3. 跨 Agent 共享长程知识图谱 (`~/.agent-memory/knowledge-graph.jsonl`)
- 基于官方 MCP 知识图谱协议 (`@modelcontextprotocol/server-memory`)，所有 Agent 统一挂载至本地持久化文件 `~/.agent-memory/knowledge-graph.jsonl`。
- **自动化知识互通**：任何一个 Agent 调用 `create_entities` / `add_observations` 沉淀的硬件标定值、协议映射或架构决策，其他 Agent 均可通过 `read_graph` / `search_nodes` 秒级即时检索，彻底解决不同 Agent 会话之间的“失忆”问题。

### 4. 项目级任务接力黑板 (`.agent/SESSION_STATE.md`)
- 在项目根目录创建 `.agent/SESSION_STATE.md`（参考 `global/templates/project-SESSION_STATE.md`）。
- 每个 Agent 在离开前将进展写入黑板，下一个接手 Agent 启动时读取黑板即可瞬间恢复全部上下文。

### 5. 人在环协同治理原则 (Human-in-the-Loop Governance)
- **按需分级 (Complexity Gating)**：仅在 0 到 1 架构构建或复杂跨模块工程中启动多 Agent 协作；日常单点修复与临时对话由单 Agent 就地解决，严禁资源浪费。
- **预审公示 (Pre-review Gate)**：启动协作前必须输出结构化分工提纲，经用户确认或调整后方可启动。
- **决策非擅断 (No Presumption)**：关键技术选型与权衡给出 2~4 个选项交由用户拍板，禁止擅自做主。
- **灵活手动调度 (Manual Dispatch)**：允许用户随时打破标准 4-Phase 流程，自由调度指定 Agent 开展定向接力。
- **闭环结构化汇报 (Debriefing)**：一轮协作结束后，收尾 Agent 自动汇总交付物、各 Agent 贡献与测试实证，形成精简报告。

### 6. 协作模式显式激活指南 (Activation Instructions)
新建文件夹默认保持纯净单 Agent 模式。只有当您明确需要多 Agent 协作时，方可通过以下两种方式之一进行项目级显式激活：
1. **对话关键词指令（在任意 Agent 窗口中输入）**：
   - 输入 `/collab-init` 或 `开启多 Agent 协作`；
   - Agent 会弹出「协作启动确认卡」，向您确认任务目标与领域模板（通用模板 vs 机器人模板），获批后自动在项目根目录生成 `.agent/SESSION_STATE.md` 与 `AGENTS.md`。
2. **终端命令行工具（在项目根目录下输入）**：
   - 运行 `collab-init`，交互式输入目标并选择模板，秒级生成 `.agent/SESSION_STATE.md`。

## 领域专用模板

### 通用项目模板 (`global/templates/project-AGENTS.md`)
适用于通用软件工程项目。定义项目目标、技术栈、构建/测试命令、代码格式化策略与验证标准。

### 机器人与具身智能模板 (`global/templates/robotics-AGENTS.md`)
针对物理执行机构与嵌入式控制系统制定的高可靠性工程规范：
- **五层架构解耦**：硬件总线 $\rightarrow$ 驱动层 $\rightarrow$ 控制与安全层 $\rightarrow$ ROS2 中间件 $\rightarrow$ 策略/AI 层，严禁上层直接跨层发送底层总线帧。
- **确定性实时性与 CAN 规范**：高频控制循环（>100Hz）内部**绝对禁止动态内存分配**（`malloc`、`new`、`vector::resize`）；CAN 报文强制校验 ID/DLC/CRC 并显式指定大小端；50ms 通信超时必须触发看门狗切断力矩。
- **运动学与动力学标准**：全链路强制 SI 国际单位制（弧度制）；位置/速度/电流指令必须经过饱和硬截断；逆解接近奇异点强制启用阻尼最小二乘（DLS）或零空间投影。
- **昇腾 LeRobot 异步推理**：神经网络推理必须运行于独立异步线程，与底层实时控制解耦；动作块（Action Chunks）应用平滑滤波；设置确定性安全包络拦截层。
- **五步物理安全梯级**：任何涉及物理硬件的操作严格执行：虚拟 CAN (`vcan0`) $\rightarrow$ 闭环仿真 $\rightarrow$ 断电空跑 $\rightarrow$ 低速单关节 $\rightarrow$ 人工显式批准。

---

## 技能管理策略

本仓库采用“声明式清单 + 扁平激活区”的模式管理技能：
- `skills/manifest.yaml`：声明第三方技能源（Superpowers、Everything Claude Code、Anthropic 官方插件、Matt Pocock 工程方法论、ForgeMind 机器人规范）。
- `skills/curated.txt`：维护 98 个高阶工程技能白名单。第三方技能源码不打包进仓库，避免版本污染。
- 激活区（`~/.agents/skills/`）保持单层扁平目录结构，确保 Codex、Claude Code 与 Antigravity 均能原生索引与动态调度。

---

## 安全设计原则

1. **零密钥入库**：仓库内禁止存储任何真实 API Key、Token 或证书。
2. **路径抽象**：机器相关路径统一使用 `{{占位符}}`，仅在安装时本地渲染。
3. **物理与系统级防护**：预置高危指令拦截规则，硬阻断未经确认的系统级破坏命令（`rm -rf *`、`dd`、`mkfs`）与底层硬件直接烧录（`openocd`、`jlink`、`dfu-util`）。
4. **自动化审计门禁**：通过 `verify.sh` 实行推前强制扫描，确保代码库干净、安全。

---

## 许可证

本项目内容基于 MIT 许可证开源。引用的第三方 Skill 库与插件遵循其各自的开源许可证。
