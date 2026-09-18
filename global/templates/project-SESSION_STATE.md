# Session State & Multi-Agent Blackboard

> 项目多 Agent 协同接力黑板：用于 Antigravity、Claude Code、Codex 跨会话与跨工具协作。
> 放置在项目根目录 `.agent/SESSION_STATE.md`。

## 1. 当前任务目标 (Active Goal)
- **任务主题**: <简明说明当前正在推进的工程任务、重构或缺陷修复>
- **关联需求 / Issue**: <链接或规范文档路径>
- **发起时间**: <YYYY-MM-DD>

## 2. 流水线阶段与 Agent 职责分工 (4-Phase Collaboration Pipeline)
- [ ] **Phase 1: 广域侦察与影响分析** (Antigravity 主导 · 看得广 | 专属 Skills: `diagram-design`, `research`, `domain-modeling`, `documentation-and-adrs`, `verification-before-completion`)
- [ ] **Phase 2: 深度规划与质量裁决** (Claude Code 主导 · 想得深 | 专属 Skills: `writing-plans`, `constraint-driven-development`, `subagent-driven-development`, `two-axis-review`, `robotics-hardware-safety`)
- [ ] **Phase 3: 手术级执行与交叉审查** (Codex 主导执行 · 改得准 + Claude Code 监督 | 专属 Skills: `test-driven-development`, `incremental-implementation`, `code-simplification`, `systematic-debugging`, `doubt-driven-development`)
- [ ] **Phase 4: 全局复核与文档闭环** (Antigravity 主导 · 看得广 | 专属 Skills: `verification-before-completion`, `documentation-and-adrs`, `diagram-design`)

> 注：上述阶段为标准推荐流水线；支持用户手动指定任意 Agent 跨阶段自由接力（如 Phase 1 调研后直接由 Codex 手术级执行）。

**当前进度**: <例如: Phase 3 进行中 (Codex 已完成 CAN 解析与单测，待 Claude Code 审查)>

## 3. 协作推进记录与实证 (Completed Work & Evidence)
| 时间 | 执行 Agent | 完成内容 | 验证依据 (测试命令 / 构建结果) | Git Commit |
| :--- | :--- | :--- | :--- | :--- |
| <YYYY-MM-DD> | <Agent 名称> | <具体完成项> | <如 pytest 12/12 通过，0 内存泄漏> | `<commit-id>` |

## 4. 核心技术决策与不变量 (Decisions & Invariants)
- <决策 1: 控制循环内部绝对禁止动态内存分配 (0 malloc/new)>
- <决策 2: 通信超时阈值锁定为 50ms 看门狗自动禁能>
- <决策 3: 角度数据全链路强制 SI 弧度制>
<!-- 任何接手的 Agent 必须严格遵守上述决策，不得擅自逆向修改 -->

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
