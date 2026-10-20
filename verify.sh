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
for f in global/AGENTS.md global/USER_CONTEXT.md.template global/templates/project-AGENTS.md global/templates/robotics-AGENTS.md global/templates/project-SESSION_STATE.md \
         skills/manifest.yaml skills/curated.txt \
         per-agent/codex.config.toml.template per-agent/claude.settings.json.template per-agent/claude.mcp.json.template per-agent/opencode.jsonc.template per-agent/antigravity.mcp_config.json.template \
         scripts/collab-init.sh scripts/collab-tmux.sh scripts/collab-precompact.sh \
         bin/agentctl skills/agent-config-manager/SKILL.md \
         tests/test_agentctl.py \
         install.sh verify.sh README.md README.zh-CN.md .gitignore; do
  if [ -f "$REPO_DIR/$f" ]; then echo "  ✓ $f"; else echo "  ✗ 缺失 $f"; FAIL=1; fi
done
echo "  global/AGENTS.md 小节数: $(grep -cE '^## ' "$REPO_DIR/global/AGENTS.md")"
echo "  curated.txt 白名单: $(wc -l < "$REPO_DIR/skills/curated.txt")"

echo ""
echo "===== 3) 本机安装状态（信息性）====="
echo "  本机激活 skill: $(ls -d "$HOME/.agents/skills"/*/ 2>/dev/null | wc -l)"
echo "  本机 ~/.codex/AGENTS.md 存在: $([ -f "$HOME/.codex/AGENTS.md" ] && echo yes || echo no)"
[ -f "$HOME/.codex/USER_CONTEXT.md" ] && echo "  本机 USER_CONTEXT.md: 存在" || echo "  本机 USER_CONTEXT.md: 未初始化"
[ -f "$HOME/.gemini/config/skills.json" ] && echo "  Gemini skills.json: 存在" || echo "  Gemini skills.json: 未配置"

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

# Antigravity 状态（若 Antigravity 已装）
if [ -d "$HOME/.gemini" ]; then
  if [ -f "$HOME/.gemini/config/GEMINI.md" ] && [ -f "$HOME/.gemini/config/mcp_config.json" ]; then
    echo "  ✓ Antigravity 规则与 MCP 配置就位"
  else
    echo "  ! Antigravity 配置文件不完整"
  fi
fi

# 跨 Agent 共享记忆检查
if [ -f "$HOME/.agent-memory/knowledge-graph.jsonl" ]; then
  echo "  ✓ 跨 Agent 共享长程知识图谱就位 (~/.agent-memory/knowledge-graph.jsonl)"
else
  echo "  ! 共享知识图谱未初始化（可运行: mkdir -p ~/.agent-memory && touch ~/.agent-memory/knowledge-graph.jsonl）"
fi

# skill 可发现：curated 白名单在激活区是否都带 SKILL.md
TOTAL=$(wc -l < "$REPO_DIR/skills/curated.txt")
MISS=0
while IFS= read -r s; do
  [ -z "$s" ] && continue
  [ -f "$HOME/.agents/skills/$s/SKILL.md" ] || { echo "  ✗ skill 缺失: $s"; MISS=1; }
done < "$REPO_DIR/skills/curated.txt"
if [ "$MISS" -eq 0 ]; then echo "  ✓ 白名单 $TOTAL 个 skill 全部在激活区可发现"; else echo "  ✗ 有缺失 skill"; FAIL=1; fi
# 管理者 skill：canonical + 各 Agent 投影（硬链接共享 inode）
MGR="$HOME/.agents/skills/agent-config-manager/SKILL.md"
if [ -f "$MGR" ]; then
  echo "  ✓ agent-config-manager 在 canonical 区"
  MGR_INO=$(stat -c %i "$MGR" 2>/dev/null || echo "")
  for pair in "codex:$HOME/.codex/skills/agent-config-manager/SKILL.md" \
              "claude:$HOME/.claude/skills/agent-config-manager/SKILL.md"; do
    aname=${pair%%:*}; apath=${pair#*:}
    adir=$(dirname "$(dirname "$apath")")
    [ -d "$adir" ] || continue
    if [ -f "$apath" ]; then
      aino=$(stat -c %i "$apath" 2>/dev/null || echo "")
      if [ -n "$MGR_INO" ] && [ "$MGR_INO" = "$aino" ]; then
        echo "  ✓ $aname 投影为同一 inode"
      else
        echo "  ! $aname 投影存在但 inode 不同（副本而非硬链接，跑 agentctl sync）"
      fi
    else
      echo "  ! $aname 未启用 agent-config-manager（agentctl enable agent-config-manager --agent $aname）"
    fi
  done
else
  echo "  ✗ agent-config-manager 未安装到 ~/.agents/skills"; FAIL=1
fi
# 备份是否存在（冲突可回退）
BK=$(find "$HOME/.codex" "$HOME/.claude" "$HOME/.config/opencode" "$HOME/.gemini" -maxdepth 2 -name '*.bak-*' 2>/dev/null | head -5 | wc -l)
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

CM="$HOME/.claude.json"
if [ -f "$CM" ]; then
  echo "  ✓ ~/.claude.json 存在（顶层 mcpServers: $(jq '.mcpServers // {} | length' "$CM" 2>/dev/null) 个 server）"
  DEP=$(jq -r '.mcpServers | keys[]' "$CM" 2>/dev/null | grep -E '^(memory|sequential-thinking)$' | tr '\n' ' ')
  if [ -n "$DEP" ]; then echo "  ! 含过时 server: $DEP（建议移除，模型内置推理与插件记忆已覆盖）"; fi
else
  echo "  ! ~/.claude.json 缺失（Claude 尚未初始化，或配置路径不同）"
fi
echo "  本机 ~/.claude/skills 数量: $(ls -d "$HOME/.claude/skills"/*/ 2>/dev/null | wc -l)"

echo ""
echo "===== 6) Gemini CLI 侧检查 ====="
GS="$HOME/.gemini/config/skills.json"
GM="$HOME/.gemini/config/mcp_config.json"
if [ -d "$HOME/.gemini" ]; then
  if [ -f "$GS" ]; then
    if jq -e 'any(.entries[]?; .path == "~/.agents/skills")' "$GS" >/dev/null 2>&1; then
      echo "  ✓ skills.json 直接消费 ~/.agents/skills（无需投影）"
    else
      echo "  ✗ skills.json 未包含 ~/.agents/skills"; FAIL=1
    fi
  else
    echo "  ✗ $GS 缺失"; FAIL=1
  fi
  if [ -f "$GM" ]; then
    jq empty "$GM" >/dev/null 2>&1 && echo "  ✓ mcp_config.json JSON 合法（$(jq '.mcpServers // {} | length' "$GM" 2>/dev/null) 个 server）" || { echo "  ✗ mcp_config.json JSON 语法错误"; FAIL=1; }
  else
    echo "  ! $GM 缺失（可用 agentctl mcp sync 创建）"
  fi
else
  echo "  – Gemini CLI 未安装，跳过"
fi

echo ""
echo "===== 7) agentctl 统一管理层 ====="
AC=""
for cand in "$HOME/.local/bin/agentctl" "$REPO_DIR/bin/agentctl"; do
  [ -x "$cand" ] && AC="$cand" && break
done
if [ -n "$AC" ]; then
  echo "  ✓ agentctl: $AC"
  if "$AC" doctor >/tmp/agentctl-doctor.$$ 2>&1; then
    PROB=$(grep -cE '^\[' /tmp/agentctl-doctor.$$ 2>/dev/null || true)
    echo "  ✓ doctor 已运行"
    if [ "${PROB:-0}" -gt 0 ]; then
      echo "  ! doctor 提示项:"
      sed 's/^/      /' /tmp/agentctl-doctor.$$
    else
      echo "  ✓ 未发现结构性问题"
    fi
  else
    echo "  ✗ agentctl doctor 返回非零"; FAIL=1
  fi
  if "$AC" status --json 2>/dev/null | python3 -c '
import sys, json
d = json.load(sys.stdin)
dups = len(d.get("duplicates", []))
confs = len(d.get("conflicts", []))
print("  canonical=%s duplicates=%s conflicts=%s" % (d.get("canonical_count"), dups, confs))
sys.exit(0 if dups == 0 and confs == 0 else 1)
' ; then :; else echo "  ✗ 仍存在重复副本（跑 agentctl adopt）"; FAIL=1; fi
  if "$AC" plugin list --json 2>/dev/null | python3 -c '
import sys, json
d = json.load(sys.stdin)
counts = {k: len(v.get("plugins", {})) for k, v in d.items() if isinstance(v, dict) and "plugins" in v}
print("  插件清单: " + ", ".join(f"{k}={v}" for k, v in sorted(counts.items())))
caps = {k: ",".join(v.get("capabilities", [])) for k, v in d.items() if isinstance(v, dict) and v.get("capabilities")}
print("  原生能力: " + "; ".join(f"{k}[{v}]" for k, v in sorted(caps.items())))
dups = d.get("duplicates", {})
if dups:
    print("  ! 跨 Agent 同名插件: " + ", ".join(sorted(dups)))
'; then :; else echo "  ! 插件清单读取失败"; fi
  if "$AC" mcp list --json 2>/dev/null | python3 -c '
import sys, json
d = json.load(sys.stdin)
print("  MCP: actual=%s registry=%s" % (len(d.get("actual", {})), len(d.get("registry", {}))))
'; then :; else echo "  ! MCP 清单读取失败"; fi
  if "$AC" mcp duplicates --json 2>/dev/null | python3 -c '
import sys, json
d = json.load(sys.stdin)
warn = {"same-agent", "version-drift", "same-agent-service"}
for i in d.get("issues", []):
    print("    [%s] %s: %s" % (i["kind"], i["key"], i["detail"]))
sys.exit(1 if any(i.get("kind") in warn for i in d.get("issues", [])) else 0)
'; then :; else echo "  ✗ MCP 存在同 Agent 重复或版本漂移"; FAIL=1; fi
  rm -f /tmp/agentctl-doctor.$$
else
  echo "  ! 未安装 agentctl（跑 ./install.sh 或 ln -s <repo>/bin/agentctl ~/.local/bin/agentctl）"
fi

echo ""
echo "===== 8) 隔离测试 ====="
if command -v python3 >/dev/null 2>&1; then
  if python3 -m unittest discover -s "$REPO_DIR/tests" -q >/tmp/agentctl-tests.$$ 2>&1; then
    echo "  ✓ agentctl 单元测试通过（$(grep -oE 'Ran [0-9]+ tests' /tmp/agentctl-tests.$$ | tail -1)）"
  else
    echo "  ✗ agentctl 单元测试失败："
    tail -n 20 /tmp/agentctl-tests.$$ | sed 's/^/      /'
    FAIL=1
  fi
  rm -f /tmp/agentctl-tests.$$
else
  echo "  ! 未找到 python3，跳过隔离测试"; FAIL=1
fi

echo ""
echo "===== 9) 写入权冲突检查 ====="
CC_SETTINGS="$HOME/.cc-switch/settings.json"
if [ -f "$CC_SETTINGS" ]; then
  CC_SYNC=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("skillSyncMethod", ""))' "$CC_SETTINGS" 2>/dev/null || echo "")
  CC_STORAGE=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("skillStorageLocation", ""))' "$CC_SETTINGS" 2>/dev/null || echo "")
  if [ "$CC_SYNC" = "symlink" ] && [ "$CC_STORAGE" = "unified" ]; then
    echo "  ✓ cc-switch skillSyncMethod=symlink, storage=unified（共享 canonical store，不产生副本）"
  else
    case "$CC_SYNC" in
      off|disabled|none|manual) echo "  ✓ cc-switch skillSyncMethod=$CC_SYNC（不争抢 skills 写入权）" ;;
      "") echo "  ! cc-switch 已安装但未读到 skillSyncMethod；请确认其不自动同步 skills" ;;
      *) echo "  ! cc-switch skillSyncMethod=$CC_SYNC, storage=$CC_STORAGE"
         echo "      请改设为 symlink + unified，或关闭其 skills 同步；勿使用 copy/auto"
         echo "      cc-switch 只负责 provider/model 切换" ;;
    esac
  fi
else
  echo "  – 未检测到 cc-switch"
fi
if command -v hk >/dev/null 2>&1 || [ -d "$HOME/.harnesskit" ]; then
  echo "  ! 检测到 HarnessKit：仅用于只读盘点/审计，不要让它并行安装或同步 skills"
fi

echo ""
if [ "$FAIL" -eq 0 ]; then echo "✅ verify 通过：可以 git add/commit/push。"; else echo "❌ verify 存在失败项，请先修复。"; exit 1; fi
