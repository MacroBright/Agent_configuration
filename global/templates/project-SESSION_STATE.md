# Session State & Multi-Agent Blackboard

> 项目多 Agent 协同接力黑板：用于 Antigravity、Claude Code、Codex 跨会话与跨工具协作。
> 放置在项目根目录 `.agent/SESSION_STATE.md`。

## 1. 当前任务目标 (Active Goal)
- **任务主题**: <简明说明当前正在推进的工程任务、重构或缺陷修复>
- **关联需求 / Issue**: <链接或规范文档路径>
- **发起时间**: <YYYY-MM-DD>

## 2. 流水线阶段与 Agent 职责分工
- [ ] **Phase 1: 架构设计与图表规范** (推荐: Antigravity - 负责 5 层设计、状态机、diagram-design 出版级图表)
- [ ] **Phase 2: 核心代码与 TDD 落地** (推荐: Codex / Antigravity - 负责算法、协议序列化、单元测试)
- [ ] **Phase 3: 严格审查与环境调试** (推荐: Claude Code - 负责终端编译、静态检查、code-review、性能调优)
- [ ] **Phase 4: 硬件安全与实机测试** (推荐: 人工复核批准 + 终端执行五步安全阶梯)

**当前进度**: <例如: Phase 2 进行中 (已由 Codex 完成 CAN 解析器，待 Claude Code 审查)>

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
