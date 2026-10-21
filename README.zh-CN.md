# agent-config

> 跨 CLI Agent 与 IDE（Codex、Claude Code、OpenCode、Gemini CLI、Antigravity）的统一版本化配置与工程规则系统。

<p align="left">
  <a href="README.md">English</a> ·
  <a href="README.zh-CN.md">简体中文</a>
</p>

---

## 项目概述

`agent-config` 为多 Agent 开发环境提供分层解耦、可复现的统一配置基础设施。针对多机器、多 Agent 场景下配置文件碎片化、规则冲突、密钥难管理等问题，本仓库采用五层解耦设计：

1. **全局规则层** (`global/AGENTS.md`)：定义跨 Agent 通用的工程原则、非协商条款、任务执行模式与安全红线。
2. **用户上下文层** (`global/USER_CONTEXT.md.template`)：定义长期技术方向、工程偏好与协作风格，独立于具体项目生命周期。
3. **领域模板层** (`global/templates/`)：提供通用软件工程与机器人/具身智能专用领域的项目级规则起点。
4. **工具适配层** (`per-agent/`)：按 Agent 分离配置模板与 MCP 服务，无硬编码路径与密钥。
5. **能力管理层** (`bin/agentctl`)：单一来源的技能库、唯一写入者，以及面向各 Agent 的投影机制，统一管理 skills、MCP 与插件。

```
                  +-----------------------------------+
                  |        global/AGENTS.md          |  跨 Agent 通用规则与非协商条款
                  +-----------------------------------+
                                    |
                  +-----------------------------------+
                  |      ~/.codex/USER_CONTEXT.md    |  用户长期技术上下文
                  +-----------------------------------+
                                    |
       +----------------------------+----------------------------+
       |                                                         |
       v                                                         v
+-----------------------------+           +---------------------------------------------+
| global/templates/           |           | per-agent/                                  |
| ├── project-AGENTS.md       |           | ├── codex.config.toml.template              |
| ├── robotics-AGENTS.md      |           | ├── claude.settings.json.template           |
| └── project-SESSION_STATE.md|           | ├── claude.mcp.json.template                |
+-----------------------------+           | ├── opencode.jsonc.template                 |
                                          | └── antigravity.mcp_config.json.template    |
                                          +---------------------------------------------+
                                    |
                                    v
                  +-----------------------------------+
                  |      bin/agentctl                |  skills/MCP/插件唯一写入者
                  +-----------------------------------+
                                    |
                  +-----------------------------------+
                  |   ~/.agents/skills/<name>        |  规范副本（以硬链接向外投影）
                  +-----------------------------------+
```

---

## Agent 支持矩阵

| Agent | 目标配置路径 | 部署方式 | 核心特性 |
| :--- | :--- | :--- | :--- |
| **Codex** | `~/.codex/config.toml` | 原生配置 + 本地 `auth.json` | 自定义 Provider、推理深度控制、桌面端插件段 |
| **Claude Code** | `~/.claude/settings.json`<br>`~/.claude/mcp.json` | 增量合并 + 软链 `CLAUDE.md` | 非破坏性 JSON 合并、硬件安全黑名单 (`deny`/`ask`)、MCP 基线 |
| **OpenCode** | `~/.config/opencode/opencode.jsonc` | 原生配置 | CANN 昇腾工具链插件、远程 RAG 检索 MCP 集成 |
| **Gemini CLI / Antigravity** | `~/.gemini/config/GEMINI.md`<br>`~/.gemini/config/mcp_config.json` | 规则分发 + MCP 基线 | 核心 MCP 服务、通过 `skills.json` 消费规范技能库 |

---

## 目录结构

```text
.
├── global/
│   ├── AGENTS.md                  # 跨 Agent 共享的全局规则层
│   ├── USER_CONTEXT.md.template   # 长期用户上下文模板
│   └── templates/
│       ├── project-AGENTS.md      # 通用新项目规则起点
│       ├── robotics-AGENTS.md     # 机器人/具身智能项目专用规则
│       └── project-SESSION_STATE.md  # 多 Agent 协作接力黑板模板
├── per-agent/
│   ├── codex.config.toml.template
│   ├── claude.settings.json.template
│   ├── claude.mcp.json.template
│   ├── opencode.jsonc.template
│   └── antigravity.mcp_config.json.template
├── skills/
│   ├── manifest.yaml              # 第三方 Skill 来源声明清单
│   ├── curated.txt                # 活跃、已校验的 Skill 白名单
│   └── agent-config-manager/      # 指导 Agent 使用 agentctl 的管理技能
├── bin/
│   └── agentctl                   # skills、MCP、插件唯一写入 CLI
├── tests/
│   └── test_agentctl.py           # 使用临时 HOME 的隔离测试
├── scripts/
│   ├── collab-init.sh             # 项目级协作脚手架
│   ├── collab-tmux.sh             # 多 Agent tmux 工作区与快照
│   └── collab-precompact.sh       # 上下文压缩前持久化状态
├── install.sh                     # 交互式一键安装与引导脚本
├── verify.sh                      # 密钥扫描与安装状态校验脚本
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

- 自动检测本机已安装的 Agent 环境（`Codex`、`Claude Code`、`OpenCode`、`Gemini CLI`）。
- 在修改任何现有配置前，自动建立带时间戳的备份文件（`*.bak-YYYYMMDD`）。
- 交互式获取必要环境参数（模型名、Base URL、API Key、本地知识库路径等）。
- **针对 Claude Code**：采用增量合并策略——保留用户既有环境变量与插件，合并 `deny`/`ask` 安全权限规则，仅补充缺失的 MCP 服务，绝不覆盖或删除既有条目。
- **针对 Gemini CLI / Antigravity**：配置 `mcp_config.json`，并将 `skills.json` 指向规范技能库。
- 将 `agentctl` 安装到 `~/.local/bin/agentctl`，并把 `agent-config-manager` 安装进规范技能库。
- 密钥统一写入 `~/.codex/auth.json` 等本地文件（权限锁定为 `chmod 600`），绝不进入 Git 跟踪。

### 2. 状态校验

在完成配置修改或执行 `git push` 前，运行复检脚本：

```bash
./verify.sh
```

该脚本将自动执行以下检查：

- **密钥扫描**：全仓库扫描高熵密钥、Token 及私钥模式（要求 0 命中）。
- **仓库完整性**：校验所有必须的规则、模板、脚本与管理器文件。
- **Agent 安装正确性**：校验 `AGENTS.md` 位置、Claude JSON 语法合法性、`permissions.deny` 规则数及 Gemini/Antigravity 配置状态。
- **技能可发现性**：确认白名单技能均具备合法的 `SKILL.md`，且各 Agent 投影可正确解析。

---

## 能力管理

`agentctl` 是唯一负责安装、启用、禁用、更新与卸载能力的组件。它在 `~/.agents/skills/<name>` 保留一份规范副本，将副本投影到各 Agent，并把 MCP 与插件操作收敛到同一套命令接口。仓库只记录规则、模板与管理器本身，不打包第三方技能或密钥。

| 领域 | 真实来源 | 写入路径 |
| --- | --- | --- |
| Skills | `~/.agents/skills/<name>` | 硬链接投影 + 单一规范副本 |
| MCP | `~/.agents/agentctl/mcp.json` | 合并写入各 Agent 原生配置 |
| 插件 | 各 Agent 原生清单 | 委托给对应 Agent CLI |
| 指令 | 本仓库 (`global/`、`per-agent/`) | 由 `install.sh` 安装 |

### Skills

```bash
agentctl status                  # 规范副本数、链接数、重复项
agentctl doctor                  # 断链、内容冲突、重复副本
agentctl list                    # 技能及各 Agent 可见状态

agentctl install <path-or-git-url> [--name NAME] [--subpath skills] [--agent all]
agentctl enable  <name> --agent codex
agentctl disable <name> --agent claude
agentctl update  <name>          # 或 --all
agentctl remove  <name>          # 默认 dry-run，加 --apply 执行
agentctl adopt                   # 收敛既有副本的 dry-run 计划
```

- `disable` 只移除某个 Agent 的投影，规范副本保留。
- `update` 通过共享 inode 生效，所有已启用 Agent 立即看到新内容。
- `adopt` 收敛其他工具创建的技能副本；遇到内容不同的规范副本绝不覆盖，只报告冲突。
- 若跨文件系统无法建立硬链接，则回退为复制，并由 `status` 明确标记。
- Gemini 是消费者而非投影目标：其 `skills.json` 直接指向规范目录，不产生第二份技能树。

### MCP

```bash
agentctl mcp list
agentctl mcp add <name> '{"command":"npx","args":["-y","pkg"]}'
agentctl mcp add <name> '{"url":"https://example.com/mcp"}'
agentctl mcp sync [--agent all]
agentctl mcp adopt
agentctl mcp enable  <name> --agent claude [--apply]
agentctl mcp disable <name> --agent claude [--apply]
agentctl mcp remove  <name> [--agent all] [--apply]
agentctl mcp duplicates [--json] [--all]
```

- `enable` / `disable` 只改一个 Agent；注册表条目与其他 Agent 保持不变。
- 两者默认 dry-run，加 `--apply` 才写入目标 Agent 配置。
- `remove` 会删除注册表条目本身；日常去重优先用 `disable`。
- `duplicates` 按 Docker 镜像、`uvx`/`npx` 包、本地脚本或 HTTP 端点聚合。同 Agent 重复与跨 Agent 版本漂移作为警告；跨 Agent 名称/服务分发差异作为提示；绝不输出 env 或 header 的值。

Claude 与 Gemini 使用 JSON 合并；Codex 使用带标记的 TOML 区块，手写 MCP 条目会被保留；OpenCode 目前只读，因为重写 JSONC 会丢失注释。疑似密钥的值统一存为 `${ENV_NAME}`，注册表中不会出现真实 Token。

### 插件

```bash
agentctl plugin list [--json]
agentctl plugin install <selector> --agent <agent> [--apply]
agentctl plugin update [selector] --agent <agent> [--apply]
agentctl plugin uninstall <selector> --agent <agent> [--apply]
agentctl plugin enable|disable <selector> --agent claude [--apply]
```

插件写入默认 dry-run，且一次只接受一个 `--agent`。各生态能力不同：

| Agent | list | install | update | uninstall | enable/disable |
| --- | --- | --- | --- | --- | --- |
| Claude Code | 是 | 是 | 是 | 是 | 是 |
| Codex | 是 | 是 | marketplace refresh | 是 | 否 |
| OpenCode | 是 | 是 | 是（`--force`） | 否 | 否 |
| Gemini CLI | 是 | 否 | 否 | 否 | 否 |

不支持的动作以退出码 `2` 结束，表示能力缺失，不应反复重试。插件缓存不做跨 Agent 硬链接去重；各生态有独立清单与更新周期，唯一安全的去重方式是在决策层先盘点、再避免把同一能力重复装进多个 Agent。

### 让 Agent 自己管理

仓库内置 `skills/agent-config-manager`，要求 Agent 通过 `agentctl` 操作，禁止手工编辑技能目录。`install.sh` 会把它安装进规范技能库，并为检测到的每个 Agent 启用。

例如在 Codex 中可以直接说：

- “把这个 skill 只启用给 Claude，Codex 不需要”
- “盘点所有 agent 的 MCP，合并重复项”
- “更新所有 git 来源的 skill，先给我看计划”

该技能强制破坏性操作先 dry-run、密钥脱敏，并遵循上面的能力矩阵。

### 共存规则

- **cc-switch** 只应负责 Provider/模型切换。若保留其技能同步，必须使用 `skillSyncMethod=symlink` 与 `skillStorageLocation=unified`；`copy`/`auto` 会产生竞争性副本。`verify.sh` 会输出当前取值。
- **HarnessKit** 不是本方案的依赖。若单独安装，只用于只读盘点与审计。
- 不要让两个工具同时执行技能同步。

---

## 多 Agent 协同与长程知识图谱共享

本系统原生支持 **Antigravity、Claude Code 与 Codex** 在同一项目上的能力互补协同与持久化知识互通。

### 1. 三智能体能力与角色分工矩阵 (Role Matrix)

| 智能体 (Agent) | 底层模型 / 核心属性 | 核心定位 | 主责场景与能力专长 |
| :--- | :--- | :--- | :--- |
| **Antigravity** | **Gemini 3.8 Flash**<br>- 1M 巨量上下文<br>- 自动上下文压缩 (~135k 触发)<br>- 原生 Linux 沙箱<br>- 多模态图文解析 | **「看得广」**<br>广域侦察与全景影响分析 | - **全局依赖扫描**：摸清大型代码库拓扑、跨模块调用与潜在破坏半径。<br>- **多格式规范预研**：消化 PDF 论文、硬件手册、CAN DBC、通信协议，生成出版级架构图与状态机 (`diagram-design`)。<br>- **长程连续迁移**：执行耗时跨模块重构、环境脚手架初始化与批量迁移。<br>- **全局回归复核**：最终破坏性排查、全景构建验证与文档闭环。 |
| **Claude Code** | **DeepSeek V4.1 Flash**<br>- 1M 上下文窗口<br>- 严密独立 Subagent 体系<br>- 严格权限控制 (`Ask/Deny`) | **「想得深」**<br>深度规划与质量安全裁决 | - **需求拆解与架构规划**：从复杂需求到落地设计，识别领域隐性约束，编写结构化 `implementation_plan.md`。<br>- **独立双轴审查**：派生并行 subagent 执行规范与规格审查 (`two-axis-review`)。<br>- **复杂系统仲裁**：排查多组件交互死锁、隐蔽竞态与状态机冲突。<br>- **安全与关键操作把关**：对硬件操作、不可逆修改实施安全审计。 |
| **Codex** | **DeepSeek V4.1 Flash**<br>- 面向代码微调<br>- 高吞吐路由<br>- 终端紧凑原生集成 | **「改得准」**<br>手术刀式精准执行与高吞吐验证 | - **手术刀级精准实现**：在明确方案指导下，高吞吐编写确定性核心代码，单点修改精准无冗余。<br>- **TDD 与协议编解码**：快速落地驱动测试、CAN DBC 序列化、SocketCAN 编解码与硬件驱动脚手架。<br>- **极速对抗挑刺**：质疑边界与假设，发现角落回归。<br>- **突发缺陷极速抢修**：单点 Bug 快速复现、定位与修补。 |

### 2. 四阶段协同接力闭环 (4-Phase Collaborative Loop)

```
[Phase 1: 广域侦察] ──> [Phase 2: 深度规划] ──> [Phase 3: 手术执行] ──> [Phase 4: 全局复核]
  (Antigravity)           (Claude Code)             (Codex)              (Antigravity)
   看得广 · 摸脉络         想得深 · 定方案           改得准 · 极速编码       看得广 · 验全景
   沉淀知识图谱            写入接力黑板              双轴交叉审查            闭环归档
```

1. **Phase 1: 广域侦察与影响分析 (Antigravity 主导)**：全局扫描代码库依赖拓扑，消化硬件规范与通信协议，绘制架构图，沉淀架构实体至长程图谱。
2. **Phase 2: 深度规划与质量裁决 (Claude Code 主导)**：纵深剖析业务逻辑，识别隐性约束，拟定 `implementation_plan.md` 并将 Invariants 写入 `.agent/SESSION_STATE.md`。
3. **Phase 3: 手术级执行与交叉审查 (Codex 主导 + Claude Code 监督)**：Codex 快速产出高密度 TDD 单元测试与驱动核心；Claude Code 调度 subagent 实施双轴代码审查并裁决合入。
4. **Phase 4: 全局复核与文档闭环 (Antigravity 主导)**：执行全系统构建与集成测试，验证跨模块稳定性，同步更新 ADR 与工程文档，更新黑板状态归档。

### 3. 跨 Agent 共享长程知识图谱 (`~/.agent-memory/knowledge-graph.jsonl`)

- 基于官方 MCP 知识图谱协议 (`@modelcontextprotocol/server-memory`)，所有 Agent 统一挂载至本地持久化文件。
- **自动化知识互通**：任一 Agent 通过 `create_entities` / `add_observations` 沉淀的硬件标定值、协议映射或架构决策，其他 Agent 均可通过 `read_graph` / `search_nodes` 即时检索。

### 4. 项目级任务接力黑板 (`.agent/SESSION_STATE.md`)

- 在项目根目录创建 `.agent/SESSION_STATE.md`，模板见 `global/templates/project-SESSION_STATE.md`。
- 每个 Agent 在离开前将进展写入黑板，下一个接手 Agent 启动时读取黑板即可恢复上下文。

### 5. 人在环协同治理原则 (Human-in-the-Loop Governance)

- **按需分级 (Complexity Gating)**：仅在 0 到 1 架构构建或复杂跨模块工程中启动多 Agent 协作；日常单点修复与临时对话由单 Agent 就地解决。
- **预审公示 (Pre-review Gate)**：启动协作前必须输出结构化分工提纲，经用户确认或调整后方可启动。
- **决策非擅断 (No Presumption)**：关键技术选型与权衡给出 2~4 个选项交由用户拍板。
- **灵活手动调度 (Manual Dispatch)**：允许用户随时打破标准四阶段流程，自由调度指定 Agent 开展定向接力。
- **闭环结构化汇报 (Debriefing)**：一轮协作结束后，收尾 Agent 汇总交付物、各 Agent 贡献与测试实证。

### 6. 协作模式显式激活

新建文件夹默认保持纯净单 Agent 模式。需要多 Agent 协作时，可通过以下两种方式之一进行项目级显式激活：

1. **对话关键词指令**：输入 `/collab-init` 或 `开启多 Agent 协作`。Agent 会弹出确认卡，确认任务目标与领域模板后，自动生成 `.agent/SESSION_STATE.md` 与 `AGENTS.md`。
2. **终端命令行工具**：在项目根目录运行 `collab-init`，交互式生成 `.agent/SESSION_STATE.md`。

### 7. 协同专属 Skills & MCP 效能矩阵

多 Agent 协作时，各 Agent 前置筛选并激活为其角色定制的工具包：

- **Antigravity（看得广）**：`diagram-design`、`research`、`domain-modeling`、`documentation-and-adrs`、`verification-before-completion`，配合 MCP `memory`、`markitdown`、`arxiv`、`obsidian`。
- **Claude Code（想得深）**：`writing-plans`、`constraint-driven-development`、`subagent-driven-development`、`two-axis-review`、`robotics-hardware-safety`，配合 MCP `memory`、`sequential-thinking`。
- **Codex（改得准）**：`test-driven-development` / `tdd`、`incremental-implementation`、`code-simplification`、`systematic-debugging`、`doubt-driven-development`，配合原生编译/测试工具链。
- **经验沉淀飞轮**：排查出的死锁、硬件兼容性与不变量通过 `add_observations` 持续写入长程图谱。
- **独立开发免受限**：单兵作战时不受此矩阵限制，依然拥有全部已安装 Skills 与 MCP 的调度权限。

### 8. 融合开源生态核心设计

1. **认知反思模型 (源自 Hindsight)**：建立 `Retain-Recall-Reflect` 循环。遇到死锁或架构纠偏时，升华为 `{触发场景 → 踩坑诱因 → 永久法则}` 结构化反思实体，受 Token 预算约束精准召回。
2. **工单原子锁与熔断安全带 (源自 Paperclip)**：子任务状态细化为 `[PENDING] → [LOCKED: Agent] → [REVIEWING] → [COMPLETED]`；单轮协作默认 5 轮迭代上限，超限自动熔断并上报用户。
3. **工位拓扑与终端快照 (源自 OpenRig)**：确立 `Seat 1 (Recon)`、`Seat 2 (Lead)`、`Seat 3 (Coder)` 工位边界；提供 `collab-tmux` 支持终端协同分屏与现场快照。
4. **上下文虚拟化与计算下沉 (源自 Context-Mode)**：倡导 “Think in Code” 范式，分析任务编写内联微脚本在沙箱执行，仅回传精炼结果；联动 PreCompact 钩子执行 `collab-precompact` 持久化状态；对全量测试与构建输出强制管道截断。
5. **对抗性门禁、排他领空与声明式 Agent (源自 Antigravity Teamwork & Subagents)**：Phase 4 复核确立 Critic（代码规范）、Challenger（极端用例与压力测试破壁者）与 Auditor（真实命令实测与反 mock/反 skip 审计员）三重独立对抗门禁；引入排他性文件领空原则（`[FILES: ...]` 互斥写）；在黑板中固化三档工程完整性模式（`development` / `demo` / `benchmark`）；预置声明式 Agent 资产（`agents/explorer.md`, `challenger.md`, `auditor.md`）并支持跨里程碑接班人轮换（Fresh Successor Handoff）。

---

## 代码编写与单元测试规范

跨 Agent 代码生成与重构严格遵循以下基准。既有成熟项目在不冲突前提下尊重既有 CI/Linter 约定，新代码默认遵循：

1. **Python 代码与测试规范**：
   - **编码规范**：遵循 [Python PEP 8](https://pep8.org/)，4 空格缩进，`snake_case` 函数与变量、`CamelCase` 类、导入分层，推荐搭配 `flake8`/`black`/`ruff`/`isort`。
   - **单元测试**：遵循 [pytest 官方规范](http://www.pytest.org/en/latest/)，测试文件统一为 `test_*.py`，直接使用原生 `assert`，利用 `@pytest.fixture` 隔离状态、`@pytest.mark.parametrize` 覆盖边界用例。
2. **C++ 代码与测试规范**：
   - **编码规范**：遵循 [Google C++ Coding Guidelines](http://google.github.io/styleguide/cppguide.html)，头文件自包含、命名规范（类 `CamelCase`、变量 `snake_case`、私有成员 `_` 后缀、常量 `kConstant`）、RAII 智能指针、禁裸 `new`/`delete`。
   - **单元测试**：遵循 [Googletest Primer](https://github.com/google/googletest/blob/master/googletest/docs/primer.md)，使用 `TEST` / `TEST_F`，区分 `EXPECT_*` 非致命检查与 `ASSERT_*` 致命断言，浮点比较使用 `EXPECT_NEAR`/`EXPECT_FLOAT_EQ`，通过 CMake `gtest_discover_tests` 接入 CTest。
3. **其余编程语言规范（各自对应之 Google 编程规范）**：
   - 其余语言遵循各自对应的 Google 编程规范，统一参考 [Google 开源项目风格指南中文版](https://github.com/zh-google-styleguide/zh-google-styleguide) 与 [Google Style Guides 官方索引](https://google.github.io/styleguide/)。
   - **C 语言**：Google C 风格，头文件自包含、函数/结构体命名明确、严格指针判空与边界防护。
   - **Shell / Bash**：遵循 [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)，`set -euo pipefail`，函数内变量强制 `local`，严格双引号防护。
   - **TypeScript / JavaScript**：遵循 [Google TypeScript/JavaScript Style Guide](https://google.github.io/styleguide/tsguide.html)，显式类型、`const` 优先、禁 `var` 与滥用 `any`。
   - **Go 及其他**：遵循各自 Google 官方风格与标准格式化工具。

---

## 领域专用模板

### 通用项目模板 (`global/templates/project-AGENTS.md`)

适用于通用软件工程项目。定义项目目标、技术栈、构建/测试命令、代码格式化策略与验证标准。

### 机器人与具身智能模板 (`global/templates/robotics-AGENTS.md`)

针对物理执行机构与嵌入式控制系统制定的高可靠性工程规范：

- **五层架构解耦**：硬件总线 → 驱动层 → 控制与安全层 → ROS2 中间件 → 策略/AI 层，严禁上层直接跨层发送底层总线帧。
- **确定性实时性与 CAN 规范**：高频控制循环内绝对禁止动态内存分配；CAN 报文强制校验 ID/DLC/CRC；通信超时触发看门狗切断力矩。
- **运动学与动力学标准**：全链路强制 SI 单位；指令经过饱和硬截断；接近奇异点启用阻尼最小二乘 (DLS) 或零空间投影。
- **异步推理**：神经网络推理运行于独立异步线程，与实时控制解耦；动作块应用平滑滤波并设置安全包络。
- **五步物理安全梯级**：虚拟 CAN (`vcan0`) → 闭环仿真 → 断电空跑 → 低速单关节 → 人工显式批准。

### 协作黑板模板 (`global/templates/project-SESSION_STATE.md`)

定义多 Agent 项目的交接结构：当前阶段、任务状态、不变量、实证记录与下一个 Agent 的接力指令。

---

## 技能管理策略

技能采用「单一规范库 + 声明式来源」模式管理：

- `skills/manifest.yaml`：声明第三方技能来源。
- `skills/curated.txt`：维护活跃技能白名单；第三方技能源码不打包进仓库。
- `~/.agents/skills/`：规范技能库，保持扁平结构以确保跨 Agent 可发现。
- `agentctl` 将技能以硬链接投影到 Codex、Claude Code 与 OpenCode；Gemini 直接读取规范目录。
- 对单个 Agent 启用或禁用只改变该 Agent 的投影，不复制内容。
- `agent-config-manager` 是 Agent 管理这套配置的操作手册。

---

## 安全设计原则

1. **零密钥入库**：仓库内禁止存储任何真实 API Key、Token 或证书。
2. **路径抽象**：机器相关路径统一使用 `{{占位符}}`，仅在安装时本地渲染。
3. **MCP 密钥引用**：疑似密钥的 MCP 值统一存为 `${ENV_NAME}`，注册表不保存字面量。
4. **破坏性操作防护**：预置规则拦截高危系统命令（`rm -rf *`、`dd`、`mkfs`）与未确认的硬件烧录（`openocd`、`jlink`、`dfu-util`）。
5. **自动化审计**：`verify.sh` 在推送前扫描密钥模式与安装漂移。

---

## 开发

```bash
python3 -m unittest discover -s tests -v
bash -n install.sh
bash -n verify.sh
./verify.sh
```

测试使用临时 `HOME` 与 mock Agent CLI，不会触碰真实配置或已安装技能。

---

## 许可证

本项目基于 MIT 许可证开源。引用的第三方 Skill 库、插件与市场遵循其各自的开源许可证。
