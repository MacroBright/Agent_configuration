#!/usr/bin/env bash
# agent-config 一键安装/同步脚本
# 用途：新机器或新 agent 环境引导。规则入库、密钥本地注入、skill 按清单拉取。
# 注意：本脚本会 ①备份现有配置 ②写入新配置。执行前请先阅读。
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATE="$(date +%Y%m%d)"
HOME_DIR="${HOME:?HOME is not set}"
SKILLS_DIR="${HOME_DIR}/.agents/skills"
STAMP="[agent-config]"

say(){ echo "$STAMP $*"; }
ask(){
  local d="$2"
  read -r -p "$1 [$d]: " a
  echo "${a:-$d}"
}
backup_file(){ # backup_file <path>
  [ -f "$1" ] && cp "$1" "$1.bak-$DATE" && say "备份 $1 -> $1.bak-$DATE"
}

detect_agents(){
  say "目标 Agent 环境——"
  for probe in "$HOME_DIR/.codex:Codex" "$HOME_DIR/.claude:Claude Code" "$HOME_DIR/.gemini:Gemini CLI" "$HOME_DIR/.config/opencode:OpenCode"; do
    p="${probe%%:*}"; n="${probe##*:}"
    if [ -d "$p" ]; then say "  ✓ $n 已安装 → 将处理"; else say "  – $n 未安装 → 跳过"; fi
  done
}

# ---------- 0. 安全检查 ----------
say "在写任何东西之前，先跑一次仓库密钥扫描（若有泄露立即中止）"
if grep -rInE --exclude-dir=.git -E '(ark-[A-Za-z0-9]{20,}|sk-[A-Za-z0-9]{20,}|ANTHROPIC_API_KEY|OPENAI_API_KEY=.{20,}|ghp_[A-Za-z0-9]{20,})' "$REPO_DIR" 2>/dev/null; then
  say "!! 仓库中发现疑似密钥，中止安装。请先清理后重试。"; exit 1
fi

detect_agents

# ---------- 1. 全局规则 ----------
if [ -d "${HOME_DIR}/.codex" ]; then
  backup_file "${HOME_DIR}/.codex/AGENTS.md"
  cp "$REPO_DIR/global/AGENTS.md" "${HOME_DIR}/.codex/AGENTS.md"
  say "已写入 ~/.codex/AGENTS.md（全局规则层）"
  mkdir -p "${HOME_DIR}/.codex/context/templates"
  cp "$REPO_DIR/global/templates/project-AGENTS.md" "${HOME_DIR}/.codex/context/templates/project-AGENTS.md"
  cp "$REPO_DIR/global/templates/robotics-AGENTS.md" "${HOME_DIR}/.codex/context/templates/robotics-AGENTS.md"
  cp "$REPO_DIR/global/templates/project-SESSION_STATE.md" "${HOME_DIR}/.codex/context/templates/project-SESSION_STATE.md"
  mkdir -p "${HOME_DIR}/.agent-memory"
  touch "${HOME_DIR}/.agent-memory/knowledge-graph.jsonl"
  say "已写入通用与机器人领域项目级模板"

  # 协作 CLI 工具软链至 ~/.local/bin
  mkdir -p "${HOME_DIR}/.local/bin"
  for scr in collab-init collab-tmux collab-precompact; do
    if [ -f "$REPO_DIR/scripts/${scr}.sh" ]; then
      chmod +x "$REPO_DIR/scripts/${scr}.sh"
      ln -sf "$REPO_DIR/scripts/${scr}.sh" "${HOME_DIR}/.local/bin/${scr}"
    fi
  done
  say "已配置 ~/.local/bin/collab-* 协作工具软链"

  if [ ! -f "${HOME_DIR}/.codex/USER_CONTEXT.md" ]; then
    cp "$REPO_DIR/global/USER_CONTEXT.md.template" "${HOME_DIR}/.codex/USER_CONTEXT.md"
    say "已生成 ~/.codex/USER_CONTEXT.md，请打开填写占位符"
  else
    say "~/.codex/USER_CONTEXT.md 已存在，跳过"
  fi
fi

# ---------- 2. Codex 配置（模型/密钥本地注入） ----------
if [ -d "${HOME_DIR}/.codex" ]; then
  say "-- Codex 配置 --"
  MODEL="$(ask '默认模型(如 ark-code-latest)' 'ark-code-latest')"
  REASON="$(ask 'reasoning effort(high/medium/low)' 'high')"
  NAME="$(ask 'provider 名称(自定义)' 'custom')"
  BASE="$(ask 'Base URL(形如 http://127.0.0.1:15721/v1)' 'http://127.0.0.1:15721/v1')"
  HAS_BUNDLED=no
  [ -d "${HOME_DIR}/.codex/.tmp/bundled-marketplaces/openai-bundled" ] && HAS_BUNDLED=yes
  awk -v model="$MODEL" -v reason="$REASON" -v name="$NAME" -v base="$BASE" -v home="${HOME_DIR}/.codex" -v desktop="$HAS_BUNDLED" '
    /{{#HAS_DESKTOP_BUNDLED}}/{insec=1; onesec=(desktop=="yes"); print ""; next}
    /{{\/HAS_DESKTOP_BUNDLED}}/{insec=0; print ""; next}
    { if (insec && !onesec) next
      gsub(/\{\{MODEL\}\}/, model)
      gsub(/\{\{REASONING_EFFORT\}\}/, reason)
      gsub(/\{\{PROVIDER_NAME\}\}/, name)
      gsub(/\{\{BASE_URL\}\}/, base)
      gsub(/\{\{CODEX_HOME\}\}/, home)
      print }
  ' "$REPO_DIR/per-agent/codex.config.toml.template" > "${HOME_DIR}/.codex/config.toml"
  say "已生成 ~/.codex/config.toml（含桌面插件段: $HAS_BUNDLED）"
  if [ ! -f "${HOME_DIR}/.codex/auth.json" ]; then
    KEY="$(ask 'API Key(仅写入本地 ~/.codex/auth.json，绝不入库)' '')"
    if [ -n "$KEY" ]; then
      printf '{\n  "OPENAI_API_KEY": "%s"\n}\n' "$KEY" > "${HOME_DIR}/.codex/auth.json"
      chmod 600 "${HOME_DIR}/.codex/auth.json"
      say "已写入 ~/.codex/auth.json(chmod 600)"
    fi
  else
    say "~/.codex/auth.json 已存在，跳过"
  fi
fi

# ---------- 3. Claude Code ----------
if [ -d "${HOME_DIR}/.claude" ]; then
  say "-- Claude Code --"
  S="${HOME_DIR}/.claude/settings.json"
  M="${HOME_DIR}/.claude.json"
  backup_file "$S"
  backup_file "$M"
  BASE_CL="$(ask 'Claude Base URL(已有配置会保留，留空则用默认)' 'http://127.0.0.1:15721')"
  EFFORT="$(ask 'effortLevel(medium)' 'medium')"
  TMP_TPL="$(mktemp)"
  sed -e "s|{{BASE_URL}}|$BASE_CL|g" -e "s|{{EFFORT_LEVEL}}|$EFFORT|g" \
      "$REPO_DIR/per-agent/claude.settings.json.template" > "$TMP_TPL"

  if [ -f "$S" ]; then
    # 增量合并：既有 env/model/theme 保留不动；deny/ask 并集去重；插件与市场只补缺失项
    jq -S --slurpfile t "$TMP_TPL" --arg base "$BASE_CL" '
      .effortLevel //= $t[0].effortLevel
      | .env.ANTHROPIC_AUTH_TOKEN //= $t[0].env.ANTHROPIC_AUTH_TOKEN
      | (if (.env.ANTHROPIC_BASE_URL // "") == "" then .env.ANTHROPIC_BASE_URL = $base else . end)
      | .permissions.deny = ((.permissions.deny // []) + ($t[0].permissions.deny // []) | unique)
      | .permissions.ask  = ((.permissions.ask  // []) + ($t[0].permissions.ask  // []) | unique)
      | .enabledPlugins = ((.enabledPlugins // {}) * ($t[0].enabledPlugins // {}))
      | .extraKnownMarketplaces = ((.extraKnownMarketplaces // {}) * ($t[0].extraKnownMarketplaces // {}))
    ' "$S" > "$S.tmp" && mv "$S.tmp" "$S"
    say "已合并 $S（既有 env/插件保留，安全规则取并集）"
  else
    cp "$TMP_TPL" "$S"
    say "已生成 $S"
  fi

  # MCP：只补缺失的 server，绝不删除既有条目
  TMP_MCP="$(mktemp)"
  sed -e "s|{{HOME}}|$HOME_DIR|g" "$REPO_DIR/per-agent/claude.mcp.json.template" > "$TMP_MCP"
  if [ -f "$M" ]; then
    jq -S --slurpfile t "$TMP_MCP" \
      '.mcpServers = ((.mcpServers // {}) * ($t[0].mcpServers // {}))' \
      "$M" > "$M.tmp" && mv "$M.tmp" "$M"
    say "已合并 $M 顶层 mcpServers（缺失 server 补齐，既有条目不动）"
  else
    cp "$TMP_MCP" "$M"
    chmod 600 "$M"
    say "已生成 $M"
  fi
  rm -f "$TMP_MCP" 
  rm -f "$TMP_TPL"

  [ ! -e "${HOME_DIR}/.claude/CLAUDE.md" ] && ln -s "${HOME_DIR}/.codex/AGENTS.md" "${HOME_DIR}/.claude/CLAUDE.md" 2>/dev/null && say "已软链 ~/.claude/CLAUDE.md -> ~/.codex/AGENTS.md"
fi

# ---------- 4. Gemini CLI（直接消费 canonical skill） ----------
if [ -d "${HOME_DIR}/.gemini" ]; then
  say "-- Gemini CLI --"
  GC="${HOME_DIR}/.gemini/config"
  G_SKILLS="${GC}/skills.json"
  G_MCP="${GC}/mcp_config.json"
  mkdir -p "$GC"
  backup_file "$G_SKILLS"
  if [ -f "$G_SKILLS" ]; then
    jq -S --arg p '~/.agents/skills' \
      '.entries = (((.entries // []) + [{path: $p}]) | unique_by(.path))' \
      "$G_SKILLS" > "$G_SKILLS.tmp" && mv "$G_SKILLS.tmp" "$G_SKILLS"
    say "已确保 $G_SKILLS 包含 ~/.agents/skills（不创建硬链接副本）"
  else
    jq -n --arg p '~/.agents/skills' '{entries: [{path: $p}]}' > "$G_SKILLS"
    say "已生成 $G_SKILLS"
  fi
  if [ -f "$G_MCP" ]; then
    if jq empty "$G_MCP" >/dev/null 2>&1; then
      say "$G_MCP 已存在（保留；后续用 agentctl mcp adopt/sync 统一）"
    else
      say "!! $G_MCP JSON 语法错误，请先修复；本次不覆盖"
    fi
  else
    say "未发现 $G_MCP；需要时用 agentctl mcp add/sync 创建"
  fi
fi

# ---------- 5. OpenCode ----------
if [ -d "${HOME_DIR}/.config/opencode" ]; then
  say "-- OpenCode(CANN) --"
  backup_file "${HOME_DIR}/.config/opencode/opencode.jsonc"
  CW="$(ask 'CANN auth 插件 js 路径(留空跳过)' '')"
  CB="$(ask 'CANN docagent 插件 js 路径(留空跳过)' '')"
  RAG="$(ask 'rag-retrieval MCP URL(留空跳过)' '')"
  sed -e "s|{{CANNWORK_PLUGIN}}|$CW|g" -e "s|{{CANNBOT_PLUGIN}}|$CB|g" -e "s|{{RAG_URL}}|$RAG|g" \
      "$REPO_DIR/per-agent/opencode.jsonc.template" > "${HOME_DIR}/.config/opencode/opencode.jsonc"
  say "已生成 ~/.config/opencode/opencode.jsonc"
fi

# ---------- 6. Antigravity & Antigravity IDE ----------
if [ -d "${HOME_DIR}/.gemini" ]; then
  say "-- Antigravity & Antigravity IDE --"
  mkdir -p "${HOME_DIR}/.gemini/config"
  backup_file "${HOME_DIR}/.gemini/config/mcp_config.json"
  
  # 检测本地 Obsidian Vault 路径
  DEF_VAULT=""
  [ -d "${HOME_DIR}/win_office/Liang/Documents/Bright的知识库" ] && DEF_VAULT="${HOME_DIR}/win_office/Liang/Documents/Bright的知识库"
  VAULT_PATH="$(ask 'Obsidian 知识库绝对路径' "$DEF_VAULT")"

  # 检测本地 HuggingFace Token
  HF_TOKEN=""
  [ -f "${HOME_DIR}/.cache/huggingface/token" ] && HF_TOKEN="$(head -n 1 "${HOME_DIR}/.cache/huggingface/token" 2>/dev/null || true)"
  HF_TOKEN="$(ask 'Hugging Face API Token' "$HF_TOKEN")"

  sed -e "s|{{HOME}}|$HOME_DIR|g" -e "s|{{OBSIDIAN_VAULT_PATH}}|$VAULT_PATH|g" -e "s|{{HUGGINGFACE_API_KEY}}|$HF_TOKEN|g" \
      "$REPO_DIR/per-agent/antigravity.mcp_config.json.template" > "${HOME_DIR}/.gemini/config/mcp_config.json"
  say "已生成 ~/.gemini/config/mcp_config.json（已配置 7 大核心 MCP 服务）"

  # 配置技能发现路径
  cat << 'SKJSON' > "${HOME_DIR}/.gemini/config/skills.json"
{
  "entries": [
    {
      "path": "~/.gemini/config/skills"
    },
    {
      "path": "~/.agents/skills"
    }
  ]
}
SKJSON
  say "已配置 ~/.gemini/config/skills.json 双重技能检索路径"
fi

# ---------- 7. agentctl（统一 skills / MCP 管理层） ----------
say "-- agentctl --"
mkdir -p "${HOME_DIR}/.local/bin" "${HOME_DIR}/.agents/skills"
ln -sf "$REPO_DIR/bin/agentctl" "${HOME_DIR}/.local/bin/agentctl"
chmod +x "$REPO_DIR/bin/agentctl"
say "已安装 agentctl -> ~/.local/bin/agentctl"
AC="${HOME_DIR}/.local/bin/agentctl"

# 管理者 skill：本仓库自带，首次安装后由所有已安装 Agent 共享同一份硬链接投影。
if [ -d "${HOME_DIR}/.agents/skills/agent-config-manager" ]; then
  "$AC" enable agent-config-manager --agent all || true
else
  "$AC" install "$REPO_DIR/skills/agent-config-manager" \
    --name agent-config-manager --agent all || true
fi

"$AC" status || true
say "已有副本先看收敛计划: agentctl adopt    （确认后再加 --apply）"

# cc-switch 若同时同步 skills，会和 agentctl 的单一 canonical store 争夺写入权。
CC_SETTINGS="${HOME_DIR}/.cc-switch/settings.json"
if [ -f "$CC_SETTINGS" ]; then
  if command -v jq >/dev/null 2>&1; then
    CC_SYNC="$(jq -r '.skillSyncMethod // "unknown"' "$CC_SETTINGS" 2>/dev/null || echo unknown)"
    CC_STORAGE="$(jq -r '.skillStorageLocation // "unknown"' "$CC_SETTINGS" 2>/dev/null || echo unknown)"
    if [ "$CC_SYNC" = "symlink" ] && [ "$CC_STORAGE" = "unified" ]; then
      say "cc-switch skill sync: symlink + unified（与 agentctl 共享单一副本）"
    else
      case "$CC_SYNC" in
        off|disabled|none|manual) say "cc-switch skill sync: $CC_SYNC（与 agentctl 不冲突）" ;;
        *) say "!! cc-switch skill sync=$CC_SYNC, storage=$CC_STORAGE；请改为 symlink + unified，或关闭其 skills 同步" ;;
      esac
    fi
  else
    say "! 检测到 cc-switch，但未安装 jq；请手动确认其 skill sync 为 symlink + unified 或关闭"
  fi
fi

# ---------- 8. Skills 清单拉取 ----------
say "-- Skills --"
if command -v git >/dev/null 2>&1; then
  say "skills 统一由 agentctl 管理：install / update / remove / enable / disable / sync"
  say "第三方来源见 skills/manifest.yaml；仓库不 vendored 实体，按清单拉取。"
  say "启用后单个 skill 只存一份（~/.agents/skills），各 Agent 使用硬链接投影。"
else
  say "未找到 git，跳过 skill 拉取。"
fi

say "完成。请：1) 编辑 ~/.codex/USER_CONTEXT.md 2) 重开会话 3) 跑 ./verify.sh 复核"
