import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
import { StreamableHTTPClientTransport } from "@modelcontextprotocol/sdk/client/streamableHttp.js";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import { createMcpExpressApp } from "@modelcontextprotocol/sdk/server/express.js";
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import {
  ListToolsRequestSchema,
  CallToolRequestSchema,
  isInitializeRequest,
} from "@modelcontextprotocol/sdk/types.js";
import { Request, Response } from "express";
import fs from "node:fs";
import { pino } from "pino";
import { randomUUID } from "node:crypto";

const logger = pino({
  transport: {
    target: "pino-pretty",
    options: { colorize: true }
  }
});

const REGISTRY_PATH = "./server-registry.json";
const PORT = Number(process.env.PORT) || 5115;

interface McpBackend {
  client: Client;
  config: any;
  status: "connected" | "error";
}

class McpHubV4 {
  private backends: Record<string, McpBackend> = {};
  private server: Server;
  private app: any; 
  private transports: Map<string, StreamableHTTPServerTransport> = new Map();

  constructor() {
    this.server = new Server({
      name: "shared-mcp-hub",
      version: "4.0.0",
    }, {
      capabilities: { tools: {}, resources: {}, prompts: {} }
    });

    this.app = createMcpExpressApp();
    this.setupRoutes();
  }

  private setupRoutes() {
    // Unified V4 Hub Endpoint: POST (messages), GET (stream), DELETE (terminate)
    const hubHandler = async (req: Request, res: Response) => {
      const sessionId = req.headers["mcp-session-id"] as string;

      try {
        let transport: StreamableHTTPServerTransport | undefined;

        if (sessionId && this.transports.has(sessionId)) {
          transport = this.transports.get(sessionId);
        } else if (!sessionId && req.method === "POST" && isInitializeRequest(req.body)) {
          // New Session Initialization
          logger.info("[Hub] Initializing new Hub session");
          transport = new StreamableHTTPServerTransport({
            sessionIdGenerator: () => randomUUID(),
            onsessioninitialized: (sid) => {
              logger.info(`[Hub] Session initialized: ${sid}`);
              if (transport) this.transports.set(sid, transport);
            }
          });

          transport.onclose = () => {
            if (transport?.sessionId) {
              logger.info(`[Hub] Session closed: ${transport.sessionId}`);
              this.transports.delete(transport.sessionId);
            }
          };

          await this.server.connect(transport);
          await transport.handleRequest(req, res, req.body);
          return;
        }

        if (transport) {
          await transport.handleRequest(req, res, req.body);
        } else {
          res.status(400).json({
            jsonrpc: "2.0",
            error: { code: -32000, message: "Invalid session or initialization required" },
            id: null
          });
        }
      } catch (err) {
        logger.error(`[Hub] Transport error: ${err}`);
        if (!res.headersSent) res.status(500).send("Internal Hub Error");
      }
    };

    this.app.all("/hub", hubHandler);

    // V3: Dynamic Registration (kept for flexibility)
    this.app.post("/register", async (req: Request, res: Response) => {
      const { name, config } = req.body;
      logger.info(`[Hub] Dynamic registration request for: ${name}`);
      try {
        await this.connectBackend(name, config);
        res.status(200).json({ status: "ok", message: `Server ${name} registered` });
      } catch (err) {
        res.status(500).json({ status: "error", message: String(err) });
      }
    });

    // V4: Health & Status Dashboard
    this.app.get("/status", (_req: Request, res: Response) => {
      const status = Object.entries(this.backends).map(([name, data]) => ({
        name,
        status: data.status,
        type: data.config.type,
        command: data.config.command || data.config.url
      }));
      res.json({
        hub: "ACTIVE",
        version: "4.0.0",
        protocol: "Streamable HTTP",
        activeSessions: this.transports.size,
        backends: status,
        uptime: process.uptime()
      });
    });
  }

  private async connectBackend(name: string, config: any) {
    logger.info(`[Hub] Connecting to backend: ${name} (${config.type})`);
    let transport;
    if (config.type === "stdio") {
      transport = new StdioClientTransport({
        command: config.command,
        args: config.args,
        env: { ...process.env, ...config.env }
      });
    } else if (config.type === "sse" || config.type === "http") {
      // Use modern transport if it's likely a new server, fallback to SSE patterns if it ends in /sse
      if (config.url.endsWith("/sse")) {
         // This is technically deprecated but kept until backends migrate
         const { SSEClientTransport } = await import("@modelcontextprotocol/sdk/client/sse.js");
         transport = new SSEClientTransport(new URL(config.url));
      } else {
         transport = new StreamableHTTPClientTransport(new URL(config.url));
      }
    }

    if (transport) {
      const client = new Client({ name: "hub-proxy", version: "4.0.0" }, { capabilities: {} });
      await client.connect(transport);
      this.backends[name] = { client, config, status: "connected" };
      logger.info(`[Hub] Successfully aggregated backend: ${name}`);
    }
  }

  async start() {
    // 1. Load initial registry
    if (fs.existsSync(REGISTRY_PATH)) {
      const registry = JSON.parse(fs.readFileSync(REGISTRY_PATH, "utf-8"));
      for (const [name, config] of Object.entries(registry.mcpServers || {})) {
        if ((config as any).enabled) {
          await this.connectBackend(name, config).catch(e => logger.error(`Init failed for ${name}: ${e}`));
        }
      }
    }

    // 2. Setup standard request handlers
    this.server.setRequestHandler(ListToolsRequestSchema, async () => {
      const allTools = [];
      for (const [name, data] of Object.entries(this.backends)) {
        try {
          const resp = await data.client.listTools();
          allTools.push(...resp.tools);
        } catch (e) { logger.warn(`[Hub] Tool listing failed for ${name}`); }
      }
      return { tools: allTools };
    });

    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;
      for (const data of Object.values(this.backends)) {
        try {
          const { tools } = await data.client.listTools();
          if (tools.some((t: any) => t.name === name)) {
            return await data.client.callTool({ name, arguments: args });
          }
        } catch (e) { continue; }
      }
      throw new Error(`Tool ${name} not found across connected backends`);
    });

    // 3. Start listening
    this.app.listen(PORT, () => {
      logger.info(`[Hub] Shared MCP Multiplexer V4 listening on port ${PORT}`);
      logger.info(`[Hub] Endpoint: http://localhost:${PORT}/hub`);
      logger.info(`[Hub] Health Dashboard: http://localhost:${PORT}/status`);
    });
  }
}

const hub = new McpHubV4();
hub.start().catch((err: Error) => logger.error(err));

// Graceful exit
process.on("SIGTERM", () => {
  logger.info("[Hub] SIGTERM received. Closing hub...");
  process.exit(0);
});

