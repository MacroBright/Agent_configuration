#!/usr/bin/env bash
# collab-tmux: 基于 tmux 的轻量级多 Agent 工位管理与现场快照工具 (借鉴 OpenRig 架构)
set -eo pipefail

check_tmux() {
  if ! command -v tmux >/dev/null 2>&1; then
    echo "❌ 未检测到 tmux。请先运行: sudo apt-get update && sudo apt-get install -y tmux"
    exit 1
  fi
}

PROJ_DIR="$(pwd)"
PROJ_NAME="$(basename "$PROJ_DIR")"
SESSION_NAME="collab-${PROJ_NAME}"
CMD="${1:-up}"

case "$CMD" in
  up|start)
    check_tmux
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
      echo "ℹ️ 会话 $SESSION_NAME 已在运行，正在附加接入..."
      exec tmux attach-session -t "$SESSION_NAME"
    fi

    echo "🚀 正在为项目 [$PROJ_NAME] 初始化多 Agent 协同工位 (Session: $SESSION_NAME)..."
    
    # 窗口 1: Claude Code (Seat 2: Lead)
    tmux new-session -d -s "$SESSION_NAME" -n "claude" -c "$PROJ_DIR"
    tmux send-keys -t "$SESSION_NAME:claude" "echo '=== Seat 2: Claude Code (Lead Orchestrator) ==='; claude" C-m

    # 窗口 2: Codex (Seat 3: Coder)
    tmux new-window -t "$SESSION_NAME" -n "codex" -c "$PROJ_DIR"
    tmux send-keys -t "$SESSION_NAME:codex" "echo '=== Seat 3: Codex (Surgical Implementation) ==='; codex" C-m

    # 窗口 3: Shell & Tests
    tmux new-window -t "$SESSION_NAME" -n "terminal" -c "$PROJ_DIR"
    tmux send-keys -t "$SESSION_NAME:terminal" "echo '=== Build, Tests & Git Terminal ==='; git status" C-m

    # 默认切回 Claude 窗口
    tmux select-window -t "$SESSION_NAME:claude"
    echo "✓ 协同工位初始化完成 (窗口: claude, codex, terminal)"
    exec tmux attach-session -t "$SESSION_NAME"
    ;;

  snapshot)
    check_tmux
    if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
      echo "❌ 找不到运行中的协同会话: $SESSION_NAME"
      exit 1
    fi
    mkdir -p "$PROJ_DIR/.agent/snapshots"
    TS="$(date +%Y%m%d_%H%M%S)"
    echo "📸 正在捕获各工位终端现场快照..."
    for win in claude codex terminal; do
      if tmux list-windows -t "$SESSION_NAME" -F "#{window_name}" | grep -q "^${win}$"; then
        tmux capture-pane -pt "$SESSION_NAME:${win}" > "$PROJ_DIR/.agent/snapshots/${TS}_${win}.log" 2>/dev/null || true
        echo "  ✓ 已保存窗口快照: .agent/snapshots/${TS}_${win}.log"
      fi
    done
    echo "✅ 团队现场快照保存完毕: .agent/snapshots/"
    ;;

  status)
    check_tmux
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
      echo "🟢 协同会话 [$SESSION_NAME] 正在运行:"
      tmux list-windows -t "$SESSION_NAME"
    else
      echo "⚪ 协同会话 [$SESSION_NAME] 未在运行"
    fi
    ;;

  down|stop)
    check_tmux
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
      echo "⏹️ 正在终止协同会话: $SESSION_NAME"
      tmux kill-session -t "$SESSION_NAME"
      echo "✓ 已停止"
    else
      echo "ℹ️ 会话 $SESSION_NAME 不存在"
    fi
    ;;

  *)
    echo "用法: collab-tmux [up|down|snapshot|status]"
    echo "  up       : 启动或附加至当前项目的多 Agent 协同 tmux 会话 (窗口: claude, codex, terminal)"
    echo "  snapshot : 捕获各工位屏幕输出快照至 .agent/snapshots/"
    echo "  status   : 查看当前项目工位状态"
    echo "  down     : 停止当前项目的协同 tmux 会话"
    exit 1
    ;;
esac
