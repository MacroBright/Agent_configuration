# agent-config

个人 Agent 配置仓库，跨机器、跨 CLI Agent（Codex、Claude Code、OpenCode）统一复用。

本仓库不把配置塞进一份巨大的 `AGENTS.md`，而是把规则、用户上下文、每个 Agent 的适配分开存放。换新机器或换 Agent 时，一次 `clone` 加 `./install.sh` 即可恢复。

## 仓库内容

- `global/AGENTS.md` — 跨 Agent 共享的规则层
- `global/USER_CONTEXT.md.template` — 稳定的用户画像模板，安装时填写
- `global/templates/project-AGENTS.md` — 新项目规则文件的起点
- `per-agent/*.template` — 各工具配置模板，机器相关的值用占位符
- `skills/manifest.yaml` 与 `skills/curated.txt` — skill 来源清单与激活白名单（不打包第三方内容）
- `install.sh` / `verify.sh` — 环境引导与复检脚本

## 快速开始

新机器上：

```bash
git clone <本仓库> ~/agent-config
cd ~/agent-config
./install.sh
./verify.sh
```

`install.sh` 是交互式的。它会先检测本机装了哪些 Agent（Codex / Claude Code / OpenCode），备份已有配置，然后询问模型、Base URL、API Key 以及项目相关路径，最后把文件写入 `$HOME`。密钥写入 `~/.codex/auth.json`（chmod 600），绝不会进入本仓库。

`verify.sh` 会扫描仓库是否有泄露的密钥，并确认安装后的文件、软链接、skill 是否都在 Agent 预期位置。

## 本仓库遵守的规则

- 仓库内不存放密钥，密钥由 `install.sh` 写入本地、位于仓库之外。
- 不硬编码机器相关路径，任何因机器而异的值都用 `{{占位符}}` 表示，安装时替换。
- 不 vendored 第三方 skill，只在 `skills/manifest.yaml` 记录其来源。
- `USER_CONTEXT.md` 只记录长期方向与偏好，不写成履历，也不写当前项目细节。

## 新增一种 Agent

1. 新增模板，如 `per-agent/<agent>.template`，机器相关的值写成 `{{占位符}}`。
2. 在 `install.sh` 加一段：备份 → 渲染模板 → 写入该 Agent 配置目录。
3. 若需要更多 skill，在 `manifest.yaml` 加来源、在 `curated.txt` 加白名单。

## skill 组织方式

`skills/` 保持为清单而不是知识库。目标是少量、描述清晰、按功能角色分组的 skill（学习、研究、调试、编码、架构、性能），而不是一堆按领域堆叠的文件（如 `ascend.md`、`cpp.md`）。领域知识由项目或专门的 skill 按需加载。激活区的 skill 目录保持扁平，这样 Codex 才能扫描 `~/.agents/skills/*/`。

## 安全性

`.gitignore` 已排除 `auth.json`、备份文件与真实配置文件。每次 push 前运行 `./verify.sh` 做最终的密钥检查。

## 许可证

本仓库内容按 MIT 授权。引用的市场和 skill（obra/superpowers、everything-claude-code、claude-plugins-official、claude-mem）均为第三方，遵守其各自许可证。
