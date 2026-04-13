import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
import { SSEClientTransport } from "@modelcontextprotocol/sdk/client/sse.js";
import { SSEServerTransport } from "@modelcontextprotocol/sdk/server/sse.js";
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import {
  ListToolsRequestSchema,
  CallToolRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import express, { Request, Response } from "express";
import fs from "node:fs";
import { pino } from "pino";

const logger = pino({
  transport: {
    target: "pino-pretty",
    options: { colorize: true }
  }
});

const REGISTRY_PATH = "./server-registry.json";
const PORT = process.env.PORT || 5115;

interface McpBackend {
  client: Client;
  config: any;
  status: "connected" | "error";
}

class McpHubV3 {
  private backends: Record<string, McpBackend> = {};
  private server: Server;
  private app: express.Express;
  private sseTransport?: SSEServerTransport;

  constructor() {
    this.server = new Server({
      name: "shared-mcp-hub",
      version: "3.0.0",
    }, {
      capabilities: { tools: {}, resources: {}, prompts: {} }
    });

    this.app = express();
    this.app.use(express.json());
    this.setupRoutes();
  }

  private setupRoutes() {
    // Spec-compliant SSE
    this.app.get("/sse", async (_req: Request, res: Response) => {
      logger.info("[Hub] New client connection arriving at /sse");
      this.sseTransport = new SSEServerTransport("/messages", res);
      await this.server.connect(this.sseTransport);
    });

    this.app.post("/messages", async (req: Request, res: Response) => {
      if (this.sseTransport) {
        await this.sseTransport.handlePostMessage(req, res);
      } else {
        res.status(400).send("No active session");
      }
    });

    // V3: Dynamic Registration
    this.app.post("/register", async (req: Request, res: Response) => {
      const { name, config } = req.body;
      logger.info(`[Hub] Dynamic registration request for: ${name}`);
      try {
        await this.connectBackend(name, config);
        // Optionally persist to registry
        res.status(200).json({ status: "ok", message: `Server ${name} registered` });
      } catch (err) {
        res.status(500).json({ status: "error", message: String(err) });
      }
    });

    // V3: Health Dashboard
    this.app.get("/status", (_req: Request, res: Response) => {
      const status = Object.entries(this.backends).map(([name, data]) => ({
        name,
        status: data.status,
        type: data.config.type,
        command: data.config.command || data.config.url
      }));
      res.json({
        hub: "ACTIVE",
        version: "3.0.0",
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
    } else if (config.type === "sse") {
      transport = new SSEClientTransport(new URL(config.url));
    }

    if (transport) {
      const client = new Client({ name: "hub-proxy", version: "1.0.0" }, { capabilities: {} });
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
      logger.info(`[Hub] Shared MCP Multiplexer listening on port ${PORT}`);
      logger.info(`[Hub] Health Dashboard: http://localhost:${PORT}/status`);
    });
  }
}

const hub = new McpHubV3();
hub.start().catch((err: Error) => logger.error(err));

// Graceful exit
process.on("SIGTERM", () => {
  logger.info("[Hub] SIGTERM received. Closing hub...");
  // TODO: Close all backend transports
  process.exit(0);
});
