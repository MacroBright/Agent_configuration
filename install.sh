#!/usr/bin/env bash
# agent-config 一键安装/同步脚本
# 用途：新机器或新 agent 环境引导。规则入库、密钥本地注入、skill 按清单拉取。
# 注意：本脚本会 ①备份现有配置 ②写入新配置。执行前请先阅读。
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATE="$(date +%Y%m%d)"
HOME_DIR="${HOME:-$HOME}"
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

# ---------- 0. 安全检查 ----------
say "在写任何东西之前，先跑一次仓库密钥扫描（若有泄露立即中止）"
if grep -rInE --exclude-dir=.git -E '(ark-|sk-[A-Za-z0-9]{20,}|ANTHROPIC_API_KEY|OPENAI_API_KEY=.{20,}|ghp_[A-Za-z0-9]{20,})' "$REPO_DIR" 2>/dev/null; then
  say "!! 仓库中发现疑似密钥，中止安装。请先清理后重试。"; exit 1
fi

# ---------- 1. 全局规则 ----------
if [ -d "${HOME_DIR}/.codex" ]; then
  backup_file "${HOME_DIR}/.codex/AGENTS.md"
  cp "$REPO_DIR/global/AGENTS.md" "${HOME_DIR}/.codex/AGENTS.md"
  say "已写入 ~/.codex/AGENTS.md（全局规则层）"
  mkdir -p "${HOME_DIR}/.codex/context/templates"
  cp "$REPO_DIR/global/templates/project-AGENTS.md" "${HOME_DIR}/.codex/context/templates/project-AGENTS.md"
  say "已写入项目级模板"
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
  backup_file "${HOME_DIR}/.claude/settings.json"
  BASE_CL="$(ask 'Claude Base URL(留空则不写 env)' 'http://127.0.0.1:15721')"
  EFFORT="$(ask 'effortLevel(medium)' 'medium')"
  sed -e "s|{{BASE_URL}}|$BASE_CL|g" -e "s|{{EFFORT_LEVEL}}|$EFFORT|g" \
      "$REPO_DIR/per-agent/claude.settings.json.template" > "${HOME_DIR}/.claude/settings.json"
  say "已生成 ~/.claude/settings.json"
  [ ! -e "${HOME_DIR}/.claude/CLAUDE.md" ] && ln -s "${HOME_DIR}/.codex/AGENTS.md" "${HOME_DIR}/.claude/CLAUDE.md" 2>/dev/null && say "已软链 ~/.claude/CLAUDE.md -> ~/.codex/AGENTS.md"
fi

# ---------- 4. OpenCode ----------
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

# ---------- 5. Skills 清单拉取 ----------
say "-- Skills --"
if command -v git >/dev/null 2>&1; then
  say "第三方 skill 源请按 skills/README 手动拉取（manifest.yaml 有源地址）；不自动 clone。"
  say "启新激活区前请把现有 ~/.agents/skills 备份归档；curated.txt 为白名单。"
else
  say "未找到 git，跳过 skill 拉取。"
fi

say "完成。请：1) 编辑 ~/.codex/USER_CONTEXT.md 2) 重开会话 3) 跑 ./verify.sh 复核"
