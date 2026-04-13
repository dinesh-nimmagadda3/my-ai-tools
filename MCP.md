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
  "env": {
    "XDG_CACHE_HOME": "/app/.shared-mcp-data/cache"
  },
  "shared": true,
  "enabled": true
}
```

**MCP Tools exposed:**
- `query` — Hybrid search (BM25 + Vector + Reranking)
- `get` — Retrieve a specific document by path or docid
- `multi_get` — Batch retrieve documents (glob/list)
- `status` — Index health and collection info

**Optional Performance Tuning:**
- Use `qmd mcp --http` to start a long-lived server (prevents model reloading).
- Set `QMD_EMBED_MODEL` to override the default GGUF embedding model.

**Troubleshooting (Node.js Version):**
> [!WARNING]
> `qmd` utilizes `better-sqlite3`, which may have compatibility issues with very recent Node.js versions (e.g., **v23+**). If you see "Init failed for qmd" or "Connection closed" errors:
> 1. Switch to a stable LTS version (**Node v20 or v22**).
> 2. Or rebuild the native bindings: `npm rebuild better-sqlite3 --build-from-source`.

**How to verify alignment:**
```bash
# Check if the mcp command and tools match official docs
qmd --version
node --version
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
  "args": [
    "--frecency-db",
    "/app/.shared-mcp-data/fff/frecency.mdb",
    "--history-db",
    "/app/.shared-mcp-data/fff/history.mdb",
    "--log-file",
    "/app/.shared-mcp-data/fff/fff-mcp.log"
  ],
  "shared": true,
  "enabled": true
}
```

**MCP Tools exposed:**
- `search` — Fast file name search (git-aware)
- `grep` — High-speed content search
- `open` / `get` — Optimized file reading

**Prerequisite:** `fff-mcp` binary must be installed via the official installer:
```bash
curl -fsSL https://dmtrkovalenko.dev/install-fff-mcp.sh | bash
```

**How to verify alignment:**
```bash
# Verify the binary exists and show help
fff-mcp --help
```

---

### 5. memory

| Property | Value |
|---|---|
| **Upstream** | [MCP Servers (Memory)](https://github.com/modelcontextprotocol/servers/tree/main/src/memory) |
| **Package** | `@modelcontextprotocol/server-memory` |
| **Type** | `stdio` (spawned via Bun) |
| **Purpose** | Persistent knowledge graph memory — Claude remembers facts about you across chats |

**Registry entry:**
```json
"memory": {
  "type": "stdio",
  "command": "bun",
  "args": ["x", "-y", "@modelcontextprotocol/server-memory"],
  "env": {
    "MEMORY_FILE_PATH": "$HOME/.ai-tools/memory.jsonl"
  },
  "shared": true,
  "enabled": true
}
```

> [!NOTE]
> The Hub's multiplexer automatically expands the **`$HOME`** variable in `env` and `args` to ensure portability.

**MCP Tools exposed:**
- `create_entities` — Create multiple new entities in the graph
- `create_relations` — Connect entities in the graph
- `add_observations` — Add new facts to existing entities
- `delete_entities` / `delete_relations` / `delete_observations` — Cleanup tools
- `read_graph` — View the entire memory state
- `search_nodes` / `open_nodes` — Query and retrieve memory

**How to verify alignment:**
```bash
# Verify the README for command/args
curl -s https://raw.githubusercontent.com/modelcontextprotocol/servers/main/src/memory/README.md | grep "@modelcontextprotocol/server-memory"
```

---

### 6. filesystem

| Property | Value |
|---|---|
| **Upstream** | [MCP Servers (Filesystem)](https://github.com/modelcontextprotocol/servers/tree/main/src/filesystem) |
| **Package** | `@modelcontextprotocol/server-filesystem` |
| **Type** | `stdio` (spawned via Bun) |
| **Purpose** | Secure local filesystem access — read, write, create, and search files/directories |

**Registry entry:**
```json
"filesystem": {
  "type": "stdio",
  "command": "bun",
  "args": [
    "x",
    "-y",
    "@modelcontextprotocol/server-filesystem",
    "$HOME"
  ],
  "shared": true,
  "enabled": true
}
```

> [!TIP]
> Use **`$HOME`** in the path arguments to ensure the server works correctly regardless of the user account.

In the containerized hub deployment, `$HOME` is mounted to the same absolute host path so filesystem tools expose your real home directory instead of `/root`.

**MCP Tools exposed:**
- `read_text_file` / `read_multiple_files` — Read file contents
- `write_file` / `edit_file` — Create or modify files
- `create_directory` / `list_directory` — Manage directories
- `search_files` / `directory_tree` — Explore the filesystem
- `move_file` / `get_file_info` — File management and metadata

**How to verify alignment:**
```bash
# Verify the README for command/args and allowed paths protocol
curl -s https://raw.githubusercontent.com/modelcontextprotocol/servers/main/src/filesystem/README.md | grep "@modelcontextprotocol/server-filesystem"
```

---

### 7. chrome-devtools

| Property | Value |
|---|---|
| **Upstream** | https://github.com/ChromeDevTools/chrome-devtools-mcp |
| **Package** | `chrome-devtools-mcp` |
| **Type** | `stdio` (spawned via Bun) |
| **Purpose** | Browser automation and inspection — navigate, interact, and debug web pages |

**Registry entry:**
```json
"chrome-devtools": {
  "type": "stdio",
  "command": "bun",
  "args": [
    "x",
    "-y",
    "chrome-devtools-mcp@latest",
    "--headless",
    "--executablePath",
    "/opt/google/chrome/chrome",
    "--userDataDir",
    "/app/.shared-mcp-data/chrome-profile",
    "--chromeArg=--no-sandbox",
    "--chromeArg=--disable-setuid-sandbox"
  ],
  "shared": true,
  "enabled": true
}
```

**MCP Tools exposed:**
- Navigation: `navigate`, `click`, `type`, `scroll`
- Inspection: `get_console_logs`, `get_network_logs`, `screenshot`
- Execution: `evaluate_script`
- **Slim mode**: Use `--slim` in `args` to only expose navigation and screenshots.

**Capabilities & Limitations:**
- **Headless Mode**: ✅ Supported via `--headless` flag (enabled in our default config).
- **Chrome Runtime**: The container mounts the host Chrome install at `/opt/google/chrome` and uses a writable profile under `/app/.shared-mcp-data/chrome-profile`.
- **Firefox Support**: ❌ Not officially supported. The server is purpose-built for Chromium-based browsers via the Chrome DevTools Protocol (CDP).

**How to verify alignment:**
```bash
# Check if the mcp command and flags match official docs
curl -s https://raw.githubusercontent.com/ChromeDevTools/chrome-devtools-mcp/main/README.md | grep "headless"
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
# Restart
cd ~/.ai-tools/shared-mcp
./cli.sh start-hub  # Or: bun run multiplexer.ts &
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
| `memory` | https://github.com/modelcontextprotocol/servers/tree/main/src/memory | `npm show @modelcontextprotocol/server-memory` |
| `filesystem` | https://github.com/modelcontextprotocol/servers/tree/main/src/filesystem | `npm show @modelcontextprotocol/server-filesystem` |
| `chrome-devtools` | https://github.com/ChromeDevTools/chrome-devtools-mcp | `npm show chrome-devtools-mcp` |

**Things to check on each server update:**
- [ ] URL or package name changed?
- [ ] Transport type changed (http vs sse vs stdio)?
- [ ] New MCP tools added (update AGENTS.md if notable)?
- [ ] Breaking config schema changes?
