import { StreamableHTTPClientTransport } from "@modelcontextprotocol/sdk/client/streamableHttp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import {
  ListToolsRequestSchema,
  CallToolRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";

const HUB_URL = process.env.HUB_URL || "http://localhost:5115/hub";

async function runBridge() {
  const clientTransport = new StreamableHTTPClientTransport(new URL(HUB_URL));
  const hubClient = new Client({
    name: "mcp-bridge-client",
    version: "4.0.0",
  }, {
    capabilities: {}
  });

  await hubClient.connect(clientTransport);

  const bridgeServer = new Server({
    name: "mcp-bridge-server",
    version: "4.0.0",
  }, {
    capabilities: {
      tools: {},
      resources: {},
    }
  });

  bridgeServer.setRequestHandler(ListToolsRequestSchema, async () => {
    return await hubClient.listTools();
  });

  bridgeServer.setRequestHandler(CallToolRequestSchema, async (request) => {
    return await hubClient.callTool(request.params);
  });

  const serverTransport = new StdioServerTransport();
  await bridgeServer.connect(serverTransport);
}

runBridge().catch(console.error);
