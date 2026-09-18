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

本系统原生支持 **Antigravity、Claude Code 与 Codex** 在同一项目上协同开发与知识互通：

### 1. 跨 Agent 共享长程知识图谱 (`~/.agent-memory/knowledge-graph.jsonl`)
- 基于官方 MCP 知识图谱协议 (`@modelcontextprotocol/server-memory`)，所有 Agent 统一挂载至本地持久化文件 `~/.agent-memory/knowledge-graph.jsonl`。
- **自动化知识互通**：任何一个 Agent 调用 `create_entities` / `add_observations` 沉淀的硬件标定值、协议映射或架构决策，其他 Agent 均可通过 `read_graph` / `search_nodes` 秒级即时检索，彻底解决不同 Agent 会话之间的“失忆”问题。

### 2. 项目级任务接力黑板 (`.agent/SESSION_STATE.md`)
- 在项目根目录创建 `.agent/SESSION_STATE.md`（参考 `global/templates/project-SESSION_STATE.md`）。
- **标准分工流**：
  - **Antigravity (架构与可视化)**：负责编写方案、生成 `diagram-design` 架构图与状态机，解析多格式文档。
  - **Codex (高速工程编码)**：根据方案快速编写算法、CAN 协议编解码与 TDD 测试。
  - **Claude Code (深度审查与终端调试)**：在 Linux 终端执行构建、静态检查、`/code-review` 与物理安全复核。
- 每个 Agent 在离开前将进展写入黑板，下一个接手 Agent 启动时读取黑板即可瞬间恢复全部上下文。

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
