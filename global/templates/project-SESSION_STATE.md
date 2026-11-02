# Session State & Multi-Agent Blackboard

> 项目多 Agent 协同接力黑板：用于 Antigravity、Claude Code、Codex 跨会话与跨工具协作。
> 放置在项目根目录 `.agent/SESSION_STATE.md`。

## 1. 当前任务目标 (Active Goal)
- **任务主题**: <简明说明当前正在推进的工程任务、重构或缺陷修复>
- **关联需求 / Issue**: <链接或规范文档路径>
- **发起时间**: <YYYY-MM-DD>
- **协作拓扑模式 (Topology)**: hierarchical (分层流水线, 默认) | mesh (结对双工攻坚)
- **工程完整性模式 (Integrity Mode)**: development | demo | benchmark (默认: development)
- **协同迭代轮次**: 1 / 5 (熔断阈值: 5 轮，超限将挂起并升级至人类董事会)

## 2. 流水线阶段与工单状态机 (Pipeline & Task Locks)
### 阶段分工与推荐工具
- [ ] **Phase 1: 广域侦察与影响分析** (Seat 1: Antigravity 主导 · 看得广 | 专属 Skills: `diagram-design`, `research`, `domain-modeling`, `documentation-and-adrs`, `verification-before-completion`)
- [ ] **Phase 2: 深度规划与质量裁决** (Seat 2: Claude Code 主导 · 想得深 | 专属 Skills: `writing-plans`, `constraint-driven-development`, `subagent-driven-development`, `two-axis-review`, `robotics-hardware-safety`)
- [ ] **Phase 3: 手术级执行与交叉审查** (Seat 3: Codex 主导执行 · 改得准 + Claude Code 监督 | 专属 Skills: `test-driven-development`, `incremental-implementation`, `code-simplification`, `systematic-debugging`, `doubt-driven-development`)
- [ ] **Phase 4: 全局复核与对抗门禁** (Seat 1: Antigravity 主导 · Critic 规范评审 / Challenger 压力反例 / Auditor 真实性审计 | 专属 Skills: `verification-before-completion`, `documentation-and-adrs`, `diagram-design`)

> 注：支持用户打破标准流水线，手动指定任意 Agent 跨阶段自由接力（如 Phase 1 调研后直接由 Codex 手术级执行）。

### 细分工单原子锁与排他文件领空 (Atomic Task Checkout & Exclusive File Ownership)
> 规则：任务原子认领必须绑定独占文件领空 `[FILES: ...]`，任一文件同一时刻严禁被两个 Agent 同时修改。
> 租约说明：支持指定认领时间戳与租约 TTL（如 `@ HH:MM (TTL: 30m)`），超期未更新视为死锁陈旧锁，接班 Agent 或人类可强制接管释放。
> 订阅直通 (Fast Path)：支持绑定 `[SUBSCRIBED: <thread-id>]` 作用域。后续同一任务的构建报错、编译器日志与测试反馈直接直通认领 Worker，绕过全局重新扫描，节约 30%+ 协调 Token。
- `[LOCKED: Codex @ 15:30 (TTL: 30m)] [FILES: src/can_bus.cpp, include/can_bus.h] [SUBSCRIBED: thread-can-protocol]` <子任务 1: 核心协议序列化与数据结构实现> (执行中，领空锁定，直通订阅生效)
- `[PENDING] [FILES: src/watchdog.cpp] [SUBSCRIBED: thread-watchdog]` <子任务 2: 看门狗状态机与异常恢复握手逻辑> (待认领)
- `[REVIEWING: Claude Code]` <子任务 3: 双轴规范审查与死锁检测> (待审查)
- `[COMPLETED]` <子任务 0: 架构图与长程实体沉淀> (已归档)

**当前进度**: <例如: Phase 3 进行中 (Codex 已完成子任务 1，待 Claude Code 审查)>

## 3. 协作推进记录与实证 (Completed Work & Evidence)
| 时间 | 执行 Agent | 完成内容 | 验证依据 (测试命令 / 构建结果) | Git Commit |
| :--- | :--- | :--- | :--- | :--- |
| <YYYY-MM-DD> | <Agent 名称> | <具体完成项> | <如 pytest 12/12 通过，0 内存泄漏> | `<commit-id>` |

## 4. 记忆命名空间与认知反思沉淀 (Memory Namespaces & Reflections)
> 缓存治理原则：Inline 高频时空邻近信息（节点短 ID、关键摘要、前后关联）；超长 Diff 与日志 Spill 溢出至外部文件；检索时顺着 ID 引用指针执行链式召回 (Chain of Recall)。

### 4.1 永久不变量 (Invariants Namespace · 永久固化)
- `inv-mem-01`: 控制循环内部绝对禁止动态内存分配 (0 malloc/new)
- `inv-net-02`: 通信超时阈值锁定为 50ms 看门狗自动禁能
- `inv-kin-03`: 角度数据全链路强制 SI 弧度制
<!-- 任何接手的 Agent 必须严格遵守上述决策，不得擅自逆向修改 -->

### 4.2 结构化认知反思 (Patterns Namespace · 经验升华)
| 节点 ID | 触发场景 (Trigger) | 踩坑诱因 (Gotcha) | 升华法则 (Crystallized Invariant) | 关联节点 (Chain Ref) |
| :--- | :--- | :--- | :--- | :--- |
| `pat-can-01` | CAN 总线高频接收 | 堆动态分配导致 200μs 线程抖动 | 在实时控制循环中严格预分配缓冲区，0 动态内存分配 | `inv-mem-01`, `thread-can-protocol` |

### 4.3 暂态交接与握手信号 (Ephemeral Namespace · TTL 300s，归档自动清理)
- <例如: Codex 提交构建缓存至 /tmp/build_cache，请 Claude Code 审查单元测试覆盖率>
<!-- 暂态空间用于跨 Agent 握手信号、临时迁移状态，本轮任务交付后丢弃，不污染长程图谱 -->

## 5. 接力指令 (Handoff to Next Agent)
- **接手 Agent 启动动作**: <明确写出下一个接班 Agent 启动后要执行的第一条命令或任务>
- **未决疑问与风险提示**: <列出需要后续 Agent 重点排查或请示用户确认的问题>

## 6. 本轮协作闭环总结汇报 (Collaboration Debriefing)
<!-- 一轮多 Agent 任务全部完成后由收尾 Agent 填写并向用户汇报 -->
- **任务目标与完成度**: <例如: 100% 完成，CAN 电机控制与看门狗功能全部交付>
- **各 Agent 贡献清单**:
  - `Antigravity`: <完成协议预研、生成架构图，沉淀知识图谱实体>
  - `Claude Code`: <完成深度规划、确定并发不变量与安全策略>
  - `Codex`: <极速落地驱动实现与 TDD 测试套件，Commit: xxxxxxx>
- **验证实证**: <如 pytest 15/15 全部通过，0 编译警告>
- **后续建议 / 未决项**: <无遗留阻塞项，下一步可接入实机联调>
