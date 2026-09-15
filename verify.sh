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
         per-agent/codex.config.toml.template per-agent/claude.settings.json.template per-agent/opencode.jsonc.template \
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
if [ "$FAIL" -eq 0 ]; then echo "✅ verify 通过：可以 git add/commit/push。"; else echo "❌ verify 存在失败项，请先修复。"; exit 1; fi
