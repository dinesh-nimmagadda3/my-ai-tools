# MCP Servers Reference

This document is the single source of truth for all MCP servers registered in the **Shared Hub (V5)**. Each entry includes the upstream repository link, the correct configuration, how to verify alignment, and any optional tuning.

> **Hub Registry File:** [`configs/shared-mcp/server-registry.json`](configs/shared-mcp/server-registry.json)
> **Hub Source:** [`configs/shared-mcp/multiplexer.ts`](configs/shared-mcp/multiplexer.ts)
> **Hub Runs At:** `http://localhost:5115`

---

## 🔌 How the Hub Connects Servers

The Hub supports two transport types for backend MCP servers:

| Type | Used When | Transport Class |
|---|---|---|
| `stdio` | Local CLI tools (installed binary) | `StdioClientTransport` |
| `http` | Remote hosted MCP servers (URL-based) | `StreamableHTTPClientTransport` |

> **Legacy Note:** The old `sse` type is still accepted by the Hub's multiplexer but `http` is now the canonical type for all remote servers.

---

## 📋 Server Registry

### 1. context7

| Property | Value |
|---|---|
| **Upstream** | https://github.com/upstash/context7 |
| **Latest Release** | `@upstash/context7-mcp@2.1.8` (Apr 13 2026) |
| **Type** | `http` (Remote Streamable HTTP) |
| **URL** | `https://mcp.context7.com/mcp` |
| **Purpose** | Fetches live, version-specific documentation for any library |

**Registry entry:**
```json
"context7": {
  "type": "http",
  "url": "https://mcp.context7.com/mcp",
  "shared": true,
  "enabled": true
}
```

**MCP Tools exposed:**
- `resolve-library-id` — Maps a library name to its Context7 ID
- `query-docs` — Retrieves documentation for a specific library by ID

**Optional API Key** (for higher rate limits — free tier: 60 req/min, 1000/day):
```json
"context7": {
  "type": "http",
  "url": "https://mcp.context7.com/mcp",
  "env": { "CONTEXT7_API_KEY": "your-key-here" },
  "shared": true,
  "enabled": true
}
```
Get a free key at: https://context7.com/dashboard

**How to verify alignment:**
```bash
# Check their latest README for transport type and URL
curl -s https://raw.githubusercontent.com/upstash/context7/master/README.md | grep -A3 "mcp.context7.com"
```

---

### 2. sequential-thinking

| Property | Value |
|---|---|
| **Upstream** | https://github.com/modelcontextprotocol/servers/tree/main/src/sequentialthinking |
| **Package** | `@modelcontextprotocol/server-sequential-thinking` |
| **Type** | `stdio` (local, spawned via npx) |
| **Purpose** | Enables structured multi-step reasoning for complex analysis tasks |

**Registry entry:**
```json
"sequential-thinking": {
  "type": "stdio",
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"],
  "shared": true,
  "enabled": true
}
```

**MCP Tools exposed:**
- `sequentialthinking` — Dynamic problem decomposition with revision capabilities

**Optional Environment Variables:**
- `DISABLE_THOUGHT_LOGGING`: Set to `true` to disable logging of thought information to the terminal.

**How to verify alignment:**
```bash
# Check if the package command matches official docs
curl -s https://raw.githubusercontent.com/modelcontextprotocol/servers/HEAD/src/sequentialthinking/README.md | grep "@modelcontextprotocol/server-sequential-thinking"
```

---

### 3. qmd

| Property | Value |
|---|---|
| **Upstream** | https://github.com/tobi/qmd |
| **Install Command** | `bun install -g @tobilu/qmd` |
| **Type** | `stdio` (local binary) |
| **Purpose** | AI-powered knowledge management — embed and query project notes |

**Registry entry:**
```json
"qmd": {
  "type": "stdio",
  "command": "qmd",
  "args": ["mcp"],
  "shared": true,
  "enabled": true
}
```

**MCP Tools exposed:**
- `query` — Semantic search over knowledge base
- `get` — Retrieve a specific knowledge entry
- `search` — Full-text search
- `vsearch` — Vector similarity search
- `multi_get` — Retrieve multiple entries
- `status` — Knowledge base status

**Prerequisite:** `qmd` binary must be installed (`bun install -g @tobilu/qmd`)

**How to verify alignment:**
```bash
qmd --version
qmd mcp --help
```

---

### 4. fff

| Property | Value |
|---|---|
| **Upstream** | https://github.com/dmtrKovalenko/fff.nvim |
| **Install Command** | `curl -fsSL https://dmtrkovalenko.dev/install-fff-mcp.sh \| bash` |
| **Type** | `stdio` (local binary) |
| **Purpose** | Fast file search with built-in memory for AI agents |

**Registry entry:**
```json
"fff": {
  "type": "stdio",
  "command": "fff-mcp",
  "args": [],
  "shared": true,
  "enabled": true
}
```

**Prerequisite:** `fff-mcp` binary must be installed via the official installer:
```bash
curl -fsSL https://dmtrkovalenko.dev/install-fff-mcp.sh | bash
```

**How to verify alignment:**
```bash
fff-mcp --version
```

---

## ➕ Adding a New MCP Server

### Step 1 — Add to the registry

Edit [`configs/shared-mcp/server-registry.json`](configs/shared-mcp/server-registry.json):

**For a remote (HTTP) server:**
```json
"my-server": {
  "type": "http",
  "url": "https://my-mcp-server.com/mcp",
  "shared": true,
  "enabled": true
}
```

**For a local (STDIO) server:**
```json
"my-server": {
  "type": "stdio",
  "command": "my-binary",
  "args": ["--flag"],
  "shared": true,
  "enabled": true
}
```

### Step 2 — Restart the Hub

```bash
# Find and stop the running hub
kill $(cat /tmp/shared-mcp-hub.pid) 2>/dev/null || true

# Restart
cd ~/.ai-tools/shared-mcp && bun run multiplexer.ts &
```

### Step 3 — Verify it connected

```bash
curl -s http://localhost:5115/status | jq '.backends'
```

All connected tools (Claude, Gemini, OpenCode, Codex) will automatically gain access to the new server — no client reconfiguration needed.

---

## 🔍 Maintenance Checklist

Use this checklist periodically to keep configurations aligned with upstream:

| Server | Upstream Repo | Check URL / Package |
|---|---|---|
| `context7` | https://github.com/upstash/context7 | `https://mcp.context7.com/mcp` |
| `sequential-thinking` | https://github.com/modelcontextprotocol/servers | `npm show @modelcontextprotocol/server-sequential-thinking` |
| `qmd` | https://github.com/tobi/qmd | `npm show @tobilu/qmd` |
| `fff` | https://github.com/dmtrKovalenko/fff.nvim | Install script URL |

**Things to check on each server update:**
- [ ] URL or package name changed?
- [ ] Transport type changed (http vs sse vs stdio)?
- [ ] New MCP tools added (update AGENTS.md if notable)?
- [ ] Breaking config schema changes?
