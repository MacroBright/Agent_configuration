# agent-config

<div align="center">[English](README.md) · [简体中文](README.zh-CN.md)</div>

Personal agent configuration, versioned and reused across machines and agents (Codex, Claude Code, OpenCode, Antigravity).

Instead of a single oversized `AGENTS.md`, this repo keeps the rules, the user context, and the per-agent adapters separate. Switching to a fresh machine or another agent is a `clone` plus `install.sh`.

## What's inside

- `global/AGENTS.md` — shared rules layer, read by every agent
- `global/USER_CONTEXT.md.template` — stable user profile, filled in at install time
- `global/templates/project-AGENTS.md` — general starting point for a new project's rules
- `global/templates/robotics-AGENTS.md` — dedicated rules for robotics & embodied AI projects (CAN/ROS2/LeRobot/Ascend/Safety)
- `per-agent/*.template` — config templates per tool, machine-specific values as placeholders
- `per-agent/claude.mcp.json.template` — Claude Code MCP baseline (github/obsidian/arxiv/huggingface; the deprecated `memory` and `sequential-thinking` servers are deliberately excluded)
- `skills/manifest.yaml` + `skills/curated.txt` — skill sources and the active whitelist (not vendored)
- `install.sh` / `verify.sh` — bootstrap and re-check an environment

## Getting started

On a fresh machine:

```bash
git clone <this repo> ~/agent-config
cd ~/agent-config
./install.sh
./verify.sh
```

`install.sh` is interactive. It detects which agents are installed (Codex, Claude Code, OpenCode, Antigravity), backs up existing config, then asks for the model, base URL, API key, and any project-specific paths before writing files under `$HOME`. For Claude Code it merges instead of overwriting: existing `env`, plugins and marketplaces are kept, permission rules (`deny`/`ask`) are unioned, and missing MCP servers are added without removing any. Secrets go to `~/.codex/auth.json` (chmod 600) and never into this repo.

`verify.sh` scans the repo for leaked secrets and confirms the installed files, symlinks, and skills are where the agents expect them. It also checks the Claude side: `settings.json` syntax, non-empty `permissions.deny`, plugin/marketplace counts, `CLAUDE.md` presence, and flags the deprecated MCP servers.

## Rules this repo follows

- No secrets in the repo. Keys are written locally by `install.sh`, outside the repository.
- No machine-specific paths hard-coded. Anything that varies per machine is a `{{placeholder}}`, filled in during install.
- Third-party skills are not vendored. The repo records where they come from in `skills/manifest.yaml`.
- `USER_CONTEXT.md` stores long-term direction and preferences, not a résumé or current-project details.

## Adding a new agent

1. Add a template, e.g. `per-agent/<agent>.template`, with `{{placeholders}}` for machine-specific values.
2. Add an install block in `install.sh` that backs up, renders, and writes the template.
3. If the agent needs extra skills, add a source to `manifest.yaml` and extend `curated.txt`.

## Skills organization

Keep `skills/` as a manifest, not a knowledge base. Aim for a small set of well-described skills grouped by role — learning, research, debugging, coding, architecture, performance — rather than a long list of domain files (e.g. `ascend.md`, `cpp.md`). Domain knowledge is loaded by projects or dedicated skills on demand. Active skill directories stay flat so Codex can scan `~/.agents/skills/*/`.

## Security

`.gitignore` excludes `auth.json`, backups, and real config files. Run `./verify.sh` before every push as a final secret check.

## License

MIT for the content in this repo. Referenced marketplaces and skills (obra/superpowers, everything-claude-code, claude-plugins-official, claude-mem) are third-party and governed by their own licenses.
