import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { Client } from '@modelcontextprotocol/sdk/client/index.js';
import { StdioClientTransport } from '@modelcontextprotocol/sdk/client/stdio.js';
import Database from 'better-sqlite3';

let tempRoot: string;
let tempHome: string;
let dbPath: string;

function createStandaloneDb(targetPath: string) {
  fs.mkdirSync(path.dirname(targetPath), { recursive: true });
  const db = new Database(targetPath);

  db.exec(`
    CREATE TABLE nodes (
      id INTEGER PRIMARY KEY,
      title TEXT,
      description TEXT,
      source TEXT,
      link TEXT,
      event_date TEXT,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
      metadata TEXT,
      embedding BLOB,
      embedding_updated_at TEXT,
      embedding_text TEXT,
      chunk_status TEXT DEFAULT 'not_chunked'
    );

    CREATE TABLE edges (
      id INTEGER PRIMARY KEY,
      from_node_id INTEGER NOT NULL,
      to_node_id INTEGER NOT NULL,
      source TEXT,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      context TEXT,
      explanation TEXT
    );

    CREATE TABLE chunks (
      id INTEGER PRIMARY KEY,
      node_id INTEGER NOT NULL,
      chunk_idx INTEGER NOT NULL,
      text TEXT NOT NULL,
      embedding_type TEXT,
      metadata TEXT,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP
    );
  `);

  const now = new Date().toISOString();
  const insertNode = db.prepare(`
    INSERT INTO nodes (id, title, description, source, link, event_date, created_at, updated_at, metadata, chunk_status)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);

  insertNode.run(
    1,
    'Standalone Test Node',
    'This is a standalone MCP test node used for retrieval and orientation.',
    'A concrete source text about building a useful graph of atomic units of context.',
    null,
    null,
    now,
    now,
    JSON.stringify({ captured_by: 'human' }),
    'chunked'
  );

  insertNode.run(
    2,
    'Connected Support Node',
    'A supporting node connected to the main standalone test node.',
    'Related source text for standalone MCP testing.',
    null,
    null,
    now,
    now,
    JSON.stringify({ captured_by: 'human' }),
    'not_chunked'
  );

  db.prepare(`
    INSERT INTO edges (id, from_node_id, to_node_id, source, created_at, context, explanation)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  `).run(
    1,
    1,
    2,
    'test',
    now,
    JSON.stringify({ explanation: 'Supports the main test node.' }),
    'Supports the main test node.'
  );

  db.prepare(`
    INSERT INTO chunks (id, node_id, chunk_idx, text, embedding_type, metadata, created_at)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  `).run(
    1,
    1,
    0,
    'A concrete source text about building a useful graph of atomic units of context.',
    'text',
    JSON.stringify({}),
    now
  );

  db.close();
}

async function withStandaloneClient<T>(fn: (client: Client) => Promise<T>) {
  const transport = new StdioClientTransport({
    command: process.execPath,
    args: [path.join(process.cwd(), 'apps', 'mcp-server-standalone', 'index.js')],
    cwd: process.cwd(),
    env: {
      ...process.env,
      HOME: tempHome,
      RAH_DB_PATH: dbPath,
    } as Record<string, string>,
    stderr: 'pipe',
  });

  const client = new Client({ name: 'ra-h-standalone-contract-test', version: '1.0.0' });
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

beforeAll(() => {
  tempRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'rah-standalone-test-'));
  tempHome = path.join(tempRoot, 'home');
  dbPath = path.join(tempHome, 'Library', 'Application Support', 'RA-H', 'db', 'rah.sqlite');
});

beforeEach(() => {
  fs.rmSync(tempHome, { recursive: true, force: true });
  createStandaloneDb(dbPath);
});

afterAll(() => {
  fs.rmSync(tempRoot, { recursive: true, force: true });
});

describe('standalone MCP server contract', () => {
  it('returns orientation data with skills and no guides leakage', async () => {
    await withStandaloneClient(async (client) => {
      const result = await client.callTool({
        name: 'getContext',
        arguments: {},
      });

      const structured = getStructured<{
        stats: { nodeCount: number; edgeCount: number };
        hubNodes: Array<{ title: string }>;
        skills: Array<{ name: string }>;
      }>(result);

      expect(structured.stats.nodeCount).toBe(2);
      expect(structured.skills).toEqual(expect.arrayContaining([
        expect.objectContaining({ name: 'Onboarding' }),
        expect.objectContaining({ name: 'Create Skill' }),
        expect.objectContaining({ name: 'Refine' }),
      ]));
      expect(structured).not.toHaveProperty('guides');
    });
  });

  it('supports direct lookup and broader retrieval in standalone MCP', async () => {
    await withStandaloneClient(async (client) => {
      const queryResult = await client.callTool({
        name: 'queryNodes',
        arguments: {
          query: 'Standalone Test Node',
        },
      });

      const queryStructured = getStructured<{ count: number; nodes: Array<{ id: number; title: string }> }>(queryResult);
      expect(queryStructured.count).toBeGreaterThan(0);
      expect(queryStructured.nodes[0]?.title).toBe('Standalone Test Node');

      const retrievalResult = await client.callTool({
        name: 'retrieveQueryContext',
        arguments: {
          query: 'help me think about atomic units of context',
          focused_node_id: 1,
        },
      });

      const retrievalStructured = getStructured<{ focused_node_id: number | null; nodes: Array<{ id: number }> }>(retrievalResult);
      expect(retrievalStructured.focused_node_id).toBe(1);
      expect(retrievalStructured.nodes.some((node) => node.id === 1)).toBe(true);
    });
  });

  it('lists, reads, writes, and deletes shared skills through standalone MCP', async () => {
    await withStandaloneClient(async (client) => {
      const listResult = await client.callTool({
        name: 'listSkills',
        arguments: {},
      });
      const listed = getStructured<{ count: number; skills: Array<{ name: string }> }>(listResult);
      expect(listed.count).toBe(3);
      expect(listed.skills).toEqual(expect.arrayContaining([
        expect.objectContaining({ name: 'Onboarding' }),
        expect.objectContaining({ name: 'Create Skill' }),
        expect.objectContaining({ name: 'Refine' }),
      ]));

      const readResult = await client.callTool({
        name: 'readSkill',
        arguments: { name: 'refine' },
      });
      const readStructured = getStructured<{ name: string; content: string }>(readResult);
      expect(readStructured.name).toBe('Refine');
      expect(readStructured.content).toContain('# Refine');

      await client.callTool({
        name: 'writeSkill',
        arguments: {
          name: 'capture-source',
          content: '---\nname: Capture Source\ndescription: Preserve source carefully.\n---\n\n# Capture Source\n',
        },
      });

      const afterWrite = await client.callTool({
        name: 'listSkills',
        arguments: {},
      });
      const afterWriteStructured = getStructured<{ skills: Array<{ name: string }> }>(afterWrite);
      expect(afterWriteStructured.skills).toEqual(expect.arrayContaining([
        expect.objectContaining({ name: 'Capture Source' }),
      ]));

      await client.callTool({
        name: 'deleteSkill',
        arguments: { name: 'capture-source' },
      });

      const afterDelete = await client.callTool({
        name: 'listSkills',
        arguments: {},
      });
      const afterDeleteStructured = getStructured<{ skills: Array<{ name: string }> }>(afterDelete);
      expect(afterDeleteStructured.skills.some((skill) => skill.name === 'Capture Source')).toBe(false);
    });
  });
});
