# agent-config

> Unified, version-controlled multi-agent configuration and engineering rules across CLI agents and IDEs (Codex, Claude Code, OpenCode, Antigravity).

<p align="left">
  <a href="README.md">English</a> ·
  <a href="README.zh-CN.md">简体中文</a>
</p>

---

## Overview

`agent-config` provides a decoupled, reproducible configuration framework for multi-agent development environments. Rather than maintaining monolithic, tool-specific configuration files across multiple machines, this repository separates agent behavior into four distinct layers:

1. **Global Rules Layer** (`global/AGENTS.md`): Universal engineering principles, non-negotiables, task execution modes, and safety boundaries.
2. **User Context Layer** (`global/USER_CONTEXT.md.template`): Long-term user orientation, engineering preferences, and working styles, isolated from transient project states.
3. **Project Template Layer** (`global/templates/`): Modular starting points for general software projects and specialized domains (e.g., robotics and embodied AI).
4. **Agent Adapter Layer** (`per-agent/`): Tool-specific configurations and MCP templates with zero hardcoded credentials or machine-dependent paths.

```
                  +-----------------------------------+
                  |        global/AGENTS.md           |  <-- Shared engineering rules & non-negotiables
                  +-----------------------------------+
                                    |
                  +-----------------------------------+
                  |      ~/.codex/USER_CONTEXT.md     |  <-- Long-term engineering profile & style
                  +-----------------------------------+
                                    |
       +----------------------------+----------------------------+
       |                                                         |
       v                                                         v
+-----------------------------+           +---------------------------------------------+
| global/templates/           |           | per-agent/                                  |
| ├── project-AGENTS.md       |           | ├── codex.config.toml.template              |
| └── robotics-AGENTS.md      |           | ├── claude.settings.json.template           |
|     (CAN/ROS2/LeRobot)      |           | ├── claude.mcp.json.template                |
+-----------------------------+           | ├── opencode.jsonc.template                 |
                                          | └── antigravity.mcp_config.json.template    |
                                          +---------------------------------------------+
```

---

## Agent Support Matrix

| Agent | Target Config Path | Integration Method | Key Features |
| :--- | :--- | :--- | :--- |
| **Codex** | `~/.codex/config.toml` | Native config + local `auth.json` | Custom provider, reasoning effort control, bundled plugins |
| **Claude Code** | `~/.claude/settings.json`<br>`~/.claude/mcp.json` | Merged settings + symlinked `CLAUDE.md` | Non-destructive JSON merge, hardware safety denial list, MCP baseline |
| **OpenCode** | `~/.config/opencode/opencode.jsonc` | Native config | CANN toolchain plugins, remote RAG retrieval integration |
| **Antigravity** | `~/.gemini/config/GEMINI.md`<br>`~/.gemini/config/mcp_config.json` | Global rule deployment + MCP baseline | 7 core MCP servers, dual skill resolution via `skills.json` |

---

## Directory Structure

```text
.
├── global/
│   ├── AGENTS.md                  # Unified rules layer shared across all agents
│   ├── USER_CONTEXT.md.template   # Long-term persona and engineering preferences template
│   └── templates/
│       ├── project-AGENTS.md      # Template for standard software projects
│       └── robotics-AGENTS.md     # Template for robotics/CAN/ROS2/LeRobot projects
├── per-agent/
│   ├── codex.config.toml.template
│   ├── claude.settings.json.template
│   ├── claude.mcp.json.template
│   ├── opencode.jsonc.template
│   └── antigravity.mcp_config.json.template
├── skills/
│   ├── manifest.yaml              # Declarative registry of upstream skill sources
│   └── curated.txt                # Flat whitelist of 98 active, verified skills
├── install.sh                     # Interactive bootstrap script
├── verify.sh                      # Pre-commit secret scanning and integrity validation
├── LICENSE                        # MIT License
├── README.md                      # English documentation
└── README.zh-CN.md                # Chinese documentation
```

---

## Quick Start

### 1. Installation

On a new development machine:

```bash
git clone https://github.com/MacroBright/Agent_configuration.git ~/agent-config
cd ~/agent-config
./install.sh
```

`install.sh` performs the following steps interactively:
- Detects installed agent environments (`Codex`, `Claude Code`, `OpenCode`, `Antigravity`).
- Creates timestamped backups (`*.bak-YYYYMMDD`) before modifying any existing configuration.
- Prompts for environment variables (model name, base URLs, API keys, vault paths).
- For **Claude Code**: executes a non-destructive merge—retains custom environment variables and plugins, computes the union of `deny`/`ask` permissions, and adds missing MCP servers without overwriting existing ones.
- For **Antigravity**: provisions `mcp_config.json` with 7 core services and configures dual skill discovery paths (`~/.agents/skills` and `~/.gemini/config/skills`).
- Writes secrets exclusively to `~/.codex/auth.json` (`chmod 600`), ensuring credentials never enter git tracking.

### 2. Verification

After installation or prior to committing changes, run:

```bash
./verify.sh
```

The verification script checks:
- **Secret Scanning**: Regex scan for leaked API keys, tokens, or private keys across the repo.
- **Repository Integrity**: Validates the presence and structure of all required templates and scripts.
- **Agent Sanity Checks**: Verifies `AGENTS.md` placement, Claude JSON validity, `permissions.deny` rules, and Antigravity configs.
- **Skill Discovery**: Verifies that all 98 skills listed in `curated.txt` contain a valid `SKILL.md` in the activation zone.

---

---

## Multi-Agent Collaboration & Shared Knowledge Graph

`agent-config` natively supports cross-agent collaborative development and persistent memory across **Antigravity, Claude Code, and Codex**:

### 1. Cross-Agent Shared Knowledge Graph (`~/.agent-memory/knowledge-graph.jsonl`)
- Utilizes the MCP Knowledge Graph protocol (`@modelcontextprotocol/server-memory`) with all agents bound to a unified local JSONL storage path (`~/.agent-memory/knowledge-graph.jsonl`).
- **Zero-Friction Knowledge Sync**: Hardware calibrations, protocol DBC schemas, or architectural constraints recorded by any agent via `create_entities` / `add_observations` are immediately accessible to all other agents via `read_graph` / `search_nodes`.

### 2. Session State Blackboard Protocol (`.agent/SESSION_STATE.md`)
- Provides a structured handoff template at `.agent/SESSION_STATE.md` (based on `global/templates/project-SESSION_STATE.md`).
- **Standard Handoff Workflow**:
  - **Antigravity (Architect)**: System design, `diagram-design` schematics, multi-format doc ingestion.
  - **Codex (Implementer)**: High-throughput algorithm implementation, CAN serialization, TDD test scaffolding.
  - **Claude Code (Reviewer & Debugger)**: Terminal builds, static analysis, `/code-review`, and physical safety verification.
- Agents persist work summaries and invariant decisions into the blackboard before session handoffs, enabling incoming agents to resume instantly without context degradation.

## Domain Templates

### Standard Project (`global/templates/project-AGENTS.md`)
Designed for general application engineering. Defines project scope, tech stack, build/test commands, formatting standards, and verification criteria.

### Robotics & Embodied AI (`global/templates/robotics-AGENTS.md`)
Designed for physical system development. Enforces strict engineering guardrails:
- **Layer Isolation**: 5-layer architecture (Hardware $\rightarrow$ Driver $\rightarrow$ Control $\rightarrow$ ROS2 $\rightarrow$ AI Policy); direct cross-layer bus writes are prohibited.
- **Real-Time Safety**: Zero dynamic memory allocation (`malloc`, `new`, `std::vector::resize`) in high-frequency control loops; mandatory CAN DLC/CRC verification and 50ms watchdog timeout.
- **Kinematic Standards**: Strict SI units (radians, rad/s, Nm, N, m); software limits saturation clamping; singularity damping (DLS).
- **Asynchronous Policy Inference**: Isolates LeRobot neural network compute from real-time control threads; applies action chunk smoothing filters and safety envelope interceptors.
- **Hardware Safety Protocol**: Mandates a 5-step validation ladder (`vcan0` $\rightarrow$ simulation $\rightarrow$ unpowered dry-run $\rightarrow$ low-speed test $\rightarrow$ explicit human signoff).

---

## Skills Architecture

Skills are managed declaratively to keep the repository lightweight:
- `skills/manifest.yaml` tracks upstream repository sources (Superpowers, Everything Claude Code, Anthropic official plugins, Matt Pocock engineering skills, and ForgeMind robotics).
- `skills/curated.txt` defines a flat whitelist of active skills. Third-party skill code is not vendored directly into this repository.
- The active skills directory (`~/.agents/skills/`) remains flat to ensure cross-agent discoverability across Codex, Claude Code, and Antigravity.

---

## Security Model

1. **Zero Secret Storage**: No plaintext API keys, tokens, or credentials are saved within this repository.
2. **Path Abstraction**: Machine-specific paths are abstracted using `{{PLACEHOLDER}}` tokens rendered at installation time.
3. **Destructive Action Prevention**: Pre-configured permission policies block destructive shell commands (`rm -rf *`, `dd`, `mkfs`) and unverified hardware writes (`openocd`, `jlink`, `dfu-util`).
4. **Automated Audit**: Pre-push hooks and `verify.sh` scan for credential patterns and policy compliance before git operations.

---

## License

MIT License. Referenced third-party skills, plugins, and marketplaces are subject to their respective upstream licenses.
