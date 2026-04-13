# my-ai-tools 🤖

> **A portable, interactive setup kit for AI coding tools** — Install, configure, and connect Claude Code, Gemini CLI, OpenCode, and Codex in minutes on any machine, powered by a centralized **Shared MCP Hub (V5)**.

## ✨ Features

- 🧙‍♂️ **Interactive Setup Wizard** — Select exactly which tools and MCP servers to install
- 🌐 **One-line installer** — No cloning needed, just run a `curl` command
- 🔗 **Shared MCP Hub (V5)** — One central hub connects all tools via Streamable HTTP
- 🔄 **Bidirectional sync** — Install configs or export your current setup
- 🤖 **4 AI Tools supported** — Claude Code, Gemini CLI, OpenCode, and Codex
- 🧩 **Skills architecture** — Select and install skills per-tool or apply to all
- 🛡️ **Git Guard Hook** — Prevents dangerous git commands (force push, hard reset, etc.)
- 📦 **Zero clutter** — Installs to your home directory; the repo stays temporary

---

## 🚀 Quick Start

### One-Line Installer (Recommended)

Run this on any machine. No cloning required:

```bash
curl -fsSL https://raw.githubusercontent.com/dinesh-nimmagadda3/my-ai-tools/main/install.sh | bash
```

> **Want to preview first?** Run with `--dry-run`:
> ```bash
> curl -fsSL https://raw.githubusercontent.com/dinesh-nimmagadda3/my-ai-tools/main/install.sh | bash -s -- --dry-run
> ```

> **Security review before running:**
> ```bash
> curl -fsSL https://raw.githubusercontent.com/dinesh-nimmagadda3/my-ai-tools/main/install.sh -o install.sh
> cat install.sh
> bash install.sh
> ```

**Available flags:**
```bash
--dry-run      # Preview what would be changed (safe)
--backup       # Backup existing configs before installing
--no-backup    # Skip backup prompt
--yes / -y     # Auto-select all components (non-interactive)
```

### Manual Installation (Alternative)

```bash
git clone https://github.com/dinesh-nimmagadda3/my-ai-tools.git
cd my-ai-tools
./cli.sh

# Deploy the Hub persistently (Optional but Recommended)
./cli.sh mcp-hub compose-setup
./cli.sh mcp-hub service-install
systemctl --user start shared-mcp
```

---

## 🧙‍♂️ How the Setup Wizard Works

When you run the installer, it walks you through a three-step process:

### Step 1 — Select Components

```
Select components to install (e.g., 1,2,5 or 'all'):
1) Claude Code (CLI)
2) Gemini CLI
3) OpenCode (TUI/CLI)
4) OpenAI Codex CLI
5) Shared MCP Hub (V5 Infrastructure)
6) Common MCP Backends (fff, qmd, context7, memory, filesystem, devtools)
7) Global Tooling (biome, ruff, jq, binlock, etc.)
all) Install everything

Selection: 1,2,5
```

### Step 2 — Configure Each Selected Tool

For each AI tool you selected, the wizard asks:

```
--- Tool Configuration Wizard ---

Configuring Claude:
  Select MCP Connection:
    1) Use Shared Hub (Recommended - Connects to local Hub)
    2) Standalone (Direct connections, no Hub)
  Choice [1]:

  Available Skills in kit:
    [ adr, prd, pr-review, tdd, handoffs, ... ]
  Select Skills to install by name (e.g. 'pr-review, tdd'), 'all', or 'none':
  Skills [all]:

  Apply this configuration to all other selected tools? (y/N): y
```

### Step 3 — Permanent Installation

Everything gets permanently installed onto your machine:

| Component | Machine Location |
|---|---|
| Claude Code config | `~/.claude/` |
| Gemini CLI config | `~/.gemini/` |
| OpenCode config | `~/.config/opencode/` |
| Codex config | `~/.codex/` |
| Shared MCP Hub | `~/.ai-tools/shared-mcp/` |
| Podman Context | `~/projects/my-ai-tools/configs/shared-mcp/` |
| Systemd Service | `~/.config/systemd/user/shared-mcp.service` |
| Skills | `~/.claude/skills/`, `~/.gemini/skills/`, etc. |
| Best practices | `~/.ai-tools/best-practices.md` |

> The cloned repository (or `/tmp/` bootstrap folder) is deleted automatically after installation. **Nothing is tied to the source folder.**

---

Claude Code  ──┐
Gemini CLI   ──┤──▶  Shared Hub (port 5115)  ──▶  fff, qmd, context7 (Core)
OpenCode     ──┤      (Podman Compose)           memory (Memory Graph)
Codex CLI    ──┘       multiplexer.ts            filesystem, devtools (Sys)
                                                 sequential-thinking (Logic)
```

**How it works:**
- **Containerized**: The Hub runs inside a Podman container built from `configs/shared-mcp/Dockerfile` so Chrome DevTools MCP has the runtime libraries it needs.
- **Persistent**: Managed by `systemd` to ensure it starts on boot and auto-restarts on failure.
- **Host-integrated**: The container mounts your real home path and host Chrome install so filesystem and browser tools see the same machine state you do.
- **Standardized**: Uses `configs/shared-mcp/docker-compose.yml` for build and runtime management.

**Management Commands:**

```bash
./cli.sh mcp-hub compose-up      # Launch the cluster
./cli.sh mcp-hub compose-down    # Stop the cluster
./cli.sh mcp-hub service-install # Register systemd unit
./cli.sh mcp-hub cleanup-legacy  # Wipe stale local processes
```

**Verification:**
```bash
systemctl --user status shared-mcp  # Check service status
podman ps                           # Verify container health
journalctl --user -u shared-mcp -f  # Watch hub logs & heartbeats
```

**Adding a new MCP server:**

Edit `configs/shared-mcp/server-registry.json` and add:

```json
"my-new-server": {
  "type": "stdio",
  "command": "npx",
  "args": ["-y", "@my-org/my-mcp-server"],
  "enabled": true
}
```

All connected tools will automatically inherit the new server. No client reconfiguration needed.

> 📖 **Full MCP reference, per-server configs, and maintenance checklist:** [MCP.md](MCP.md)

---

## 🧩 Skills

Skills are per-tool instruction sets stored as `SKILL.md` files that extend an AI tool's capabilities.

### Available Skills (22 Built-in)

| Category | Skill | Description |
|---|---|---|
| **Planning** | `bootstrap` | Establishing a disciplined skill-first session |
| | `brainstorm` | Intent discovery and design exploration before code |
| | `prd` | Generating Product Requirements Documents |
| | `write-plan` | Decomposing specs into bite-sized TDD tasks |
| **Execution** | `subagent-dev` | Plan execution with isolated subagent loops |
| | `exec-plan` | Sequential task execution from a written plan |
| | `tdd` | Red-Green-Refactor development cycle |
| | `parallel-agents`| Orchestrating independent subagents for speed |
| | `ralph` | Converting PRDs to JSON for agent ingestion |
| **Quality** | `pr-review` | Requesting/receiving PR feedback (RIGOROUS) |
| | `debug` | Systematic 4-phase root-cause investigation |
| | `verify-close` | Mandatory evidence-based success verification |
| | `plannotator-review` | Interactive UI-based code reviews |
| | `slop` | Detecting and removing AI-generated boilerplate |
| **Git & Workflow**| `finish-branch` | Standardized merge, PR, and cleanup options |
| | `git-worktree` | Isolated parallel workspaces for features |
| | `adr` | Creating Architecture Decision Records |
| **Session Mgmt** | `handoffs` | Creating session handoff notes (`/handoffs`) |
| | `pickup` | Resuming work from the latest handoff notes |
| | `codemap` | Parallel codebase analysis and mapping |
| **Knowledge** | `write-skill` | TDD-based documentation for new skills |
| | `qmd-knowledge` | Persistent project knowledge management |

### Adding a New Skill

1. Create a folder: `skills/my-skill/`
2. Add a `SKILL.md` file with a `compatibility:` header:

```markdown
compatibility: claude, gemini, opencode, codex

# My Skill
Instructions for the AI go here...
```

3. Run `./cli.sh` — the wizard will discover and offer your new skill automatically.

### Community Skills

Install additional skills from popular community repositories:

```bash
npx skills add expo/skills --global --agent claude-code
npx skills add vercel-labs/agent-skills --global --agent claude-code
npx skills add blader/humanizer --global --agent claude-code
npx skills add jezweb/claude-skills --global --agent claude-code
npx skills add mattpocock/skills --skill grill-me --global --agent claude-code
```

---

## 🛠️ Tool Reference

### Claude Code

Primary AI coding assistant by Anthropic.

**Config location:** `~/.claude/claude.json`

**Key features configured:**
- OpusPlan mode (plans with Opus, implements with Sonnet)
- Auto-formatting hooks (biome, gofmt, ruff, rustfmt, shfmt, stylua)
- Git Guard hook (blocks dangerous git commands)
- Custom agents: `code-reviewer`, `test-generator`, `docs-writer`, `ai-slop-remover`
- Custom commands: `/ultrathink`, `/plannotator-review`

**MCP:** Connected via Shared Hub Bridge (STDIO)

---

### Gemini CLI

Google's terminal AI agent powered by Gemini 2.5.

**Config location:** `~/.gemini/settings.json`

**Key features:**
- Free tier: 60 req/min, 1000 req/day
- 1M token context window
- Google Search grounding built-in

**MCP:** Connected via Hub HTTP endpoint (`http://localhost:5115/hub`)

```bash
# Authenticate
gemini  # Follow OAuth browser flow
# Or use API key
export GEMINI_API_KEY="your-key"
```

---

### OpenCode

Modern TUI-based coding assistant. [Homepage](https://opencode.ai)

**Config location:** `~/.config/opencode/opencode.json`

**Key features:**
- Auto-formatting via built-in `formatter` config
- Plugins: `@plannotator/opencode`, `@mohak34/opencode-notifier`
- Custom agents & commands

**MCP:** Connected via Hub HTTP endpoint (`http://localhost:5115/hub`)

```bash
curl -fsSL https://opencode.ai/install | bash
```

---

### Codex CLI

OpenAI's command-line coding assistant.

**Config location:** `~/.codex/config.toml`

**Key features:**
- TOML-based configuration (automatically managed by installer)
- Kanagawa theme
- Multi-agent support

**MCP:** Shared Hub injected dynamically into `config.toml` during install

```bash
pnpm install -g @openai/codex
```

---

## 🔄 Bidirectional Config Sync

### Forward: Install to Machine (`cli.sh`)

Copy configurations from this repository to your home directory:

```bash
./cli.sh [--dry-run] [--backup] [--no-backup]
```

### Reverse: Export from Machine (`generate.sh`)

Export your current configurations back to this repository for version control:

```bash
./generate.sh [--dry-run]
```

> Use `generate.sh` after customizing your local setup to save changes back to the repo. Commit and push to keep your setup portable.

---

## 📋 Prerequisites

| Requirement | Notes |
|---|---|
| **Git** | Required for cloning/updates |
| **Bun** | Auto-installed if missing |
| **curl** | Required for one-line installer |

> The installer automatically checks for and installs `bun`, `qmd`, and `fff-mcp` if not found.

---

## 📚 Resources

- [Claude Code Documentation](https://claude.com/claude-code)
- [OpenCode Documentation](https://opencode.ai/docs)
- [MCP Servers Directory](https://mcp.so)
- [MCP SDK Reference](https://github.com/modelcontextprotocol/typescript-sdk)
- [Claude Code Best Practices](https://github.com/shanraisshan/claude-code-best-practice)
- [Everything Claude Code](https://github.com/affaan-m/everything-claude-code)
