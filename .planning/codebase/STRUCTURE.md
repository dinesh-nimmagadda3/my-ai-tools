# Directory Structure

## Root Level

| File/Directory | Purpose |
|----------------|---------|
| `cli.sh` | Main installer script |
| `generate.sh` | Config export script |
| `install.sh` | Standalone installer for curl pipe |
| `AGENTS.md` | Coding guidelines for AI agents |
| `README.md` | Project documentation |
| `CONTRIBUTING.md` | Contribution guidelines |
| `TESTING.md` | Testing procedures |
| `MEMORY.md` | Developer notes and learning |
| `configs/` | Source configurations |
| `skills/` | Local marketplace plugins |
| `lib/` | Shared shell utilities |
| `docs/` | User guides and tutorials |
| `tests/` | Test fixtures and scripts |

## `configs/` - Configuration Source

### Configuration Directory Layout

```
configs/
├── claude/              # Claude Code settings
│   ├── settings.json    # Main settings (hooks, statusLine, etc.)
│   ├── mcp-servers.json # MCP server configurations
│   ├── CLAUDE.md        # Agent guidelines
│   ├── commands/        # Custom slash commands
│   ├── agents/          # Custom agent definitions
│   ├── hooks/           # TypeScript-based hooks
│   └── skills/          # Installed skills (80+)
│
├── opencode/            # OpenCode configurations
│   ├── opencode.json    # Main settings
│   ├── agent/           # Custom agents
│   └── command/         # Custom commands
│
├── amp/                 # Amp (Modular) settings
│   ├── settings.json    # Main settings
│   └── AGENTS.md        # Agent guidelines
│
├── ccs/                 # Claude Code Switch
│   ├── config.yaml      # Main configuration
│   ├── delegation-sessions.json
│   └── hooks/           # CCS-specific hooks
│
├── codex/               # OpenAI Codex CLI
│   ├── config.json      # Main config
│   ├── config.toml      # Alternative format
│   └── AGENTS.md        # Agent guidelines
│
├── gemini/              # Google Gemini CLI
│   ├── settings.json    # Main settings
│   ├── agents/          # Custom agents (.md)
│   ├── commands/        # Custom commands (.toml)
│   ├── policies/        # Tool policies (.toml)
│   ├── GEMINI.md        # Main guidelines
│   └── AGENTS.md        # Additional guidelines
│
├── cursor/              # Cursor Agent CLI
│   └── AGENTS.md        # Agent guidelines
│
├── factory/             # Factory Droid
│   ├── AGENTS.md        # Global guidelines
│   ├── mcp.json         # MCP configuration
│   ├── settings.json    # Settings
│   └── droids/          # Custom droid definitions
│
├── copilot/             # GitHub Copilot CLI
│   ├── AGENTS.md        # Agent guidelines
│   └── mcp-config.json  # MCP config
│
├── ai-launcher/         # AI Launcher
│   └── config.json      # Main config
│
├── best-practices.md    # Developer best practices
└── git-guidelines.md    # Git safety guidelines
```

## `skills/` - Local Marketplace Plugins

Each skill is a directory containing a `SKILL.md` file:

```
skills/
├── adr/                    # Architecture Decision Records
│   └── SKILL.md
├── codemap/                # Codebase analysis
│   └── SKILL.md
├── handoffs/               # Session handoff creation
│   ├── SKILL.md
│   └── scripts/
├── pickup/                 # Session handoff resume
│   ├── SKILL.md
│   └── scripts/
├── plannotator-review/      # Code review via Plannotator
│   └── SKILL.md
├── pr-review/              # PR review workflows
│   ├── SKILL.md
│   └── scripts/
├── prd/                    # PRD generation
│   └── SKILL.md
├── qmd-knowledge/          # Knowledge management
│   ├── SKILL.md
│   └── scripts/
├── ralph/                  # PRD to JSON converter
│   └── SKILL.md
├── slop/                   # AI slop detection
│   └── SKILL.md
└── tdd/                    # Test-driven development
    └── SKILL.md
```

## `lib/` - Shared Utilities

```
lib/
└── common.sh    # Shared shell functions (logging, execution, downloads)
```

## `docs/` - User Documentation

```
docs/
├── agent-teams-examples.md
├── claude-code-teams.md
├── learning-stories.md
└── qmd-knowledge-management.md
```

## Naming Conventions

| Item | Convention | Example |
|------|------------|---------|
| Config files | lowercase with hyphens | `mcp-servers.json` |
| Commands | command-name.md | `ultrathink.md` |
| Agents | agent-name.md | `ai-slop-remover.md` |
| Skills | skill-name/ (directory) | `codemap/` |
| Best practices | best-practices.md | `best-practices.md` |

## Key Locations

| Resource | Location in Repo | Target in Home |
|----------|-----------------|----------------|
| Claude Code | `configs/claude/` | `~/.claude/` |
| OpenCode | `configs/opencode/` | `~/.config/opencode/` |
| Amp | `configs/amp/` | `~/.config/amp/` |
| CCS | `configs/ccs/` | `~/.ccs/` |
| Gemini CLI | `configs/gemini/` | `~/.gemini/` |
| Best Practices | `configs/best-practices.md` | `~/.ai-tools/best-practices.md` |
| Git Guidelines | `configs/git-guidelines.md` | `~/.ai-tools/git-guidelines.md` |

## Hooks Structure

Claude Code hooks implemented in TypeScript:

```
configs/claude/hooks/
├── index.ts        # Entry point for hooks
├── git-guard.ts    # Git safety hook
├── session.ts      # Session management
├── lib.ts          # Shared utilities
├── package.json    # TypeScript dependencies
└── tsconfig.json   # TypeScript config
```

## Commands Structure

Custom slash commands as Markdown files:

```
configs/claude/commands/
├── ccs/           # CCS delegation
├── ccs.md         # CCS command
├── ultrathink.md  # Deep thinking mode
└── ...            # Other commands
```

## Agents Structure

Custom agents as Markdown files with YAML frontmatter:

```
configs/claude/agents/
├── ai-slop-remover.md
├── code-reviewer.md
├── documentation-writer.md
├── feature-team-coordinator.md
└── test-generator.md
```

## Configuration File Formats

- **JSON**: Claude, OpenCode, Amp settings, MCP servers
- **YAML**: CCS configuration
- **Markdown**: Commands, agents, skills, guidelines
- **TOML**: Gemini CLI commands, Codex config
- **Shell**: Scripts, hooks (bash/TypeScript)
