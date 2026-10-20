#!/usr/bin/env bash
# collab-precompact: 在会话触发 Compaction 压缩前夕，自动将工作区与黑板状态固化到磁盘
# 借鉴 Context-Mode 的 PreCompact 抗失忆机制，防止模型在长会话压缩后丢失正在修改的文件和未结任务。
set -eo pipefail

# 1. 探测项目根目录（寻找 .agent/SESSION_STATE.md 或 git 根目录）
PROJ_DIR="$(pwd)"
if [ ! -f "$PROJ_DIR/.agent/SESSION_STATE.md" ]; then
  GIT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  if [ -n "$GIT_ROOT" ] && [ -f "$GIT_ROOT/.agent/SESSION_STATE.md" ]; then
    PROJ_DIR="$GIT_ROOT"
  fi
fi

SSTATE="$PROJ_DIR/.agent/SESSION_STATE.md"

# 如果未开启多 Agent 协作黑板，静默退出（保持 fail-open，不阻塞宿主）
if [ ! -f "$SSTATE" ]; then
  # 输出符合 Claude Code hook 要求的标准响应
  echo '{"decision":"approve"}'
  exit 0
fi

TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")"
LAST_COMMIT="$(git log -n 1 --oneline 2>/dev/null || echo "none")"
DIRTY_FILES="$(git status -s 2>/dev/null | head -n 15 || echo "clean")"

# 2. 如果存在快照标记，则更新或追加 [PreCompact 实时快照] 区块
SNAPSHOT_HEADER="<!-- PRECOMPACT_SNAPSHOT_START -->"
SNAPSHOT_FOOTER="<!-- PRECOMPACT_SNAPSHOT_END -->"

SNAPSHOT_BLOCK="${SNAPSHOT_HEADER}
### 🔄 PreCompact 压缩前夕现场快照 ($TIMESTAMP)
> [!NOTE]
> 本区块由 PreCompact 钩子自动生成。会话压缩后，Agent 应首先依据此快照对齐工作现场。
- **分支状态**: \`$BRANCH\` | **最近提交**: \`$LAST_COMMIT\`
- **工作区脏文件 (Top 15)**:
\`\`\`text
$DIRTY_FILES
\`\`\`
${SNAPSHOT_FOOTER}"

# 如果已有快照区块，替换之；若无，则追加到文末
if grep -q "$SNAPSHOT_HEADER" "$SSTATE"; then
  TMP_FILE="$(mktemp)"
  awk -v start="$SNAPSHOT_HEADER" -v end="$SNAPSHOT_FOOTER" -v repl="$SNAPSHOT_BLOCK" '
    $0 ~ start { printing=0; print repl; next }
    $0 ~ end { printing=1; next }
    printing { print }
  ' "$SSTATE" > "$TMP_FILE"
  mv "$TMP_FILE" "$SSTATE"
else
  printf "\n\n%s\n" "$SNAPSHOT_BLOCK" >> "$SSTATE"
fi

# 输出 Claude Code 兼容的标准 Hook 批准 JSON
echo '{"decision":"approve"}'
exit 0
