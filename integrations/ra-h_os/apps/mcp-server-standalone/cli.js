#!/usr/bin/env node
'use strict';

const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const Database = require('better-sqlite3');
const packageJson = require('./package.json');
const { getDatabasePath } = require('./services/sqlite-client');

const SUPPORTED_CLIENTS = new Set([
  'claude-code',
  'claude-desktop',
  'cursor',
  'codex',
  'opencode',
  'vscode',
  'windsurf',
  'aider',
]);

function log(message) {
  console.log(`[ra-h-mcp-server] ${message}`);
}

function fail(message) {
  console.error(`[ra-h-mcp-server] ERROR: ${message}`);
  process.exit(1);
}

function usage() {
  console.log(`RA-H MCP Server ${packageJson.version}

Usage:
  ra-h-mcp-server                         Start MCP stdio server
  ra-h-mcp-server setup --client <name>   Configure MCP for one or more agents
  ra-h-mcp-server doctor                  Verify package, DB, and schema
  ra-h-mcp-server init-db                 Create/verify the RA-H SQLite DB
  ra-h-mcp-server print-config --client <name>
  ra-h-mcp-server install-rules --client <name> [--target <path>]

Options:
  --client <name[,name]> claude-code, claude-desktop, cursor, codex, opencode, vscode, windsurf, aider
  --db <path>            Override DB path for this command
  --scope <scope>        user or project (default: user)
  --pin current          Use this package version instead of @latest in generated config
  --yes                  Write supported config files without prompting
  --install-rules        Also install RA-H graph behavior into each client's repo memory file
  --print-only           Print config/rules without writing files
  --target <path>        Directory for project rule files
`);
}

function parseArgs(argv) {
  const args = {
    _: [],
    client: null,
    db: null,
    scope: 'user',
    pin: null,
    yes: false,
    installRules: false,
    printOnly: false,
    target: null,
  };

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === '--help' || arg === '-h') {
      args.help = true;
    } else if (arg === '--yes' || arg === '-y') {
      args.yes = true;
    } else if (arg === '--install-rules' || arg === '--rules') {
      args.installRules = true;
    } else if (arg === '--print-only' || arg === '--dry-run') {
      args.printOnly = true;
    } else if (['--client', '--clients', '--db', '--scope', '--pin', '--target'].includes(arg)) {
      const value = argv[i + 1];
      if (!value || value.startsWith('--')) fail(`${arg} requires a value`);
      args[arg === '--clients' ? 'client' : arg.slice(2)] = value;
      i += 1;
    } else {
      args._.push(arg);
    }
  }

  return args;
}

function expandPath(rawPath) {
  if (!rawPath) return rawPath;
  let expanded = rawPath;
  if (expanded.startsWith('~')) {
    expanded = path.join(os.homedir(), expanded.slice(1));
  }
  expanded = expanded.replace(/\$HOME/g, os.homedir());
  return path.resolve(expanded);
}

function defaultDbPath() {
  return getDatabasePath();
}

function resolveDbPath(args) {
  return expandPath(args.db || process.env.RAH_DB_PATH || process.env.SQLITE_DB_PATH || defaultDbPath());
}

function ensureMinimumSchema(db) {
  db.pragma('foreign_keys = ON');
  db.exec(`
    CREATE TABLE IF NOT EXISTS nodes (
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

    CREATE TABLE IF NOT EXISTS chunks (
      id INTEGER PRIMARY KEY,
      node_id INTEGER NOT NULL,
      chunk_idx INTEGER,
      text TEXT,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      embedding_type TEXT DEFAULT 'text-embedding-3-small',
      metadata TEXT,
      FOREIGN KEY (node_id) REFERENCES nodes(id) ON DELETE CASCADE
    );
    CREATE INDEX IF NOT EXISTS idx_chunks_by_node ON chunks(node_id);
    CREATE INDEX IF NOT EXISTS idx_chunks_by_node_idx ON chunks(node_id, chunk_idx);

    CREATE TABLE IF NOT EXISTS edges (
      id INTEGER PRIMARY KEY,
      from_node_id INTEGER NOT NULL,
      to_node_id INTEGER NOT NULL,
      source TEXT,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      context TEXT,
      explanation TEXT,
      FOREIGN KEY (from_node_id) REFERENCES nodes(id) ON DELETE CASCADE,
      FOREIGN KEY (to_node_id) REFERENCES nodes(id) ON DELETE CASCADE
    );
    CREATE INDEX IF NOT EXISTS idx_edges_from ON edges(from_node_id);
    CREATE INDEX IF NOT EXISTS idx_edges_to ON edges(to_node_id);

    CREATE VIRTUAL TABLE IF NOT EXISTS nodes_fts USING fts5(
      title,
      source,
      description,
      content='nodes',
      content_rowid='id'
    );
    CREATE VIRTUAL TABLE IF NOT EXISTS chunks_fts USING fts5(
      text,
      content='chunks',
      content_rowid='id'
    );
  `);
}

function initDb(dbPath) {
  fs.mkdirSync(path.dirname(dbPath), { recursive: true });
  const db = new Database(dbPath);
  try {
    ensureMinimumSchema(db);
    const quickCheck = db.prepare('PRAGMA quick_check').get();
    return quickCheck.quick_check || Object.values(quickCheck)[0];
  } finally {
    db.close();
  }
}

function inspectDb(dbPath) {
  if (!fs.existsSync(dbPath)) {
    return { exists: false, ok: false, missing: ['database file'] };
  }

  const db = new Database(dbPath, { readonly: true, fileMustExist: true });
  try {
    const requiredTables = ['nodes', 'edges', 'chunks'];
    const missing = requiredTables.filter(
      (table) => !db.prepare("SELECT 1 FROM sqlite_master WHERE type='table' AND name = ?").get(table)
    );
    const quickCheck = db.prepare('PRAGMA quick_check').get();
    const nodeCount = missing.includes('nodes')
      ? null
      : db.prepare('SELECT COUNT(*) as count FROM nodes').get().count;

    return {
      exists: true,
      ok: missing.length === 0,
      missing,
      quickCheck: quickCheck.quick_check || Object.values(quickCheck)[0],
      nodeCount,
    };
  } finally {
    db.close();
  }
}

function packageSpec(args) {
  return args.pin === 'current'
    ? `ra-h-mcp-server@${packageJson.version}`
    : 'ra-h-mcp-server@latest';
}

function mcpServerJson(args, dbPath) {
  return {
    command: 'npx',
    args: ['-y', packageSpec(args)],
    env: {
      RAH_DB_PATH: dbPath,
    },
  };
}

function clientConfig(client, args, dbPath) {
  const server = mcpServerJson(args, dbPath);

  if (client === 'claude-code') {
    return {
      type: 'json-merge',
      path: path.join(os.homedir(), '.claude.json'),
      snippet: { mcpServers: { 'ra-h': server } },
      writable: true,
    };
  }

  if (client === 'claude-desktop') {
    return {
      type: 'json-merge',
      path: path.join(os.homedir(), 'Library', 'Application Support', 'Claude', 'claude_desktop_config.json'),
      snippet: { mcpServers: { 'ra-h': server } },
      writable: process.platform === 'darwin',
    };
  }

  if (client === 'cursor') {
    return {
      type: 'json-merge',
      path: path.join(os.homedir(), '.cursor', 'mcp.json'),
      snippet: { mcpServers: { 'ra-h': server } },
      writable: true,
    };
  }

  if (client === 'vscode') {
    return {
      type: 'json-merge',
      path: path.join(process.cwd(), '.vscode', 'mcp.json'),
      snippet: { servers: { 'ra-h': server } },
      writable: args.scope === 'project',
      note: 'VS Code MCP config is project-local here; pass --scope project --yes to write it.',
    };
  }

  if (client === 'codex') {
    return {
      type: 'toml-merge',
      path: path.join(process.env.CODEX_HOME || path.join(os.homedir(), '.codex'), 'config.toml'),
      snippet: `[mcp_servers.ra-h]\ncommand = "npx"\nargs = ["-y", "${packageSpec(args)}"]\n\n[mcp_servers.ra-h.env]\nRAH_DB_PATH = "${dbPath.replace(/\\/g, '\\\\').replace(/"/g, '\\"')}"\n`,
      writable: true,
      note: 'Codex config is TOML; pass --yes to merge this block into the Codex config file.',
    };
  }

  return {
    type: 'json',
    path: null,
    snippet: { mcpServers: { 'ra-h': server } },
    writable: false,
    note: `${client} config writing is not automated yet. Copy this MCP block into that client's MCP settings.`,
  };
}

function readJson(filePath) {
  if (!fs.existsSync(filePath)) return {};
  const raw = fs.readFileSync(filePath, 'utf8').trim();
  if (!raw) return {};
  return JSON.parse(raw);
}

function writeJsonMerge(config) {
  const current = readJson(config.path);
  const next = {
    ...current,
    mcpServers: {
      ...(current.mcpServers || {}),
      ...(config.snippet.mcpServers || {}),
    },
  };

  if (config.snippet.servers) {
    next.servers = {
      ...(current.servers || {}),
      ...config.snippet.servers,
    };
  }

  fs.mkdirSync(path.dirname(config.path), { recursive: true });
  fs.writeFileSync(config.path, `${JSON.stringify(next, null, 2)}\n`);
}

function removeTomlTables(raw, tableNames) {
  const tables = new Set(tableNames);
  const lines = raw.split(/\r?\n/);
  const kept = [];
  let skipping = false;

  for (const line of lines) {
    const match = line.match(/^\s*\[([^\]]+)\]\s*$/);
    if (match) {
      skipping = tables.has(match[1]);
    }
    if (!skipping) kept.push(line);
  }

  return kept.join('\n').trimEnd();
}

function writeTomlMerge(config) {
  const current = fs.existsSync(config.path) ? fs.readFileSync(config.path, 'utf8') : '';
  const withoutRah = removeTomlTables(current, ['mcp_servers.ra-h', 'mcp_servers.ra-h.env']);
  const next = `${withoutRah ? `${withoutRah}\n\n` : ''}${config.snippet.trimEnd()}\n`;

  fs.mkdirSync(path.dirname(config.path), { recursive: true });
  fs.writeFileSync(config.path, next);
}

function formatSnippet(snippet) {
  return typeof snippet === 'string' ? snippet : JSON.stringify(snippet, null, 2);
}

function validateClient(client) {
  if (!SUPPORTED_CLIENTS.has(client)) {
    fail(`Unsupported client "${client}". Supported: ${Array.from(SUPPORTED_CLIENTS).join(', ')}`);
  }
}

function resolveClients(rawClient) {
  if (!rawClient) fail('Missing --client');
  const clients = rawClient
    .split(',')
    .map((client) => client.trim())
    .filter(Boolean);

  if (clients.length === 0) fail('Missing --client');
  clients.forEach(validateClient);
  return [...new Set(clients)];
}

function rulesSnippet() {
  return `## RA-H Graph Memory

You are helping build a thoughtful graph of atomic units of context.

- Before substantive work that touches the user's projects, ideas, people, decisions, or prior context, retrieve relevant graph context from RA-H.
- Use queryNodes for direct lookup of a specific existing node.
- Use retrieveQueryContext for broader grounding before answering.
- Search before creating. Prefer updating the same artifact when it is clearly the same thing.
- When the user states a durable decision, preference, project fact, or useful idea, surface one concise candidate node for confirmation.
- Do not pester. Ask at most once per turn, and drop it if the user moves on.
- Preserve the user's wording in source for user-authored ideas unless they explicitly want a rewrite.
`;
}

function mergeRulesFile(existing, content) {
  const start = '<!-- RA-H_GRAPH_MEMORY_START -->';
  const end = '<!-- RA-H_GRAPH_MEMORY_END -->';
  const block = `${start}\n${content.trimEnd()}\n${end}`;
  const pattern = new RegExp(`${start}[\\s\\S]*?${end}`);

  if (pattern.test(existing)) {
    return `${existing.replace(pattern, block).trimEnd()}\n`;
  }

  return `${existing.trimEnd()}${existing.trim() ? '\n\n' : ''}${block}\n`;
}

function rulesTarget(client, target) {
  const base = expandPath(target || process.cwd());
  if (client === 'cursor') return path.join(base, '.cursor', 'rules', 'ra-h.mdc');
  if (client === 'aider') return path.join(base, 'CONVENTIONS.md');
  if (client === 'claude-code' || client === 'claude-desktop') return path.join(base, 'CLAUDE.md');
  return path.join(base, 'AGENTS.md');
}

function commandInitDb(args) {
  const dbPath = resolveDbPath(args);
  const quickCheck = initDb(dbPath);
  log(`Database ready at ${dbPath}`);
  log(`SQLite quick_check: ${quickCheck}`);
}

function commandDoctor(args) {
  const dbPath = resolveDbPath(args);
  const report = inspectDb(dbPath);
  let latest = null;
  const npmResult = spawnSync('npm', ['view', 'ra-h-mcp-server', 'version'], {
    encoding: 'utf8',
    timeout: 5000,
  });
  if (npmResult.status === 0) latest = npmResult.stdout.trim();

  log(`Package version: ${packageJson.version}`);
  if (latest) log(`npm latest: ${latest}`);
  log(`DB path: ${dbPath}`);

  if (!report.exists) fail(`Database does not exist at ${dbPath}. Run init-db or setup first.`);
  if (!report.ok) fail(`Database schema missing: ${report.missing.join(', ')}`);

  log(`SQLite quick_check: ${report.quickCheck}`);
  log(`Node count: ${report.nodeCount}`);
  log('Doctor passed.');
}

function commandPrintConfig(args) {
  const clients = resolveClients(args.client);
  const dbPath = resolveDbPath(args);
  clients.forEach((client) => {
    const config = clientConfig(client, args, dbPath);
    if (clients.length > 1) log(`Config for ${client}:`);
    console.log(formatSnippet(config.snippet));
    if (config.note) log(config.note);
    if (config.path) log(`Target path: ${config.path}`);
  });
}

function installRulesForClient(client, args) {
  const content = rulesSnippet();
  const targetPath = rulesTarget(client, args.target);

  if (args.printOnly || !args.yes) {
    console.log(content);
    log(`Rule file target: ${targetPath}`);
    log('Pass --yes to write it.');
    return;
  }

  fs.mkdirSync(path.dirname(targetPath), { recursive: true });
  const existing = fs.existsSync(targetPath) ? fs.readFileSync(targetPath, 'utf8') : '';
  fs.writeFileSync(targetPath, mergeRulesFile(existing, content));
  log(`Updated rules in ${targetPath}`);
}

function commandInstallRules(args) {
  resolveClients(args.client).forEach((client) => installRulesForClient(client, args));
}

function setupClient(client, args, dbPath) {
  const config = clientConfig(client, args, dbPath);
  log(`Configuring ${client}`);
  console.log(formatSnippet(config.snippet));
  if (config.path) log(`MCP config target: ${config.path}`);
  if (config.note) log(config.note);

  const canWrite = config.writable && ['json-merge', 'toml-merge'].includes(config.type) && config.path;
  if (canWrite && args.yes && !args.printOnly) {
    if (config.type === 'toml-merge') {
      writeTomlMerge(config);
    } else {
      writeJsonMerge(config);
    }
    log(`Updated ${config.path}`);
  } else if (canWrite) {
    log('Pass --yes to write this config automatically.');
  } else {
    log('Automatic config writing is not available for this client; copy the printed config.');
  }

  if (args.installRules) {
    installRulesForClient(client, args);
    return;
  }

  const rulePath = rulesTarget(client, args.target);
  log(`Recommended rules target: ${rulePath}`);
  log(`Install rules with: npx -y ${packageSpec(args)} install-rules --client ${client} --target <repo> --yes`);
}

function commandSetup(args) {
  const clients = resolveClients(args.client);
  const dbPath = resolveDbPath(args);
  initDb(dbPath);
  log(`Database ready at ${dbPath}`);

  clients.forEach((client) => setupClient(client, args, dbPath));
  commandDoctor(args);
}

function runCli(argv) {
  const [command, ...rest] = argv;
  const args = parseArgs(rest);

  if (!command || command === '--help' || command === '-h' || args.help) {
    usage();
    return;
  }

  if (command === 'setup') return commandSetup(args);
  if (command === 'doctor') return commandDoctor(args);
  if (command === 'init-db') return commandInitDb(args);
  if (command === 'print-config') return commandPrintConfig(args);
  if (command === 'install-rules') return commandInstallRules(args);

  fail(`Unknown command "${command}"`);
}

module.exports = {
  runCli,
  initDb,
  inspectDb,
  rulesSnippet,
};
