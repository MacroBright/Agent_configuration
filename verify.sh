#!/usr/bin/env bash
# agent-config 验证脚本：①推前密钥扫描 ②仓库完整性 ③本机安装状态快照
set -uo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FAIL=0

echo "===== 1) 推前密钥扫描（必须 0 命中）====="
HITS=$( { grep -rInE --exclude-dir=.git --exclude='*.bak*' \
   -E '(ark-[A-Za-z0-9]{20,}|sk-[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|OPENAI_API_KEY="?[A-Za-z0-9]{20,}|ANTHROPIC_API_KEY="?[A-Za-z0-9]{20,})' \
   "$REPO_DIR" 2>/dev/null; } | grep -v '\.git/' || true )
if [ -n "$HITS" ]; then echo "!! 发现疑似密钥："; echo "$HITS"; FAIL=1; else echo "OK：无密钥命中。"; fi

echo ""
echo "===== 2) 仓库完整性 ====="
for f in global/AGENTS.md global/USER_CONTEXT.md.template global/templates/project-AGENTS.md \
         skills/manifest.yaml skills/curated.txt \
         per-agent/codex.config.toml.template per-agent/claude.settings.json.template per-agent/claude.mcp.json.template per-agent/opencode.jsonc.template \
         install.sh verify.sh README.md .gitignore; do
  if [ -f "$REPO_DIR/$f" ]; then echo "  ✓ $f"; else echo "  ✗ 缺失 $f"; FAIL=1; fi
done
echo "  global/AGENTS.md 小节数: $(grep -cE '^## ' "$REPO_DIR/global/AGENTS.md")"
echo "  curated.txt 白名单: $(wc -l < "$REPO_DIR/skills/curated.txt")"

echo ""
echo "===== 3) 本机安装状态（信息性）====="
echo "  本机激活 skill: $(ls -d "$HOME/.agents/skills"/*/ 2>/dev/null | wc -l)"
echo "  本机 ~/.codex/AGENTS.md 存在: $([ -f "$HOME/.codex/AGENTS.md" ] && echo yes || echo no)"
[ -f "$HOME/.codex/USER_CONTEXT.md" ] && echo "  本机 USER_CONTEXT.md: 存在" || echo "  本机 USER_CONTEXT.md: 未初始化"

echo ""
echo "===== 4) 安装正确性细查（关键路径/软链/可发现性）====="
# 位置正确
[ -f "$HOME/.codex/AGENTS.md" ] && echo "  ✓ ~/.codex/AGENTS.md 就位" || { echo "  ✗ ~/.codex/AGENTS.md 缺失"; FAIL=1; }
# Claude 软链（若 Claude 已装）
if [ -d "$HOME/.claude" ]; then
  if [ -L "$HOME/.claude/CLAUDE.md" ] || [ -f "$HOME/.claude/CLAUDE.md" ]; then
    echo "  ✓ ~/.claude/CLAUDE.md 存在（$(readlink "$HOME/.claude/CLAUDE.md" 2>/dev/null || echo 文件)）"
  else
    echo "  ! ~/.claude/CLAUDE.md 缺失（可 ln -s ~/.codex/AGENTS.md ~/.claude/CLAUDE.md）"
  fi
fi
# skill 可发现：curated 白名单在激活区是否都带 SKILL.md
TOTAL=$(wc -l < "$REPO_DIR/skills/curated.txt")
MISS=0
while IFS= read -r s; do
  [ -z "$s" ] && continue
  [ -f "$HOME/.agents/skills/$s/SKILL.md" ] || { echo "  ✗ skill 缺失: $s"; MISS=1; }
done < "$REPO_DIR/skills/curated.txt"
if [ "$MISS" -eq 0 ]; then echo "  ✓ 白名单 $TOTAL 个 skill 全部在激活区可发现"; else echo "  ✗ 有缺失 skill"; FAIL=1; fi
# 备份是否存在（冲突可回退）
BK=$(find "$HOME/.codex" "$HOME/.claude" "$HOME/.config/opencode" -maxdepth 1 -name '*.bak-*' 2>/dev/null | head -5 | wc -l)
echo "  安装备份数量(.bak-*): $BK"

echo ""
echo "===== 5) Claude Code 侧检查 ====="
CS="$HOME/.claude/settings.json"
if [ -f "$CS" ]; then
  echo "  ✓ $CS 存在"
  if command -v jq >/dev/null 2>&1; then
    DENY_N=$(jq '.permissions.deny // [] | length' "$CS" 2>/dev/null)
    ASK_N=$(jq '.permissions.ask // [] | length' "$CS" 2>/dev/null)
    if [ "${DENY_N:-0}" -gt 0 ]; then echo "  ✓ permissions.deny 规则数: $DENY_N"; else echo "  ✗ permissions.deny 为空（烧录/磁盘擦除无硬约束）"; FAIL=1; fi
    echo "  permissions.ask 规则数: ${ASK_N:-0}"
    PLG_N=$(jq '.enabledPlugins // {} | length' "$CS" 2>/dev/null)
    MKT_N=$(jq '.extraKnownMarketplaces // {} | length' "$CS" 2>/dev/null)
    if [ "${PLG_N:-0}" -gt 0 ]; then echo "  ✓ enabledPlugins: $PLG_N 个"; else echo "  ! enabledPlugins 为空（插件未沉淀）"; fi
    if [ "${MKT_N:-0}" -ge 4 ]; then echo "  ✓ extraKnownMarketplaces: $MKT_N 个"; else echo "  ! extraKnownMarketplaces 只有 $MKT_N 个（模板要求 4 个）"; fi
    jq empty "$CS" 2>/dev/null && echo "  ✓ settings.json JSON 语法合法" || { echo "  ✗ settings.json JSON 语法错误（会被静默忽略！）"; FAIL=1; }
  else
    echo "  ! 未安装 jq，跳过字段级检查"
  fi
else
  echo "  ✗ $CS 缺失"; FAIL=1
fi

if [ -f "$HOME/.claude/CLAUDE.md" ]; then
  echo "  ✓ ~/.claude/CLAUDE.md 存在（$(readlink "$HOME/.claude/CLAUDE.md" 2>/dev/null || echo 文件)）"
else
  echo "  ! ~/.claude/CLAUDE.md 缺失（可 ln -s ~/.codex/AGENTS.md ~/.claude/CLAUDE.md）"
fi

CM="$HOME/.claude/mcp.json"
if [ -f "$CM" ]; then
  echo "  ✓ ~/.claude/mcp.json 存在（$(jq '.mcpServers | length' "$CM" 2>/dev/null) 个 server）"
  DEP=$(jq -r '.mcpServers | keys[]' "$CM" 2>/dev/null | grep -E '^(memory|sequential-thinking)$' | tr '\n' ' ')
  if [ -n "$DEP" ]; then echo "  ! 含过时 server: $DEP（建议移除，模型内置推理与插件记忆已覆盖）"; fi
else
  echo "  ! ~/.claude/mcp.json 缺失（可从 per-agent/claude.mcp.json.template 复制）"
fi
echo "  本机 ~/.claude/skills 数量: $(ls -d "$HOME/.claude/skills"/*/ 2>/dev/null | wc -l)"

echo ""
if [ "$FAIL" -eq 0 ]; then echo "✅ verify 通过：可以 git add/commit/push。"; else echo "❌ verify 存在失败项，请先修复。"; exit 1; fi
