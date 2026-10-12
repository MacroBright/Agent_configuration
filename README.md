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

`agent-config` natively formalizes a tripartite division of labor and persistent shared memory across **Antigravity, Claude Code, and Codex**:

### 1. Tripartite Role Specialization Matrix

| Agent | Core Model & Attributes | Strategic Role | Primary Responsibilities |
| :--- | :--- | :--- | :--- |
| **Antigravity** | **Gemini 3.8 Flash**<br>- 1M Context Window<br>- Auto-Compaction (~135k tokens)<br>- Linux Sandbox Environment<br>- Multimodal Document Ingestion | **Reconnaissance & Global Scope**<br>*(看得广)* | - **Global Codebase Scanning**: Maps architecture topology, dependency graphs, and blast radius with 1M context.<br>- **Specification Ingestion**: Parses PDFs, DBC specs, and hardware manuals; generates publication-grade diagrams (`diagram-design`).<br>- **Long-Running Migrations**: Executes multi-module batch migrations leveraging auto-compaction and sandboxed execution.<br>- **Full-Spectrum Verification**: Runs project-wide regression testing and documentation closure. |
| **Claude Code** | **DeepSeek V4.1 Flash**<br>- 1M Context Window<br>- Isolated Subagent Hierarchy<br>- Strict Permission Sandboxing (`Ask/Deny`) | **Deep Planning & Quality Arbiter**<br>*(想得深)* | - **Deep Task Breakdown**: Translates complex requirements into structured, low-risk `implementation_plan.md` designs.<br>- **Two-Axis Code Review**: Orchestrates parallel subagents for independent spec and standard verification (`two-axis-review`).<br>- **Deadlock & Race Condition Arbitration**: Root-cause analysis for subtle concurrency or multi-module state issues.<br>- **Hardware Safety Gatekeeper**: Strictly enforces permission boundaries before critical hardware commands. |
| **Codex** | **DeepSeek V4.1 Flash**<br>- Fine-tuned 16B Activation<br>- High-Throughput Routing (214.4 tok/s)<br>- Tight Terminal Integration | **Surgical Precision & Fast Execution**<br>*(改得准)* | - **Surgical Implementation**: Writes dense, deterministic code with minimal diffs and zero speculative bloat.<br>- **TDD & Protocol Scaffolding**: Rapid test scaffolding, CAN DBC serialization, and SocketCAN driver logic.<br>- **Adversarial Review**: Challenges implementation assumptions and detects corner-case regressions at 200+ tok/s.<br>- **Hotfix Rapid Response**: Pinpoints single-point defects and applies verified fixes instantly. |

### 2. 4-Phase Collaborative Loop

Complex tasks progress through a standardized handoff pipeline:

```
[Phase 1: Reconnaissance] ──> [Phase 2: Deep Planning] ──> [Phase 3: Surgical Execution] ──> [Phase 4: Global Verification]
      (Antigravity)                  (Claude Code)                     (Codex)                       (Antigravity)
   Broad scans & specs          Invariants & Task Plan            Rapid TDD & Code            Integration & Closure
   Populate Graph               Update Blackboard                 Two-Axis Cross-Review       Archive State
```

1. **Phase 1: Reconnaissance & Impact Analysis (Antigravity)**: Scans codebase dependencies, parses hardware/protocol documents, generates architectural diagrams, and persists discovered entities to `~/.agent-memory/knowledge-graph.jsonl`.
2. **Phase 2: Deep Planning & Architecture Arbitration (Claude Code)**: Breaks down requirements, defines architectural boundaries and safety invariants, generates `implementation_plan.md`, and updates `.agent/SESSION_STATE.md`.
3. **Phase 3: Surgical Execution & Cross-Review (Codex + Claude Code)**: Codex writes TDD unit tests and driver/algorithm code at 200+ tok/s; Claude Code runs two-axis reviews via subagents to verify standards and spec fidelity before merge.
4. **Phase 4: Global Verification & Documentation Closure (Antigravity)**: Executes workspace-wide builds and virtual bus integration tests, verifies multi-module stability, updates ADRs and documentation, and seals the blackboard.

### 3. Cross-Agent Shared Knowledge Graph (`~/.agent-memory/knowledge-graph.jsonl`)
- Utilizes the MCP Knowledge Graph protocol (`@modelcontextprotocol/server-memory`) with all agents bound to a unified local JSONL storage path (`~/.agent-memory/knowledge-graph.jsonl`).
- **Zero-Friction Knowledge Sync**: Hardware calibrations, protocol DBC schemas, or architectural constraints recorded by any agent via `create_entities` / `add_observations` are immediately accessible to all other agents via `read_graph` / `search_nodes`.

### 4. Session State Blackboard Protocol (`.agent/SESSION_STATE.md`)
- Provides a structured handoff template at `.agent/SESSION_STATE.md` (based on `global/templates/project-SESSION_STATE.md`).
- Agents persist work summaries and invariant decisions into the blackboard before session handoffs, enabling incoming agents to resume instantly without context degradation.

### 5. Human-in-the-Loop Governance Principles
- **Complexity Gating**: Trigger multi-agent collaboration only for greenfield projects or complex multi-module architecture tasks. Routine fixes and single-turn queries must be handled by a single agent to avoid token waste.
- **Pre-Collaboration Proposal**: Agents must outline objectives, role breakdowns, and expected artifacts for user review and approval before orchestrating multiple agents.
- **Non-Presumption on Decisions**: Present 2-4 concrete choices for key architectural trade-offs, prefixing the recommended option with `(Recommended)`; never make unilateral architectural assumptions.
- **Flexible Manual Dispatch**: Users retain total authority to bypass standard 4-phase sequences and manually chain any agents as desired.
- **Structured Debriefing**: Upon finishing a collaborative cycle, the concluding agent provides a structured debrief covering status, artifacts, test evidence, and per-agent contributions.

### 6. Activation Instructions
New directories remain in clean, single-agent mode by default. To explicitly activate multi-agent collaboration for a project, use either method:
1. **Interactive Keyword in Chat**:
   - Send `/collab-init` or `开启多 Agent 协作` to any agent.
   - The agent displays a confirmation card to clarify the task scope and select a domain template (Standard vs. Robotics). Upon approval, it scaffolds `.agent/SESSION_STATE.md` and `AGENTS.md`.
2. **Terminal CLI Utility**:
   - Run `collab-init` in the project root to interactively provision `.agent/SESSION_STATE.md` in seconds.

### 7. Specialized Tooling Matrix in Collaboration Mode
When executing multi-agent pipelines, each agent pre-screens and activates a lean, dedicated toolkit curated from the 98 verified skills and core MCP services:
- **Antigravity (Broad Reconnaissance)**: `diagram-design` (architecture schematics), `research` (spec reports), `domain-modeling` (entity modeling), `documentation-and-adrs` (ADR records), `verification-before-completion` (final regression gate) with MCPs `memory`, `markitdown`, `arxiv`, `obsidian`.
- **Claude Code (Deep Planning & Arbitration)**: `writing-plans` (deep planning), `constraint-driven-development` (invariant mining), `subagent-driven-development` (review subagents), `two-axis-review` (standards/spec audit), `robotics-hardware-safety` (hardware safety ladder) with MCPs `memory`, `sequential-thinking`.
- **Codex (Surgical Implementation & TDD)**: `test-driven-development`/`tdd` (rapid unit testing), `incremental-implementation` (minimal surgical diffs), `code-simplification` (anti-bloat refactoring), `systematic-debugging` (root-cause fixes), `doubt-driven-development` (adversarial stress-testing) with native compiler/test toolchains.
- **Continuous Experience Crystallization**: Pitfalls and hardware calibrations are persisted to the shared graph via `add_observations`, improving accuracy and speed over time.
- **Unconstrained Solo Mode Guarantee**: During solo development (non-collab tasks or routine queries), all agents retain full, unrestricted access to all 98 skills and MCP tools.

### 8. Architectural Synthesis from Open-Source Ecosystem
Incorporating proven design patterns from leading agent collaboration projects, this system integrates:
1. **Cognitive Reflection Protocol (inspired by Hindsight)**: Replaces unstructured logs with a `Retain-Recall-Reflect` cognitive loop. Hard bugs and architectural deadlocks are distilled into `{Trigger → Gotcha → Crystallized Invariant}` entities in the shared graph, recalled strictly under token budgets.
2. **Task Atomic Locks & Iteration Guard (inspired by Paperclip)**: Subtasks cycle through `[PENDING]` $\rightarrow$ `[LOCKED: Agent]` $\rightarrow$ `[REVIEWING]` $\rightarrow$ `[COMPLETED]` to prevent conflicting edits; a default 5-iteration budget acts as a runaway circuit breaker, automatically escalating intractable deadlocks to the human Board.
3. **Seat Topology & Workspace Snapshots (inspired by OpenRig)**: Assigns deterministic roles (`Seat 1 Recon`, `Seat 2 Lead`, `Seat 3 Coder`) and includes the `collab-tmux` utility for zero-friction terminal orchestration and workspace snapshot persistence (`collab-tmux snapshot`).

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
