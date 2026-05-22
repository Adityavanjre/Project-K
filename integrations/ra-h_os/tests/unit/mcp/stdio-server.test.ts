import http from 'node:http';
import path from 'node:path';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import type { AddressInfo } from 'node:net';
import { Client } from '@modelcontextprotocol/sdk/client/index.js';
import { StdioClientTransport } from '@modelcontextprotocol/sdk/client/stdio.js';

type NodeRecord = {
  id: number;
  title: string;
  description: string | null;
  source: string | null;
  link: string | null;
  metadata: Record<string, unknown>;
  updated_at: string;
  created_at: string;
  edge_count: number;
};

type RequestLogEntry = {
  method: string;
  pathname: string;
  body: Record<string, unknown> | null;
};

let server: http.Server;
let baseUrl = '';
let nodes: NodeRecord[] = [];
let skills: Array<{ name: string; description: string; immutable?: boolean; content?: string }> = [];
let requestLog: RequestLogEntry[] = [];
let nextNodeId = 1;

function nowIso(): string {
  return new Date().toISOString();
}

function resetState() {
  nodes = [];
  skills = [
    { name: 'onboarding', description: 'Initial setup guidance.', immutable: false, content: '# onboarding\n' },
    { name: 'create-skill', description: 'Create or rewrite a reusable skill.', immutable: false, content: '# create-skill\n' },
    { name: 'refine', description: 'Refine a node or small set of nodes.', immutable: false, content: '# refine\n' },
  ];
  requestLog = [];
  nextNodeId = 1;
}

function sendJson(res: http.ServerResponse, statusCode: number, body: unknown) {
  res.writeHead(statusCode, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(body));
}

async function readJsonBody(req: http.IncomingMessage): Promise<Record<string, unknown>> {
  const chunks: Buffer[] = [];
  for await (const chunk of req) {
    chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
  }
  const raw = Buffer.concat(chunks).toString('utf8');
  return raw ? JSON.parse(raw) : {};
}

function matchesNode(node: NodeRecord, query: string) {
  const haystack = [node.title, node.description, node.source, node.link]
    .filter(Boolean)
    .join(' ')
    .toLowerCase();
  return haystack.includes(query.toLowerCase());
}

async function handleRequest(req: http.IncomingMessage, res: http.ServerResponse) {
  const url = new URL(req.url || '/', baseUrl);
  const pathname = url.pathname;
  const method = req.method || 'GET';
  const body = method === 'POST' || method === 'PUT' ? await readJsonBody(req) : null;

  requestLog.push({ method, pathname, body });

  if (method === 'POST' && pathname === '/api/nodes') {
    const timestamp = nowIso();
    const node: NodeRecord = {
      id: nextNodeId++,
      title: String(body?.title || '').trim(),
      description: typeof body?.description === 'string' ? body.description : null,
      source: typeof body?.source === 'string' ? body.source : null,
      link: typeof body?.link === 'string' ? body.link : null,
      metadata: typeof body?.metadata === 'object' && body.metadata ? body.metadata as Record<string, unknown> : {},
      updated_at: timestamp,
      created_at: timestamp,
      edge_count: 0,
    };
    nodes.unshift(node);
    return sendJson(res, 200, { success: true, data: node, message: `Created node #${node.id}: ${node.title}` });
  }

  if (method === 'GET' && pathname === '/api/nodes') {
    const search = url.searchParams.get('search')?.trim() || '';
    const limit = Number(url.searchParams.get('limit') || '10');
    const sortBy = url.searchParams.get('sortBy');

    let filtered = nodes.slice();
    if (search) {
      filtered = filtered.filter((node) => matchesNode(node, search));
    }
    if (sortBy === 'edges') {
      filtered.sort((a, b) => b.edge_count - a.edge_count || b.updated_at.localeCompare(a.updated_at));
    }

    return sendJson(res, 200, {
      success: true,
      total: filtered.length,
      count: filtered.length,
      data: filtered.slice(0, Number.isFinite(limit) ? limit : 10),
    });
  }

  if (method === 'GET' && pathname.startsWith('/api/nodes/')) {
    const id = Number(pathname.split('/').pop());
    const node = nodes.find((entry) => entry.id === id);
    if (!node) {
      return sendJson(res, 404, { success: false, error: 'Node not found.' });
    }
    return sendJson(res, 200, { success: true, node });
  }

  if (method === 'POST' && pathname === '/api/nodes/direct-search') {
    const query = typeof body?.query === 'string' ? body.query : '';
    const limit = typeof body?.limit === 'number' ? body.limit : 10;
    const filtered = nodes.filter((node) => matchesNode(node, query)).slice(0, limit);
    return sendJson(res, 200, {
      success: true,
      data: {
        count: filtered.length,
        nodes: filtered,
        filters_applied: {
          search: query,
          limit,
          createdAfter: body?.createdAfter ?? undefined,
          createdBefore: body?.createdBefore ?? undefined,
          eventAfter: body?.eventAfter ?? undefined,
          eventBefore: body?.eventBefore ?? undefined,
        },
      },
    });
  }

  if (method === 'POST' && pathname === '/api/retrieval/query-context') {
    return sendJson(res, 200, {
      success: true,
      data: {
        query: typeof body?.query === 'string' ? body.query : '',
        shouldRetrieve: true,
        mode: 'query',
        reason: 'Retrieved graph context.',
        focused_node_id: typeof body?.focused_node_id === 'number' ? body.focused_node_id : null,
        nodes: nodes.slice(0, 1).map((node) => ({
          id: node.id,
          title: node.title,
          description: node.description,
          link: node.link,
          updated_at: node.updated_at,
          kind: 'query_match',
          reason: 'Matched the query through direct graph search.',
        })),
        chunks: [],
      },
    });
  }

  if (method === 'GET' && pathname === '/api/edges') {
    return sendJson(res, 200, {
      success: true,
      count: 3,
      data: [],
    });
  }

  if (method === 'GET' && pathname === '/api/skills') {
    return sendJson(res, 200, {
      success: true,
      data: skills.map(({ content, ...skill }) => skill),
    });
  }

  if (method === 'POST' && pathname === '/api/skills') {
    const name = typeof body?.name === 'string' ? body.name : '';
    const content = typeof body?.content === 'string' ? body.content : '';
    const existing = skills.find((skill) => skill.name === name);

    if (existing) {
      existing.content = content;
    } else {
      skills.push({ name, description: '', immutable: false, content });
    }

    return sendJson(res, 200, {
      success: true,
      message: `Skill "${name}" saved`,
    });
  }

  if (method === 'GET' && pathname.startsWith('/api/skills/')) {
    const name = decodeURIComponent(pathname.split('/').pop() || '');
    const skill = skills.find((entry) => entry.name === name);
    if (!skill) {
      return sendJson(res, 404, { success: false, error: 'Skill not found.' });
    }
    return sendJson(res, 200, {
      success: true,
      data: {
        name: skill.name,
        description: skill.description,
        immutable: !!skill.immutable,
        content: skill.content || '',
      },
    });
  }

  if (method === 'DELETE' && pathname.startsWith('/api/skills/')) {
    const name = decodeURIComponent(pathname.split('/').pop() || '');
    skills = skills.filter((entry) => entry.name !== name);
    return sendJson(res, 200, {
      success: true,
      message: `Skill "${name}" deleted`,
    });
  }

  return sendJson(res, 404, { success: false, error: `Unhandled test route: ${method} ${pathname}` });
}

async function withMcpClient<T>(fn: (client: Client) => Promise<T>) {
  const transport = new StdioClientTransport({
    command: process.execPath,
    args: [path.join(process.cwd(), 'apps', 'mcp-server', 'stdio-server.js')],
    cwd: process.cwd(),
    env: {
      ...process.env,
      RAH_MCP_TARGET_URL: baseUrl,
    } as Record<string, string>,
    stderr: 'pipe',
  });

  const client = new Client({ name: 'ra-h-mcp-contract-test', version: '1.0.0' });
  await client.connect(transport);

  try {
    return await fn(client);
  } finally {
    await transport.close();
  }
}

function getStructured<T>(result: unknown) {
  return (result as { structuredContent?: unknown }).structuredContent as T;
}

describe('stdio MCP server contract', () => {
  beforeAll(async () => {
    server = http.createServer((req, res) => {
      void handleRequest(req, res);
    });

    await new Promise<void>((resolve) => {
      server.listen(0, '127.0.0.1', () => resolve());
    });

    const address = server.address() as AddressInfo;
    baseUrl = `http://127.0.0.1:${address.port}`;
  });

  afterAll(async () => {
    await new Promise<void>((resolve, reject) => {
      server.close((error) => (error ? reject(error) : resolve()));
    });
  });

  beforeEach(() => {
    resetState();
  });

  it('does not expose removed context tools or fields in the MCP registry', async () => {
    await withMcpClient(async (client) => {
      const result = await client.listTools();
      const toolNames = result.tools.map((tool) => tool.name);

      expect(toolNames).not.toEqual(expect.arrayContaining([
        'rah_query_contexts',
        'rah_write_context',
      ]));

      const addNodeTool = result.tools.find((tool) => tool.name === 'rah_add_node');
      expect(addNodeTool).toBeDefined();
      expect(JSON.stringify(addNodeTool?.inputSchema)).not.toContain('context_name');
      expect(JSON.stringify(addNodeTool?.inputSchema)).not.toContain('context_id');

      const retrieveTool = result.tools.find((tool) => tool.name === 'rah_retrieve_query_context');
      expect(retrieveTool).toBeDefined();
      expect(JSON.stringify(retrieveTool?.inputSchema)).not.toContain('active_context_id');
    });
  });

  it('creates and searches nodes through MCP without context-era payloads', async () => {
    await withMcpClient(async (client) => {
      const result = await client.callTool({
        name: 'rah_add_node',
        arguments: {
          title: 'MCP Contract Test Node',
          description: 'Node created through MCP to verify the no-context write contract.',
          source: 'Concrete source text proving rah_add_node works without context fields.',
          metadata: { source: 'mcp-contract-test' },
        },
      });

      const structured = getStructured<{ nodeId: number; title: string }>(result);
      expect(structured.nodeId).toBeGreaterThan(0);
      expect(structured.title).toBe('MCP Contract Test Node');

      const createRequest = requestLog.find((entry) => entry.method === 'POST' && entry.pathname === '/api/nodes');
      expect(createRequest?.body).toMatchObject({
        title: 'MCP Contract Test Node',
        description: 'Node created through MCP to verify the no-context write contract.',
        source: 'Concrete source text proving rah_add_node works without context fields.',
        metadata: { source: 'mcp-contract-test' },
      });
      expect(createRequest?.body).not.toHaveProperty('context_name');
      expect(createRequest?.body).not.toHaveProperty('context_id');

      const searchResult = await client.callTool({
        name: 'rah_search_nodes',
        arguments: {
          query: 'contract test node',
          limit: 5,
          createdAfter: '2026-01-01',
        },
      });

      const searchStructured = getStructured<{ count: number; nodes: Array<Record<string, unknown>> }>(searchResult);
      expect(searchStructured.count).toBe(1);
      expect(searchStructured.nodes[0]).toMatchObject({
        id: structured.nodeId,
        title: 'MCP Contract Test Node',
      });

      const searchRequest = requestLog.find((entry) => entry.method === 'POST' && entry.pathname === '/api/nodes/direct-search');
      expect(searchRequest?.body).toMatchObject({
        query: 'contract test node',
        limit: 5,
        createdAfter: '2026-01-01',
      });
      expect(searchRequest?.body).not.toHaveProperty('context_name');
      expect(searchStructured.nodes[0]).not.toHaveProperty('context_id');
    });
  });

  it('returns orientation data without contexts and retrieval payloads without active context ids', async () => {
    nodes.push({
      id: nextNodeId++,
      title: 'Work Hub Node',
      description: 'High-signal work hub used to verify MCP context orientation.',
      source: 'Hub node source',
      link: null,
      metadata: {},
      updated_at: nowIso(),
      created_at: nowIso(),
      edge_count: 7,
    });

    await withMcpClient(async (client) => {
      const retrievalResult = await client.callTool({
        name: 'rah_retrieve_query_context',
        arguments: {
          query: 'help me think about work hub priorities',
          focused_node_id: 1,
        },
      });

      const retrievalRequest = requestLog.find((entry) => entry.method === 'POST' && entry.pathname === '/api/retrieval/query-context');
      expect(retrievalRequest?.body).toMatchObject({
        query: 'help me think about work hub priorities',
        focused_node_id: 1,
      });
      expect(retrievalRequest?.body).not.toHaveProperty('active_context_id');

      const retrievalStructured = getStructured<{ focused_node_id: number | null; nodes: Array<{ title: string }> }>(retrievalResult);
      expect(retrievalStructured.focused_node_id).toBe(1);
      expect(retrievalStructured.nodes[0]?.title).toBe('Work Hub Node');

      const graphContextResult = await client.callTool({
        name: 'rah_get_context',
        arguments: {},
      });

      const graphStructured = getStructured<{
        stats: { nodeCount: number; edgeCount: number };
        hubNodes: Array<{ title: string }>;
        skills: Array<{ name: string }>;
      }>(graphContextResult);

      expect(graphStructured.stats).toEqual({ nodeCount: 1, edgeCount: 3 });
      expect(graphStructured.hubNodes).toEqual(
        expect.arrayContaining([expect.objectContaining({ title: 'Work Hub Node' })])
      );
      expect(graphStructured.skills).toEqual(expect.arrayContaining([
        expect.objectContaining({ name: 'onboarding' }),
        expect.objectContaining({ name: 'create-skill' }),
        expect.objectContaining({ name: 'refine' }),
      ]));
      expect(graphStructured).not.toHaveProperty('contexts');
      expect(graphStructured.stats).not.toHaveProperty('contextCount');
    });
  });

  it('lists, reads, writes, and deletes shared skills through packaged MCP', async () => {
    await withMcpClient(async (client) => {
      const listResult = await client.callTool({
        name: 'rah_list_skills',
        arguments: {},
      });
      const listed = getStructured<{ count: number; skills: Array<{ name: string }> }>(listResult);
      expect(listed.count).toBe(3);
      expect(listed.skills).toEqual(expect.arrayContaining([
        expect.objectContaining({ name: 'onboarding' }),
        expect.objectContaining({ name: 'create-skill' }),
        expect.objectContaining({ name: 'refine' }),
      ]));

      const readResult = await client.callTool({
        name: 'rah_read_skill',
        arguments: { name: 'refine' },
      });
      const readStructured = getStructured<{ name: string; content: string }>(readResult);
      expect(readStructured.name).toBe('refine');
      expect(readStructured.content).toContain('# refine');

      await client.callTool({
        name: 'rah_write_skill',
        arguments: {
          name: 'capture',
          content: '---\nname: capture\ndescription: Capture guidance\n---\n\nCapture skill body.',
        },
      });

      const writeRequest = requestLog.find((entry) => entry.method === 'POST' && entry.pathname === '/api/skills');
      expect(writeRequest?.body).toMatchObject({
        name: 'capture',
      });

      const afterWrite = await client.callTool({
        name: 'rah_list_skills',
        arguments: {},
      });
      const afterWriteStructured = getStructured<{ skills: Array<{ name: string }> }>(afterWrite);
      expect(afterWriteStructured.skills).toEqual(expect.arrayContaining([
        expect.objectContaining({ name: 'capture' }),
      ]));

      await client.callTool({
        name: 'rah_delete_skill',
        arguments: { name: 'capture' },
      });

      const deleteRequest = requestLog.find((entry) => entry.method === 'DELETE' && entry.pathname === '/api/skills/capture');
      expect(deleteRequest).toBeDefined();
    });
  });
});
