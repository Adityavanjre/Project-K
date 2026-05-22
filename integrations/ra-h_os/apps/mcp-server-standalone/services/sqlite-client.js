'use strict';

const Database = require('better-sqlite3');
const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');

/**
 * Get the database path.
 * Priority: RAH_DB_PATH env var > SQLITE_DB_PATH env var > platform app data location
 */
function getDefaultDbPath() {
  const homeDir = os.homedir() || process.env.HOME || '~';

  if (process.platform === 'win32') {
    const appData = process.env.APPDATA || path.join(homeDir, 'AppData', 'Roaming');
    return path.join(appData, 'RA-H', 'db', 'rah.sqlite');
  }

  if (process.platform === 'darwin') {
    return path.join(homeDir, 'Library', 'Application Support', 'RA-H', 'db', 'rah.sqlite');
  }

  return path.join(
    process.env.XDG_DATA_HOME || path.join(homeDir, '.local', 'share'),
    'RA-H',
    'db',
    'rah.sqlite'
  );
}

function getDatabasePath() {
  return process.env.RAH_DB_PATH || process.env.SQLITE_DB_PATH || getDefaultDbPath();
}

let db = null;

function getExistingColumnNames(db, tableName) {
  return db.prepare(`PRAGMA table_info(${tableName})`).all().map(c => c.name);
}

function validateExistingRahSchema(db) {
  const requiredTables = ['nodes', 'edges', 'chunks'];
  const missingTables = requiredTables.filter(
    tableName => !db.prepare("SELECT 1 FROM sqlite_master WHERE type='table' AND name = ?").get(tableName)
  );

  if (missingTables.length > 0) {
    throw new Error(
      `[RA-H MCP] Database is missing required tables: ${missingTables.join(', ')}. ` +
      'MCP startup will not create or migrate tables. Open the app and repair the database first.'
    );
  }

  const requiredNodeColumns = [
    'title', 'description', 'source', 'link', 'event_date', 'metadata',
    'embedding', 'embedding_updated_at', 'embedding_text', 'chunk_status',
    'created_at', 'updated_at'
  ];
  const requiredEdgeColumns = ['from_node_id', 'to_node_id', 'source', 'created_at', 'context', 'explanation'];
  const requiredChunkColumns = ['node_id', 'chunk_idx', 'text', 'embedding_type', 'metadata', 'created_at'];

  const schemaChecks = [
    ['nodes', requiredNodeColumns],
    ['edges', requiredEdgeColumns],
    ['chunks', requiredChunkColumns],
  ];

  for (const [tableName, requiredColumns] of schemaChecks) {
    const existingColumns = getExistingColumnNames(db, tableName);
    const missingColumns = requiredColumns.filter(columnName => !existingColumns.includes(columnName));
    if (missingColumns.length > 0) {
      throw new Error(
        `[RA-H MCP] Database table ${tableName} is missing required columns: ${missingColumns.join(', ')}. ` +
        'MCP startup will not migrate schema. Open the app and repair the database first.'
      );
    }
  }
}

/**
 * Initialize the database connection.
 * Call this once at startup.
 */
function initDatabase() {
  if (db) {
    return db;
  }

  const dbPath = getDatabasePath();

  if (!fs.existsSync(dbPath)) {
    throw new Error(
      `[RA-H MCP] Database not found at ${dbPath}. MCP startup will not create a new database. Open RA-H first to create or repair the app database.`
    );
  }

  db = new Database(dbPath);

  // Configure SQLite for WAL-first app/MCP coexistence.
  db.pragma('journal_mode = WAL');
  db.pragma('synchronous = NORMAL');
  db.pragma('cache_size = 5000');
  db.pragma('busy_timeout = 10000');

  validateExistingRahSchema(db);

  return db;
}

function ensureCoreSchema(db) {
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
  `);

  ensureEdgesTableSchema(db);
}

function ensureEdgesTableSchema(db) {
  const hasEdgesTable = db.prepare("SELECT 1 FROM sqlite_master WHERE type='table' AND name='edges'").get();

  if (!hasEdgesTable) {
    db.exec(`
      CREATE TABLE edges (
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
    `);
  } else {
    const edgeColNames = new Set(db.prepare('PRAGMA table_info(edges)').all().map((col) => col.name));
    const needsLegacyRewrite =
      !edgeColNames.has('from_node_id') ||
      !edgeColNames.has('to_node_id') ||
      !edgeColNames.has('source') ||
      !edgeColNames.has('created_at') ||
      !edgeColNames.has('context') ||
      edgeColNames.has('from_id') ||
      edgeColNames.has('to_id') ||
      edgeColNames.has('description') ||
      edgeColNames.has('updated_at');

    if (needsLegacyRewrite) {
      rebuildLegacyEdgesTable(db, edgeColNames);
    }
  }

  db.exec(`
    CREATE INDEX IF NOT EXISTS idx_edges_from ON edges(from_node_id);
    CREATE INDEX IF NOT EXISTS idx_edges_to ON edges(to_node_id);
  `);
}

function rebuildLegacyEdgesTable(db, edgeColNames) {
  const fromExpr = edgeColNames.has('from_node_id')
    ? 'from_node_id'
    : edgeColNames.has('from_id')
      ? 'from_id'
      : 'NULL';
  const toExpr = edgeColNames.has('to_node_id')
    ? 'to_node_id'
    : edgeColNames.has('to_id')
      ? 'to_id'
      : 'NULL';
  const sourceExpr = edgeColNames.has('source') ? 'source' : "'legacy'";
  const createdAtExpr = edgeColNames.has('created_at') ? 'created_at' : 'CURRENT_TIMESTAMP';
  const contextExpr = edgeColNames.has('context') ? 'context' : 'NULL';
  const explanationExpr = edgeColNames.has('explanation')
    ? 'explanation'
    : edgeColNames.has('description')
      ? 'description'
      : edgeColNames.has('context')
        ? "CASE WHEN json_valid(context) THEN json_extract(context, '$.explanation') ELSE NULL END"
        : 'NULL';

  console.error('[RA-H] Migrating legacy edges table to canonical schema');

  let flippedForeignKeys = false;
  try {
    db.exec('PRAGMA foreign_keys=OFF;');
    flippedForeignKeys = true;
  } catch {}

  try {
    db.exec('BEGIN TRANSACTION;');
    db.exec(`
      DROP INDEX IF EXISTS idx_edges_from;
      DROP INDEX IF EXISTS idx_edges_to;
      ALTER TABLE edges RENAME TO edges_legacy_migration;
      CREATE TABLE edges (
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
      INSERT INTO edges (id, from_node_id, to_node_id, source, created_at, context, explanation)
      SELECT
        id,
        ${fromExpr},
        ${toExpr},
        ${sourceExpr},
        COALESCE(${createdAtExpr}, CURRENT_TIMESTAMP),
        ${contextExpr},
        ${explanationExpr}
      FROM edges_legacy_migration
      WHERE ${fromExpr} IS NOT NULL
        AND ${toExpr} IS NOT NULL;
      DROP TABLE edges_legacy_migration;
      COMMIT;
    `);
  } catch (error) {
    try {
      db.exec('ROLLBACK;');
    } catch {}
    throw error;
  } finally {
    if (flippedForeignKeys) {
      try {
        db.exec('PRAGMA foreign_keys=ON;');
      } catch {}
    }
  }
}

/**
 * Get the database instance.
 * Throws if not initialized.
 */
function getDb() {
  if (!db) {
    throw new Error('Database not initialized. Call initDatabase() first.');
  }
  return db;
}

/**
 * Execute a query and return rows.
 */
function query(sql, params = []) {
  return runWithBusyRetry(() => {
    const database = getDb();
    const stmt = database.prepare(sql);

    const sqlLower = sql.trim().toLowerCase();
    if (sqlLower.startsWith('select') || sqlLower.startsWith('with') || sqlLower.startsWith('pragma') || sqlLower.includes('returning')) {
      return params.length > 0 ? stmt.all(...params) : stmt.all();
    } else {
      const result = params.length > 0 ? stmt.run(...params) : stmt.run();
      return {
        changes: result.changes,
        lastInsertRowid: Number(result.lastInsertRowid)
      };
    }
  }, 'query');
}

/**
 * Execute a query in a transaction.
 */
function transaction(callback) {
  const database = getDb();
  const txn = database.transaction(callback);
  return runWithBusyRetry(() => txn(), 'transaction');
}

function isBusyOrLocked(error) {
  const message = error instanceof Error ? error.message : String(error);
  const code = error && error.code ? String(error.code) : '';
  return code === 'SQLITE_BUSY' || code === 'SQLITE_LOCKED' || /database is locked|database busy/i.test(message);
}

function sleepSync(ms) {
  const buffer = new SharedArrayBuffer(4);
  const view = new Int32Array(buffer);
  Atomics.wait(view, 0, 0, ms);
}

function runWithBusyRetry(operation, label) {
  const maxAttempts = 4;
  let lastError;
  for (let attempt = 1; attempt <= maxAttempts; attempt += 1) {
    try {
      return operation();
    } catch (error) {
      if (!isBusyOrLocked(error) || attempt === maxAttempts) {
        throw error;
      }
      lastError = error;
      const delayMs = 100 * attempt * attempt;
      console.warn(`[RA-H MCP] SQLite ${label} hit ${error instanceof Error ? error.message : String(error)}; retrying in ${delayMs}ms (${attempt}/${maxAttempts})`);
      sleepSync(delayMs);
    }
  }
  throw lastError;
}

/**
 * Close the database connection.
 */
function closeDatabase() {
  if (db) {
    db.close();
    db = null;
  }
}

module.exports = {
  initDatabase,
  getDb,
  query,
  transaction,
  runWithBusyRetry,
  closeDatabase,
  getDatabasePath
};
