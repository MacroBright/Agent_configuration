#!/usr/bin/env bash
# collab-init: 为当前项目目录一键激活多 Agent 协作黑板与规范
set -e

CONFIG_REPO="${AGENT_CONFIG_DIR:-$HOME/.gemini/antigravity/scratch/Agent_configuration}"
if [ ! -d "$CONFIG_REPO" ]; then
  CONFIG_REPO="$HOME/agent-config"
fi

echo "============================================================"
echo "🤖 项目多 Agent 协同脚手架初始化 (Multi-Agent Collab Init)"
echo "============================================================"
echo "当前目录: $(pwd)"

if [ -f ".agent/SESSION_STATE.md" ]; then
  echo "⚠️ 当前目录已存在 .agent/SESSION_STATE.md，协作模式已处于激活状态。"
  exit 0
fi

# 1. 询问项目目标
read -p "请输入当前任务主题 / 核心目标: " TASK_NAME
TASK_NAME="${TASK_NAME:-新建工程协同开发任务}"

# 2. 询问模板类型
echo ""
echo "请选择领域规范模板 (输入数字，默认 1):"
echo "  1) 通用项目规范 (Standard Project AGENTS.md)"
echo "  2) 机器人与具身智能高可靠规范 (Robotics & Embodied AI AGENTS.md)"
read -p "选择 [1/2]: " TEMPLATE_CHOICE
TEMPLATE_CHOICE="${TEMPLATE_CHOICE:-1}"

# 3. 询问工程完整性模式 (Integrity Mode · 借鉴 Teamwork)
echo ""
echo "请选择工程完整性严谨度模式 (输入数字，默认 1):"
echo "  1) development (快速迭代: 允许复用三方库与框架，拦截伪造与空壳)"
echo "  2) demo (规范演示: 禁止抄袭开源核心代码，禁止逆向测试用例)"
echo "  3) benchmark (极严实测: 纯标准库实现，零 mock，硬件/系统真实命令 Ground Truth)"
read -p "选择 [1/2/3]: " MODE_CHOICE
case "$MODE_CHOICE" in
  2) INTEGRITY_MODE="demo" ;;
  3) INTEGRITY_MODE="benchmark" ;;
  *) INTEGRITY_MODE="development" ;;
esac

# 4. 初始化 Git (若尚未初始化)
if [ ! -d ".git" ]; then
  git init >/dev/null 2>&1 || true
  echo "✓ 已初始化本地 Git 仓库"
fi

# 5. 创建 .agent 目录并写入黑板
mkdir -p .agent
SESSION_TEMPLATE="$CONFIG_REPO/global/templates/project-SESSION_STATE.md"
if [ -f "$SESSION_TEMPLATE" ]; then
  sed "s/<简明说明当前正在推进的工程任务、重构或缺陷修复>/$TASK_NAME/g" "$SESSION_TEMPLATE" | \
  sed "s/development | demo | benchmark (默认: development)/$INTEGRITY_MODE/g" | \
  sed "s/<YYYY-MM-DD>/$(date +%Y-%m-%d)/g" > .agent/SESSION_STATE.md
else
  cat << SSTATE > .agent/SESSION_STATE.md
# Session State & Multi-Agent Blackboard
## 1. 当前任务目标 (Active Goal)
- **任务主题**: $TASK_NAME
- **发起时间**: $(date +%Y-%m-%d)

## 2. 流水线阶段与 Agent 职责分工 (4-Phase Collaboration Pipeline)
- [ ] **Phase 1: 广域侦察与影响分析** (Antigravity 主导)
- [ ] **Phase 2: 深度规划与质量裁决** (Claude Code 主导)
- [ ] **Phase 3: 手术级执行与交叉审查** (Codex 主导)
- [ ] **Phase 4: 全局复核与文档闭环** (Antigravity 主导)
**当前进度**: 待 Phase 1 启动
SSTATE
fi
echo "✓ 已创建项目接力黑板: .agent/SESSION_STATE.md"

# 5. 复制选定的 AGENTS.md 模板
if [ "$TEMPLATE_CHOICE" = "2" ]; then
  SRC_AGENT="$CONFIG_REPO/global/templates/robotics-AGENTS.md"
  DESC="机器人与具身智能模板"
else
  SRC_AGENT="$CONFIG_REPO/global/templates/project-AGENTS.md"
  DESC="通用项目模板"
fi

if [ -f "$SRC_AGENT" ] && [ ! -f "AGENTS.md" ]; then
  cp "$SRC_AGENT" ./AGENTS.md
  echo "✓ 已为项目生成规范: ./AGENTS.md ($DESC)"
fi

echo ""
echo "============================================================"
echo "🎉 [Collab Activated] 多 Agent 协作模式已成功激活！"
echo "后续在终端中运行 antigravity、claude 或 codex 将自动读取黑板开展协同。"
echo "============================================================"
