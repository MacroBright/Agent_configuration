# agent-config — Personal Agent Configuration / Agent Environment Bootstrap

把跨机器 / 跨工具（Codex、Claude Code、OpenCode）的 agent 配置抽成
**配置规范 + 用户上下文 + Skills 清单 + 每-agent 适配器 + 安装/验证脚本**，
装新机或换 agent 时克隆仓库 → `./install.sh` → `./verify.sh` → Ready，无需反复手配。

流程：
```text
clone → ./install.sh → Agent Environment(规则+上下文+skills+每-agent配置) → ./verify.sh → Ready
```

> ⚠️ 私有仓库。本仓库只放**规则、模板、清单**；**不放密钥、不放本机真实路径、不重新分发第三方 skill 实体**。

## 铁律（请勿违反）
1. **密钥不入库**：API Key / token 由 `install.sh` 写入本地 `~/.codex/auth.json` 并 `chmod 600`。
2. **路径模板化**：所有 `/home/<user>`、桌面路径只以 `{{占位符}}` 出现，安装时本地注入。
3. **skill 清单拉取**：第三方 skill（superpowers / ecc 等）只记录源头，不打包其内容（尊重其许可证 + 可跟上游更新）。
4. **画像中性化**：`USER_CONTEXT.md` 只存长期方向 / 工作偏好，**不含可识别身份信息**。

## 结构
```text
agent-config/
├── global/
│   ├── AGENTS.md                  # 跨 agent 规则层（12 节）
│   ├── USER_CONTEXT.md.template   # 用户画像模板（安装时复制填写）
│   └── templates/project-AGENTS.md# 新项目 AGENTS.md 模板
├── skills/
│   ├── manifest.yaml              # skill 源清单（从哪拉）
│   └── curated.txt                # 激活白名单（75 个）
├── per-agent/                     # 各工具配置模板（.template，含占位符）
├── install.sh                     # 一键引导：备份→写规则→注入密钥→生成各工具配置
├── verify.sh                      # 冒烟 + 推前密钥扫描
└── README.md / LICENSE / .gitignore
```

## 快速开始（新机器）
```bash
git clone <你的私有仓库地址> ~/agent-config && cd ~/agent-config
./install.sh        # 交互式：会问你模型 / Base URL / API Key / CANN 路径等
./verify.sh         # 推前冒烟 + 密钥扫描
# 然后去填 ~/.codex/USER_CONTEXT.md，并重开一个会话生效
```

## 如何新增一种 agent
1. 在 `per-agent/` 加一份 `<agent>.template`，把本机专属值写成 `{{占位符}}`。
2. 在 `install.sh` 加一段：备份 → 从模板渲染 → 写入该 agent 配置目录。
3. 若依赖多个 skill，在 `skills/manifest.yaml` 加源、`curated.txt` 加白名单。

## 如何安全同步回本仓库
```bash
# 每次 push 前必跑
./verify.sh
# 只提交规则/模板/清单
git add global skills per-agent install.sh verify.sh README.md LICENSE .gitignore
git commit -m "chore: 更新……"
git push origin main
```
> `.gitignore` 已排除 `auth.json`、`*.bak*`、真实 `config.toml` 等；即使如此，push 前仍以 `verify.sh` 为准。

## skills 目录作者约定（防止退化成大知识库）
- `skills/` 只放**清单与源**（`manifest.yaml` + `curated.txt`），不内置领域知识实体。
- 编写/挑选新 skill 时按**功能角色**归类思考（`learning / research / debugging / coding / architecture / performance`），
  而不是按领域堆文件（`ascend.md / cpp.md / robotics.md …`）。
- 领域知识（Ascend、C++、ROS2、CUDA 等）由**项目文档 / 专门 skill** 按需加载；
  激活区目录保持**扁平**（Codex 直接扫描 `~/.agents/skills/*/`，物理子目录会破坏发现机制）。
- 目标是：**高层规则稳定、能力模块可替换、项目上下文动态。**

## 授权说明
- 本仓库本人自定义内容按根目录 `LICENSE`（MIT）。
- 引用的第三方仓库（`obra/superpowers`、`affaan-m/everything-claude-code`、`anthropics/claude-plugins-official`、`thedotmack/claude-mem`）各按其自身许可证，本仓库仅引用其地址、不重新分发其内容。
