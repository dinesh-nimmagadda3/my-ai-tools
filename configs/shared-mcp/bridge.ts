import { StreamableHTTPClientTransport } from "@modelcontextprotocol/sdk/client/streamableHttp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import {
  ListToolsRequestSchema,
  CallToolRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";

const HUB_URL = process.env.HUB_URL || "http://localhost:5115/hub";

function isReconnectableError(error: unknown): boolean {
  const message = error instanceof Error ? error.message : String(error);
  return (
    message.includes("Invalid session") ||
    message.includes("initialization required") ||
    message.includes("Connection closed") ||
    message.includes("fetch failed") ||
    message.includes("ECONNREFUSED")
  );
}

class HubConnection {
  private hubClient?: Client;
  private reconnecting?: Promise<Client>;

  async connect(): Promise<Client> {
    if (this.hubClient) {
      return this.hubClient;
    }

    return this.reconnect();
  }

  async reconnect(): Promise<Client> {
    if (this.reconnecting) {
      return this.reconnecting;
    }

    this.reconnecting = this.createConnection().finally(() => {
      this.reconnecting = undefined;
    });

    return this.reconnecting;
  }

  async request<T>(operation: (hubClient: Client) => Promise<T>): Promise<T> {
    try {
      return await operation(await this.connect());
    } catch (error) {
      if (!isReconnectableError(error)) {
        throw error;
      }

      console.error(`[Bridge] Hub connection stale; reconnecting to ${HUB_URL}`);
      return await operation(await this.reconnect());
    }
  }

  private async createConnection(): Promise<Client> {
    const oldClient = this.hubClient;
    this.hubClient = undefined;

    if (oldClient) {
      await oldClient.close().catch(() => undefined);
    }

    const clientTransport = new StreamableHTTPClientTransport(new URL(HUB_URL));
    const hubClient = new Client({
      name: "mcp-bridge-client",
      version: "5.0.0",
    }, {
      capabilities: {}
    });

    await hubClient.connect(clientTransport);
    this.hubClient = hubClient;
    return hubClient;
  }
}

async function runBridge() {
  const hubConnection = new HubConnection();
  await hubConnection.connect();

  const bridgeServer = new McpServer({
    name: "mcp-bridge-server",
    version: "5.0.0",
  }, {
    capabilities: {
      tools: {},
      resources: {},
    }
  });

  bridgeServer.server.setRequestHandler(ListToolsRequestSchema, async () => {
    return await hubConnection.request((hubClient) => hubClient.listTools());
  });

  bridgeServer.server.setRequestHandler(CallToolRequestSchema, async (request) => {
    return await hubConnection.request((hubClient) => hubClient.callTool(request.params));
  });

  const serverTransport = new StdioServerTransport();
  await bridgeServer.connect(serverTransport);
}

runBridge().catch(console.error);
