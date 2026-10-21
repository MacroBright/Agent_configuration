# agent-config

> Unified, version-controlled multi-agent configuration and engineering rules for Codex, Claude Code, OpenCode, Gemini CLI and Antigravity.

<p align="left">
  <a href="README.md">English</a> ·
  <a href="README.zh-CN.md">简体中文</a>
</p>

---

## Overview

`agent-config` provides a decoupled, reproducible configuration framework for multi-agent development environments. Instead of maintaining monolithic, tool-specific configuration files on every machine, agent behavior is separated into five layers:

1. **Global Rules Layer** (`global/AGENTS.md`): Universal engineering principles, non-negotiables, task execution modes, and safety boundaries.
2. **User Context Layer** (`global/USER_CONTEXT.md.template`): Long-term user orientation, engineering preferences, and working styles, isolated from transient project states.
3. **Project Template Layer** (`global/templates/`): Modular starting points for general software projects and specialized domains such as robotics and embodied AI.
4. **Agent Adapter Layer** (`per-agent/`): Tool-specific configuration and MCP templates with no hardcoded credentials or machine-dependent paths.
5. **Capability Management Layer** (`bin/agentctl`): One canonical skill store, one writer, and per-agent projections for skills, MCP servers, and plugins.

```
                  +-----------------------------------+
                  |        global/AGENTS.md          |  Shared rules & non-negotiables
                  +-----------------------------------+
                                    |
                  +-----------------------------------+
                  |      ~/.codex/USER_CONTEXT.md    |  Long-term engineering profile
                  +-----------------------------------+
                                    |
       +----------------------------+----------------------------+
       |                                                         |
       v                                                         v
+-----------------------------+           +---------------------------------------------+
| global/templates/           |           | per-agent/                                  |
| ├── project-AGENTS.md       |           | ├── codex.config.toml.template              |
| ├── robotics-AGENTS.md      |           | ├── claude.settings.json.template           |
| └── project-SESSION_STATE.md|           | ├── claude.mcp.json.template                |
+-----------------------------+           | ├── opencode.jsonc.template                 |
                                          | └── antigravity.mcp_config.json.template    |
                                          +---------------------------------------------+
                                    |
                                    v
                  +-----------------------------------+
                  |      bin/agentctl                |  Single writer for skills/MCP/plugins
                  +-----------------------------------+
                                    |
                  +-----------------------------------+
                  |   ~/.agents/skills/<name>        |  Canonical copy (hardlinked out)
                  +-----------------------------------+
```

---

## Agent Support Matrix

| Agent | Target Config Path | Integration Method | Key Features |
| :--- | :--- | :--- | :--- |
| **Codex** | `~/.codex/config.toml` | Native config + local `auth.json` | Custom provider, reasoning effort control, bundled plugins |
| **Claude Code** | `~/.claude/settings.json`<br>`~/.claude/mcp.json` | Merged settings + symlinked `CLAUDE.md` | Non-destructive JSON merge, hardware safety deny list, MCP baseline |
| **OpenCode** | `~/.config/opencode/opencode.jsonc` | Native config | CANN toolchain plugins, remote RAG retrieval integration |
| **Gemini CLI / Antigravity** | `~/.gemini/config/GEMINI.md`<br>`~/.gemini/config/mcp_config.json` | Global rule deployment + MCP baseline | Core MCP servers, skill consumption via `skills.json` |

---

## Directory Structure

```text
.
├── global/
│   ├── AGENTS.md                  # Unified rules layer shared across all agents
│   ├── USER_CONTEXT.md.template   # Long-term user context template
│   └── templates/
│       ├── project-AGENTS.md      # Template for standard software projects
│       ├── robotics-AGENTS.md     # Template for robotics/CAN/ROS2/LeRobot projects
│       └── project-SESSION_STATE.md  # Handoff blackboard for multi-agent work
├── per-agent/
│   ├── codex.config.toml.template
│   ├── claude.settings.json.template
│   ├── claude.mcp.json.template
│   ├── opencode.jsonc.template
│   └── antigravity.mcp_config.json.template
├── skills/
│   ├── manifest.yaml              # Declarative registry of upstream skill sources
│   ├── curated.txt                # Whitelist of active, verified skills
│   └── agent-config-manager/      # The skill that teaches an agent to use agentctl
├── bin/
│   └── agentctl                   # Single-writer CLI for skills, MCP and plugins
├── tests/
│   └── test_agentctl.py           # Isolated tests using a temporary HOME
├── scripts/
│   ├── collab-init.sh             # Project-level collaboration scaffolding
│   ├── collab-tmux.sh             # Multi-agent tmux workspace and snapshots
│   └── collab-precompact.sh       # Persist state before context compaction
├── install.sh                     # Interactive bootstrap script
├── verify.sh                      # Secret scanning and installation validation
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

- Detects installed agent environments (`Codex`, `Claude Code`, `OpenCode`, `Gemini CLI`).
- Creates timestamped backups (`*.bak-YYYYMMDD`) before modifying any existing configuration.
- Prompts for environment variables (model name, base URLs, API keys, vault paths).
- For **Claude Code**: performs a non-destructive merge, retaining custom environment variables and plugins, computing the union of `deny`/`ask` permissions, and adding missing MCP servers without overwriting existing ones.
- For **Gemini CLI / Antigravity**: provisions `mcp_config.json` and points `skills.json` at the canonical skill store.
- Installs `agentctl` at `~/.local/bin/agentctl` and installs `agent-config-manager` into the canonical skill store.
- Writes secrets exclusively to local files such as `~/.codex/auth.json` (`chmod 600`), ensuring credentials never enter git tracking.

### 2. Verification

After installation, or before committing changes, run:

```bash
./verify.sh
```

The verification script checks:

- **Secret Scanning**: Regex scan for leaked API keys, tokens, and private keys across the repo.
- **Repository Integrity**: Validates the presence and structure of all required templates, scripts, and manager files.
- **Agent Sanity Checks**: Verifies `AGENTS.md` placement, Claude JSON validity, `permissions.deny` rules, and Gemini/Antigravity configuration.
- **Skill Discovery**: Confirms that whitelisted skills have a valid `SKILL.md` and that projections resolve correctly.

---

## Capability Management

`agentctl` is the only component that installs, enables, disables, updates, or removes capabilities. It keeps one canonical copy under `~/.agents/skills/<name>`, projects that copy into each agent, and keeps MCP and plugin operations behind the same command surface. The repository records rules, templates, and the manager itself; it does not vendor third-party skills or secrets.

| Area | Source of Truth | Write Path |
| --- | --- | --- |
| Skills | `~/.agents/skills/<name>` | Hardlink projections plus one canonical copy |
| MCP | `~/.agents/agentctl/mcp.json` | Merged into each agent's native config |
| Plugins | Each agent's native inventory | Delegated to each agent's CLI |
| Instructions | This repository (`global/`, `per-agent/`) | Installed by `install.sh` |

### Skills

```bash
agentctl status                  # canonical count, links, duplicates
agentctl doctor                  # broken links, conflicts, duplicate copies
agentctl list                    # skills and the agents that can see them

agentctl install <path-or-git-url> [--name NAME] [--subpath skills] [--agent all]
agentctl enable  <name> --agent codex
agentctl disable <name> --agent claude
agentctl update  <name>          # or --all
agentctl remove  <name>          # dry-run; add --apply to execute
agentctl adopt                   # dry-run plan to converge existing copies
```

- `disable` removes one agent's projection only; the canonical copy stays.
- `update` works through the shared inode, so every enabled agent sees the new content immediately.
- `adopt` converges skill copies created by other tools. It never overwrites a differing canonical copy; conflicts are reported.
- If a hardlink is impossible (for example, a different filesystem), the fallback is a copy and `status` reports it as such.
- Gemini is a consumer rather than a projection: its `skills.json` points at the canonical directory, so no second tree is created.

### MCP

```bash
agentctl mcp list
agentctl mcp add <name> '{"command":"npx","args":["-y","pkg"]}'
agentctl mcp add <name> '{"url":"https://example.com/mcp"}'
agentctl mcp sync [--agent all]
agentctl mcp adopt
agentctl mcp enable  <name> --agent claude [--apply]
agentctl mcp disable <name> --agent claude [--apply]
agentctl mcp remove  <name> [--agent all] [--apply]
agentctl mcp duplicates [--json] [--all]
```

- `enable` / `disable` change one agent only; the registry entry and other agents stay untouched.
- Both are dry-run by default; add `--apply` to rewrite the target agent's config.
- `remove` deletes the registry entry itself, so prefer `disable` for ordinary de-duplication.
- `duplicates` groups definitions by Docker image, `uvx`/`npx` package, local script, or HTTP endpoint. It reports same-agent duplicates and cross-agent version drift as warnings, and cross-agent name/service variants as notes. It never prints env or header values.

Claude and Gemini use merged JSON. Codex uses a marked TOML block, so handwritten MCP entries are preserved. OpenCode is read-only for now because rewriting JSONC would drop comments. Secret-looking values are stored as `${ENV_NAME}`; the registry never contains the literal token.

### Plugins

```bash
agentctl plugin list [--json]
agentctl plugin install <selector> --agent <agent> [--apply]
agentctl plugin update [selector] --agent <agent> [--apply]
agentctl plugin uninstall <selector> --agent <agent> [--apply]
agentctl plugin enable|disable <selector> --agent claude [--apply]
```

Plugin writes are dry-run by default and only accept one `--agent` at a time. Capabilities differ by ecosystem:

| Agent | list | install | update | uninstall | enable/disable |
| --- | --- | --- | --- | --- | --- |
| Claude Code | yes | yes | yes | yes | yes |
| Codex | yes | yes | marketplace refresh | yes | no |
| OpenCode | yes | yes | yes (`--force`) | no | no |
| Gemini CLI | yes | no | no | no | no |

Unsupported actions exit with code `2`; they are capability gaps, not failures to retry. Plugin caches are not hardlinked across agents. Each ecosystem has its own manifest and update lifecycle, so the only safe deduplication is at the decision level: inventory first, avoid installing the same function in several agents.

### Let an agent manage it

The repository ships `skills/agent-config-manager`, a skill that tells an agent to use `agentctl` and never edit skill directories by hand. `install.sh` installs it into the canonical store and enables it for every detected agent.

With Codex, for example:

- "把这个 skill 只启用给 Claude，Codex 不需要"
- "盘点所有 agent 的 MCP，合并重复项"
- "更新所有 git 来源的 skill，先给我看计划"

The skill enforces dry-run-first for destructive operations, secret masking, and the capability matrix above.

### Coexistence

- **cc-switch** should only switch providers and models. If its skill sync stays enabled, use `skillSyncMethod=symlink` with `skillStorageLocation=unified`; `copy` and `auto` create competing duplicates. `verify.sh` reports the current values.
- **HarnessKit** is not a dependency of this setup. If installed separately, use it only for read-only inventory and audit.
- Do not run two tools that sync skills at the same time.

---

## Multi-Agent Collaboration & Shared Knowledge Graph

`agent-config` formalizes a tripartite division of labor and persistent shared memory across **Antigravity, Claude Code, and Codex**.

### 1. Tripartite Role Specialization Matrix

| Agent | Core Model & Attributes | Strategic Role | Primary Responsibilities |
| :--- | :--- | :--- | :--- |
| **Antigravity** | **Gemini 3.8 Flash**<br>- 1M context window<br>- Auto-compaction (~135k tokens)<br>- Linux sandbox environment<br>- Multimodal document ingestion | **Reconnaissance & Global Scope**<br>*(看得广)* | - **Global Codebase Scanning**: Maps architecture topology, dependency graphs, and blast radius.<br>- **Specification Ingestion**: Parses PDFs, DBC specs, and hardware manuals; generates publication-grade diagrams (`diagram-design`).<br>- **Long-Running Migrations**: Executes multi-module batch migrations using auto-compaction and sandboxed execution.<br>- **Full-Spectrum Verification**: Runs project-wide regression testing and documentation closure. |
| **Claude Code** | **DeepSeek V4.1 Flash**<br>- 1M context window<br>- Isolated subagent hierarchy<br>- Strict permission sandboxing (`Ask/Deny`) | **Deep Planning & Quality Arbiter**<br>*(想得深)* | - **Deep Task Breakdown**: Translates complex requirements into structured, low-risk `implementation_plan.md` designs.<br>- **Two-Axis Code Review**: Orchestrates parallel subagents for independent spec and standard verification (`two-axis-review`).<br>- **Deadlock & Race Condition Arbitration**: Root-cause analysis for subtle concurrency or multi-module state issues.<br>- **Hardware Safety Gatekeeper**: Enforces permission boundaries before critical hardware commands. |
| **Codex** | **DeepSeek V4.1 Flash**<br>- Fine-tuned code model<br>- High-throughput routing<br>- Tight terminal integration | **Surgical Precision & Fast Execution**<br>*(改得准)* | - **Surgical Implementation**: Writes dense, deterministic code with minimal diffs and zero speculative bloat.<br>- **TDD & Protocol Scaffolding**: Rapid test scaffolding, CAN DBC serialization, and SocketCAN driver logic.<br>- **Adversarial Review**: Challenges implementation assumptions and detects corner-case regressions.<br>- **Hotfix Rapid Response**: Pinpoints single-point defects and applies verified fixes. |

### 2. Four-Phase Collaborative Loop

Complex tasks progress through a standardized handoff pipeline:

```
[Phase 1: Reconnaissance] ──> [Phase 2: Deep Planning] ──> [Phase 3: Surgical Execution] ──> [Phase 4: Global Verification]
      (Antigravity)                  (Claude Code)                     (Codex)                       (Antigravity)
   Broad scans & specs          Invariants & Task Plan            Rapid TDD & Code            Integration & Closure
   Populate Graph               Update Blackboard                 Two-Axis Cross-Review       Archive State
```

1. **Phase 1: Reconnaissance & Impact Analysis (Antigravity)**: Scans codebase dependencies, parses hardware/protocol documents, generates architectural diagrams, and persists discovered entities to `~/.agent-memory/knowledge-graph.jsonl`.
2. **Phase 2: Deep Planning & Architecture Arbitration (Claude Code)**: Breaks down requirements, defines architectural boundaries and safety invariants, generates `implementation_plan.md`, and updates `.agent/SESSION_STATE.md`.
3. **Phase 3: Surgical Execution & Cross-Review (Codex + Claude Code)**: Codex writes TDD unit tests and driver/algorithm code; Claude Code runs two-axis reviews via subagents to verify standards and spec fidelity before merge.
4. **Phase 4: Global Verification & Documentation Closure (Antigravity)**: Executes workspace-wide builds and virtual bus integration tests, verifies multi-module stability, updates ADRs and documentation, and seals the blackboard.

### 3. Cross-Agent Shared Knowledge Graph (`~/.agent-memory/knowledge-graph.jsonl`)

- Uses the MCP Knowledge Graph protocol (`@modelcontextprotocol/server-memory`) with all agents bound to one local JSONL path.
- **Zero-Friction Knowledge Sync**: Hardware calibrations, protocol DBC schemas, or architectural constraints recorded by any agent via `create_entities` / `add_observations` are immediately accessible to all other agents via `read_graph` / `search_nodes`.

### 4. Session State Blackboard Protocol (`.agent/SESSION_STATE.md`)

- Provides a structured handoff template at `.agent/SESSION_STATE.md`, based on `global/templates/project-SESSION_STATE.md`.
- Agents persist work summaries and invariant decisions into the blackboard before session handoffs, enabling incoming agents to resume instantly without context degradation.

### 5. Human-in-the-Loop Governance

- **Complexity Gating**: Trigger multi-agent collaboration only for greenfield projects or complex multi-module architecture tasks. Routine fixes and single-turn queries must be handled by a single agent.
- **Pre-Collaboration Proposal**: Agents must outline objectives, role breakdowns, and expected artifacts for user review and approval before orchestrating multiple agents.
- **Non-Presumption on Decisions**: Present 2–4 concrete choices for key architectural trade-offs, prefixing the recommended option with `(Recommended)`; never make unilateral architectural assumptions.
- **Flexible Manual Dispatch**: Users retain total authority to bypass the standard four-phase sequence and chain any agents as desired.
- **Structured Debriefing**: Upon finishing a collaborative cycle, the concluding agent provides a structured debrief covering status, artifacts, test evidence, and per-agent contributions.

### 6. Activation

New directories remain in clean, single-agent mode by default. To explicitly activate multi-agent collaboration for a project, use either method:

1. **Interactive keyword in chat**: send `/collab-init` or `开启多 Agent 协作`. The agent displays a confirmation card to clarify task scope and select a domain template, then scaffolds `.agent/SESSION_STATE.md` and `AGENTS.md`.
2. **Terminal utility**: run `collab-init` in the project root to provision `.agent/SESSION_STATE.md` interactively.

### 7. Specialized Tooling Matrix in Collaboration Mode

Each agent pre-screens and activates a lean toolkit curated from the verified skills and core MCP services:

- **Antigravity (broad reconnaissance)**: `diagram-design`, `research`, `domain-modeling`, `documentation-and-adrs`, `verification-before-completion`, with MCPs `memory`, `markitdown`, `arxiv`, `obsidian`.
- **Claude Code (deep planning and arbitration)**: `writing-plans`, `constraint-driven-development`, `subagent-driven-development`, `two-axis-review`, `robotics-hardware-safety`, with MCPs `memory`, `sequential-thinking`.
- **Codex (surgical implementation and TDD)**: `test-driven-development`/`tdd`, `incremental-implementation`, `code-simplification`, `systematic-debugging`, `doubt-driven-development`, with native compiler and test toolchains.
- **Continuous experience crystallization**: pitfalls and hardware calibrations are persisted to the shared graph via `add_observations`.
- **Unconstrained solo mode**: during solo development, all agents retain full access to all installed skills and MCP tools.

### 8. Architectural Synthesis

The collaboration model incorporates proven patterns from open-source agent systems:

1. **Cognitive Reflection Protocol (inspired by Hindsight)**: Replaces unstructured logs with a `Retain-Recall-Reflect` loop. Hard bugs and architectural deadlocks are distilled into `{Trigger → Gotcha → Crystallized Invariant}` entities in the shared graph, recalled under token budgets.
2. **Task Atomic Locks & Iteration Guard (inspired by Paperclip)**: Subtasks cycle through `[PENDING] → [LOCKED: Agent] → [REVIEWING] → [COMPLETED]` to prevent conflicting edits; a default five-iteration budget acts as a runaway circuit breaker and escalates intractable deadlocks to the user.
3. **Seat Topology & Workspace Snapshots (inspired by OpenRig)**: Assigns deterministic roles (`Seat 1 Recon`, `Seat 2 Lead`, `Seat 3 Coder`) and provides `collab-tmux` for terminal orchestration and snapshot persistence.
4. **Context Virtualization & Computation Pushdown (inspired by Context-Mode)**: Promotes the "Think in Code" paradigm, executing inline micro-scripts for read-only analysis and returning only synthesized results; integrates the PreCompact hook with `collab-precompact`; enforces output safeguards via pipe truncation on test suites and build logs.
5. **Adversarial Verification Tier, Exclusive File Ownership & Declarative Subagents (inspired by Antigravity Teamwork & Subagents)**: Establishes a 3-tier adversarial review in Phase 4 comprising Critic (code standards/interface contracts), Challenger (adversarial stress testing/worst-case complexity/CAN packet drop edge cases), and Auditor (ground-truth command output verification/anti-mock/anti-skip audit); enforces Exclusive File Ownership (`[FILES: ...]`); records 3 Integrity Modes (`development` / `demo` / `benchmark`); ships declarative subagent configurations (`agents/explorer.md`, `challenger.md`, `auditor.md`); and supports Fresh Successor Handoffs across milestones to eliminate context degradation.

---

## Coding & Testing Standards

All code generation, editing, and test authoring across agents must adhere to the following baseline engineering standards. In legacy codebases with established CI or linter rules, existing project conventions take precedence; all new code and refactors default strictly to these standards.

1. **Python Guidelines & Unit Testing**:
   - **Coding Style**: Strict adherence to [Python PEP 8](https://pep8.org/): four-space indentation, clear `snake_case` functions and variables, `CamelCase` classes, and grouped imports. Projects should use `flake8`, `black`, `ruff`, or `isort` as configured.
   - **Unit Testing**: Strict adherence to [pytest](http://www.pytest.org/en/latest/): `test_*.py` discovery, native `assert` introspection, `@pytest.fixture` for setup/teardown and dependency injection, and `@pytest.mark.parametrize` for boundary coverage.
2. **C++ Guidelines & Unit Testing**:
   - **Coding Style**: Strict adherence to [Google C++ Coding Guidelines](http://google.github.io/styleguide/cppguide.html): self-contained headers, standardized include ordering, RAII memory management with smart pointers, no raw `new`/`delete`, `kConstant` naming, `member_variable_` suffixes, and a Google-based `.clang-format`.
   - **Unit Testing**: Strict adherence to [Googletest Primer](https://github.com/google/googletest/blob/master/googletest/docs/primer.md): `TEST` for independent tests and `TEST_F` with `testing::Test` fixtures for shared state, non-fatal `EXPECT_*` checks versus fatal `ASSERT_*` guards, `EXPECT_NEAR`/`EXPECT_FLOAT_EQ` for floating-point comparisons, integrated with CTest via CMake `gtest_discover_tests`.
3. **Other Programming Languages (Respective Google Style Guides)**:
   - Other languages do not blindly adopt C++ conventions; each adheres to its own Google Style Guide. See the [Google Open Source Style Guides (zh)](https://github.com/zh-google-styleguide/zh-google-styleguide) and the [official index](https://google.github.io/styleguide/).
   - **C**: Google C/C++ subset style with self-contained headers, boundary defense, memory safety, and clear error return codes.
   - **Shell / Bash**: [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html): `#!/usr/bin/env bash`, `set -euo pipefail`, mandatory `local` variables in functions, and robust quoting.
   - **TypeScript / JavaScript**: [Google TypeScript/JavaScript Style Guide](https://google.github.io/styleguide/tsguide.html): explicit types, `const` over `let`, no `var`, and no indiscriminate `any`.
   - **Go and others**: Respective Google Style Guides and idiomatic formatters such as `gofmt`.

---

## Domain Templates

### Standard Project (`global/templates/project-AGENTS.md`)

Designed for general application engineering. Defines project scope, technology stack, build and test commands, formatting standards, and verification criteria.

### Robotics & Embodied AI (`global/templates/robotics-AGENTS.md`)

Designed for physical system development. Enforces strict engineering guardrails:

- **Layer Isolation**: Five-layer architecture (hardware → driver → control → ROS2 → AI policy); direct cross-layer bus writes are prohibited.
- **Real-Time Safety**: Zero dynamic memory allocation (`malloc`, `new`, `std::vector::resize`) in high-frequency control loops; mandatory CAN DLC/CRC verification and a 50 ms watchdog timeout.
- **Kinematic Standards**: Strict SI units (radians, rad/s, Nm, N, m); software limit saturation clamping; singularity damping (DLS).
- **Asynchronous Policy Inference**: Isolates LeRobot neural-network compute from real-time control threads; applies action-chunk smoothing and safety-envelope interception.
- **Hardware Safety Protocol**: Mandates a five-step validation ladder (`vcan0` → simulation → unpowered dry-run → low-speed test → explicit human signoff).

### Collaboration Blackboard (`global/templates/project-SESSION_STATE.md`)

Defines the handoff structure for multi-agent projects: current phase, task status, invariants, evidence, and the next agent's instructions.

---

## Skills Architecture

Skills are managed as a single canonical store with declarative sources:

- `skills/manifest.yaml` tracks upstream repositories and sources.
- `skills/curated.txt` defines the whitelist of active skills. Third-party skill code is not vendored into this repository.
- `~/.agents/skills/` is the canonical store, kept flat for cross-agent discoverability.
- `agentctl` projects each skill into Codex, Claude Code, and OpenCode as hardlinks. Gemini reads the canonical directory directly.
- Enabling or disabling a skill for one agent only changes that agent's projection; it never duplicates content.
- `agent-config-manager` is the operational playbook for agents managing this setup.

---

## Security Model

1. **Zero Secret Storage**: No plaintext API keys, tokens, or credentials are saved in this repository.
2. **Path Abstraction**: Machine-specific paths use `{{PLACEHOLDER}}` tokens rendered at installation time.
3. **Secret-Aware MCP Registry**: Secret-looking MCP values are stored as `${ENV_NAME}` references rather than literal tokens.
4. **Destructive Action Prevention**: Permission policies block destructive shell commands (`rm -rf *`, `dd`, `mkfs`) and unverified hardware writes (`openocd`, `jlink`, `dfu-util`).
5. **Automated Audit**: `verify.sh` scans for credential patterns and installation drift before changes are pushed.

---

## Development

```bash
python3 -m unittest discover -s tests -v
bash -n install.sh
bash -n verify.sh
./verify.sh
```

The tests use a temporary `HOME` and mock agent CLIs, so they do not touch real configuration or installed skills.

---

## License

MIT License. Referenced third-party skills, plugins, and marketplaces remain subject to their respective upstream licenses.
