---
name: agent-config-manager
description: Manage the user's cross-agent skills, MCP servers and plugins through the `agentctl` CLI. Use when the user asks to install, update, remove, enable, disable, audit or deduplicate skills, inspect/sync MCP servers, or install/update/remove plugins across Codex, Claude Code, Gemini CLI and OpenCode. Never edit agent skill directories or the canonical store by hand.
---

# Agent Configuration Manager

You are the operator of `agentctl`, the single source of truth for this machine's
agent extensions. Your job is to keep one canonical copy of every skill and project
it to each agent as hardlinks, so no skill is duplicated on disk.

## Hard rules

1. **Never modify `~/.agents/skills/<name>` directly** when the user is asking for
   enable/disable/install/remove. Those are projections; edit through `agentctl`.
2. **Never delete an agent skill directory by hand.** Use `agentctl disable` or
   `agentctl remove`.
3. **Dry-run first.** `adopt` and `remove` are dry-run by default. Always show the
   plan to the user and get confirmation before adding `--apply`.
4. **Do not let two managers own skills.** cc-switch and HarnessKit may inventory
   skills, but only `agentctl` may install/enable/disable them. cc-switch is safe
   only with `skillSyncMethod=symlink` and `skillStorageLocation=unified`; `copy`
   and `auto` can create competing copies.
5. **Secrets never enter the repo or the lockfile.** MCP specs may reference env
   var names, never literal tokens.
6. **Plugins are ecosystem-specific.** `agentctl` delegates plugin writes to each
   agent's native CLI. Never copy or hardlink a plugin cache between agents, and
   never claim feature parity that the native CLI does not provide.

## Standard workflow

```bash
agentctl status          # canonical size, per-agent link/copy counts
agentctl doctor          # broken links, conflicts, duplicate copies
agentctl list            # what exists and which agents have it
```

Before any change, run `status` and `doctor` and report the current state.

### Install

```bash
agentctl install <local-path-or-git-url> [--name NAME] [--subpath skills] [--agent all]
```

This copies into `~/.agents/skills/<name>` once, then hardlinks into each agent.
If the source is a git URL, record it so `update` works later.

### Enable / disable per agent

```bash
agentctl enable  <name> --agent codex
agentctl disable <name> --agent claude
agentctl enable  <name> --agent all
```

`disable` removes only that agent's projection. The canonical copy is untouched.
This is the correct way to answer "this skill should only be visible to Codex".

### Update

```bash
agentctl update <name>
agentctl update --all
```

Because agents share inodes with the canonical copy, an update is visible to every
enabled agent immediately. No re-sync needed.

### Remove

```bash
agentctl remove <name>            # dry-run
agentctl remove <name> --apply
```

Moves the canonical copy to `~/.agents/agentctl/trash/` and removes all projections.

### Adopt existing copies

```bash
agentctl adopt            # dry-run plan
agentctl adopt --apply    # converge into canonical + hardlinks
```

Use this after installing a new agent or after another tool created copies.
It never overwrites a differing canonical version; conflicts are reported for a
human decision.

## MCP servers

```bash
agentctl mcp list
agentctl mcp add <name> '{"command":"...","args":[...],"env":{"KEY":"..."}}'
agentctl mcp add <name> '{"url":"https://...","headers":{...}}'
agentctl mcp sync [--agent all]
agentctl mcp enable  <name> --agent claude [--apply]
agentctl mcp disable <name> --agent claude [--apply]
agentctl mcp remove  <name> [--apply]
```

- Claude Code, Gemini and OpenCode are JSON-based and merged.
- Codex uses a marked TOML block (`# >>> agentctl:mcp >>>`). Handwritten entries
  with the same name are preserved and never duplicated.
- OpenCode is read-only for now because JSONC comments would be lost.
- Always show the user the exact spec before adding an MCP server that starts a
  process or opens a network connection.

## Plugins

```bash
agentctl plugin list [--json]
agentctl plugin install <selector> --agent <one-agent> [--apply] [--json]
agentctl plugin uninstall <selector> --agent <one-agent> [--apply] [--json]
agentctl plugin update [selector] --agent <one-agent> [--apply] [--json]
agentctl plugin enable <selector> --agent claude [--apply]
agentctl plugin disable <selector> --agent claude [--apply]
```

Plugin changes are **dry-run by default**. Show the generated native command to the
user and run it only after confirmation by adding `--apply`.

Native capabilities are intentionally uneven:

- **Claude Code**: list, install, update, uninstall, enable, disable.
- **Codex**: list, install (`PLUGIN@MARKETPLACE`), uninstall, marketplace upgrade.
  It has no single-plugin update and no enable/disable command; `update` means
  refreshing a marketplace snapshot.
- **OpenCode**: list, install, update (`--force`). It has no uninstall or
  enable/disable command.
- **Gemini CLI**: inventory only.

Unsupported actions return exit code `2`; report that capability gap instead of
simulating success. Before an install, `agentctl` refuses to add a plugin with the
same base name that is already enabled in another agent. `--allow-cross-agent`
overrides this explicitly, but plugin caches still remain separate by design.

### Plugin cache policy

Do not try to deduplicate plugin caches across agents with hardlinks or symlinks.
Each ecosystem has its own manifest, loader and update lifecycle. Deduplicate only
the decision to install: inventory all agents first, avoid installing the same
function in several ecosystems, and state clearly that cross-ecosystem cache
sharing is unsupported.

## Reporting

After any operation, report:

- what changed (canonical count, per-agent links)
- evidence (`agentctl status`, `agentctl doctor`)
- what is still unverified (e.g. the agent needs a restart to reload skills)
- rollback path (`~/.agents/agentctl/trash/`, `~/.agents/agentctl/backups/`)

## Failure handling

- `unmanaged directory` on enable: run `agentctl adopt` first; do not delete it.
- `content-conflict`: show both hashes/paths and ask the user which version wins.
- hardlink error / cross-device link: the fallback is a copy; report that dedup is
  not possible for that path and why.
- native plugin CLI missing: report the missing executable and leave state unchanged.
- unsupported plugin action: exit code `2` is a capability gap, not a transient
  failure; do not retry or work around it by editing vendor caches.
