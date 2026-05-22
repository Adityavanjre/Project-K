import Database from 'better-sqlite3';
import fs from 'fs';
import path from 'path';
import { DatabaseError } from '@/types/database';
import { getDatabasePath, getVecExtensionPath } from '@/services/database/sqlite-runtime';
import { getEmbeddingProviderInfo } from '@/services/embedding/provider';
import { getVectorBackendType } from '@/services/vectorBackend';

export interface SQLiteConfig {
  dbPath: string;
  vecExtensionPath: string;
}

export interface SQLiteQueryResult<T = any> {
  rows: T[];
  changes?: number;
  lastInsertRowid?: number;
}

type FtsSurfaceName = 'nodes' | 'chunks';
type VectorTableName = 'vec_nodes' | 'vec_chunks';

interface IntegrityProbeResult {
  ok: boolean;
  error?: string;
  code?: string;
}

export interface DatabaseIntegrityReport {
  state: 'healthy' | 'degraded_fts' | 'corrupt';
  connected: boolean;
  quickCheck: IntegrityProbeResult;
  integrityCheck: IntegrityProbeResult;
  baseTables: Record<'nodes' | 'edges' | 'chunks', IntegrityProbeResult>;
  ftsTables: Record<FtsSurfaceName, boolean>;
  ftsProbeResults: Record<FtsSurfaceName, IntegrityProbeResult>;
  repairableFtsTables: FtsSurfaceName[];
  canRepairFts: boolean;
  foreignKeyViolations: number;
  lostAndFoundExists: boolean;
  vecTables: {
    nodes: boolean;
    chunks: boolean;
  };
  summary: string;
  error?: string;
}

export interface EmbeddingProfileStatus {
  active: {
    profile: string;
    model: string;
    dimensions: number;
    vector_backend: string;
  };
  stored: {
    profile: string;
    model: string;
    dimensions: number;
    vector_backend: string;
    updated_at?: string;
  } | null;
  vectors: {
    nodes: number;
    chunks: number;
  };
  rebuild_required: boolean;
  reason?: string;
}

class SQLiteClient {
  private static instance: SQLiteClient;
  private db: Database.Database;
  private config: SQLiteConfig;
  private readonly readOnly: boolean;
  private readonly maintenanceMode: boolean;
  private integrityReport: DatabaseIntegrityReport | null = null;

  private constructor() {
    this.config = this.getSQLiteConfig();
    this.readOnly = process.env.SQLITE_READONLY === 'true';
    this.maintenanceMode = process.env.RAH_DB_MAINTENANCE === 'true';
    
    // Initialize database connection
    const dbDirectory = path.dirname(this.config.dbPath);
    if (!this.readOnly && !fs.existsSync(dbDirectory)) {
      fs.mkdirSync(dbDirectory, { recursive: true });
    }
    this.db = this.readOnly
      ? new Database(this.config.dbPath, { readonly: true, fileMustExist: true })
      : new Database(this.config.dbPath);
    
    // Load sqlite-vec extension
    try {
      this.db.loadExtension(this.config.vecExtensionPath);
      console.log('SQLite vector extension loaded successfully');
    } catch (error) {
      // Do not fail hard — allow the app to run without vector features
      console.error('Warning: Failed to load vector extension:', error);
    }

    // Configure SQLite settings
    if (this.readOnly) {
      try {
        this.db.pragma('query_only = ON');
      } catch (error) {
        console.warn('Failed to enable query_only pragma in read-only mode:', error);
      }
    } else {
      this.db.pragma('foreign_keys = ON');
      this.db.pragma('journal_mode = WAL');
      this.db.pragma('synchronous = NORMAL');
      this.db.pragma('cache_size = 10000');
      this.db.pragma('temp_store = memory');
      this.db.pragma('busy_timeout = 10000');

      this.withStartupWriteLock(() => {
        this.ensureCoreSchema();
        // Ensure vector virtual tables are present. Repair/rebuild is maintenance-only.
        this.ensureVectorTables();
        this.healVectorTablesIfCorrupt();

        // Ensure logging schema (rename memory->logs if needed, create triggers/views)
        this.ensureLoggingAndMemorySchemaLocked();
      });
      this.integrityReport = this.inspectIntegrity();

      if (this.integrityReport.state === 'healthy') {
        this.withStartupWriteLock(() => {
          this.ensureFtsTables();
        });
        this.integrityReport = this.inspectIntegrity();
      } else {
        console.warn(
          `[SQLiteIntegrity] Skipping startup FTS mutation because database is ${this.integrityReport.state}: ${this.integrityReport.summary}`
        );
      }
    }

    console.log('SQLite client initialized successfully');
  }

  private getSQLiteConfig(): SQLiteConfig {
    return {
      dbPath: getDatabasePath(),
      vecExtensionPath: getVecExtensionPath()
    };
  }

  public static getInstance(): SQLiteClient {
    if (!SQLiteClient.instance) {
      SQLiteClient.instance = new SQLiteClient();
    }
    return SQLiteClient.instance;
  }

  public query<T extends Record<string, any> = any>(
    sql: string, 
    params?: any[]
  ): SQLiteQueryResult<T> {
    try {
      return this.runWithBusyRetry(() => {
        const sqlLower = sql.trim().toLowerCase();

        // Handle different query types
        if (sqlLower.startsWith('select') ||
            sqlLower.startsWith('with') ||
            sqlLower.includes('returning')) {
          // SELECT queries and queries with RETURNING clause
          const stmt = this.db.prepare(sql);
          const rows = params ? stmt.all(...params) : stmt.all();
          return { rows: rows as T[] };
        } else {
          // INSERT/UPDATE/DELETE queries without RETURNING
          const stmt = this.db.prepare(sql);
          const result = params ? stmt.run(...params) : stmt.run();
          return {
            rows: [],
            changes: result.changes,
            lastInsertRowid: Number(result.lastInsertRowid)
          };
        }
      }, 'query');
    } catch (error) {
      this.refreshIntegrityReportForCorruptionError(error);
      console.error('SQLite query error:', error);
      throw this.handleError(error);
    }
  }

  public prepare(sql: string) {
    return this.db.prepare(sql);
  }

  public transaction<T>(callback: () => T): T {
    if (this.readOnly) {
      throw {
        message: 'SQLite client is read-only',
        code: 'SQLITE_READONLY',
        details: 'Transactions are not allowed in read-only mode'
      } as DatabaseError;
    }
    // Proactively validate vec vtables before any write transaction. Destructive
    // repair/rebuild is only allowed in explicit DB maintenance mode.
    this.healVectorTablesIfCorrupt();
    const txn = this.db.transaction(callback);
    try {
      return this.runWithBusyRetry(() => txn(), 'transaction');
    } catch (error) {
      this.refreshIntegrityReportForCorruptionError(error);
      throw this.handleError(error);
    }
  }

  private isBusyOrLocked(error: unknown): boolean {
    const message = error instanceof Error ? error.message : String(error);
    const code =
      typeof error === 'object' &&
      error !== null &&
      'code' in error &&
      typeof (error as { code?: unknown }).code === 'string'
        ? String((error as { code: string }).code)
        : '';
    return code === 'SQLITE_BUSY' || code === 'SQLITE_LOCKED' || /database is locked|database busy/i.test(message);
  }

  private sleepSync(ms: number): void {
    const buffer = new SharedArrayBuffer(4);
    const view = new Int32Array(buffer);
    Atomics.wait(view, 0, 0, ms);
  }

  private runWithBusyRetry<T>(operation: () => T, label: string): T {
    const maxAttempts = 4;
    let lastError: unknown;
    for (let attempt = 1; attempt <= maxAttempts; attempt += 1) {
      try {
        return operation();
      } catch (error) {
        if (!this.isBusyOrLocked(error) || attempt === maxAttempts) {
          throw error;
        }
        lastError = error;
        const delayMs = 100 * attempt * attempt;
        console.warn(`[SQLite] ${label} hit ${error instanceof Error ? error.message : String(error)}; retrying in ${delayMs}ms (${attempt}/${maxAttempts})`);
        this.sleepSync(delayMs);
      }
    }
    throw lastError;
  }

  public async testConnection(): Promise<boolean> {
    try {
      const result = this.query('SELECT datetime() as current_time');
      return result.rows.length > 0;
    } catch (error) {
      console.error('SQLite connection test failed:', error);
      return false;
    }
  }

  public async checkVectorExtension(): Promise<boolean> {
    try {
      const result = this.query('SELECT vec_version() as version');
      return result.rows.length > 0;
    } catch (error) {
      console.error('Vector extension check failed:', error);
      return false;
    }
  }

  public async checkTables(): Promise<string[]> {
    try {
      const result = this.query(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
      );
      return result.rows.map(row => row.name);
    } catch (error) {
      console.error('Table check failed:', error);
      return [];
    }
  }

  public ensureVectorExtensions(): void {
    try {
      const dimensions = getEmbeddingProviderInfo().dimensions;
      this.ensureVectorTable('vec_nodes', dimensions);
      this.ensureVectorTable('vec_chunks', dimensions);
    } catch (error) {
      console.warn('Vector extension not available:', error);
    }
  }

  private getVectorTableSql(tableName: VectorTableName): string | null {
    const row = this.db.prepare("SELECT sql FROM sqlite_master WHERE type='table' AND name=?")
      .get(tableName) as { sql?: string } | undefined;
    return row?.sql || null;
  }

  public getVectorTableDimensions(): Record<'nodes' | 'chunks', number | null> {
    return {
      nodes: this.getVectorTableDimension('vec_nodes'),
      chunks: this.getVectorTableDimension('vec_chunks'),
    };
  }

  private getVectorTableDimension(tableName: VectorTableName): number | null {
    const sql = this.getVectorTableSql(tableName);
    const match = sql?.match(/embedding\s+FLOAT\[(\d+)\]/i);
    return match ? Number(match[1]) : null;
  }

  private createVectorTable(tableName: VectorTableName, dimensions: number): void {
    const idColumn = tableName === 'vec_nodes' ? 'node_id' : 'chunk_id';
    this.db.exec(`
      CREATE VIRTUAL TABLE ${tableName} USING vec0(
        ${idColumn} INTEGER PRIMARY KEY,
        embedding FLOAT[${dimensions}]
      );
    `);
  }

  private ensureVectorTable(tableName: VectorTableName, dimensions: number): void {
    const existingSql = this.getVectorTableSql(tableName);
    if (!existingSql) {
      this.createVectorTable(tableName, dimensions);
      console.log(`Created ${tableName} virtual table`);
      return;
    }

    const existingDimensions = this.getVectorTableDimension(tableName);
    if (existingDimensions === dimensions) {
      return;
    }

    const rowCount = this.countVectorRows(tableName);
    if (rowCount === 0 || this.maintenanceMode) {
      this.db.exec(`DROP TABLE IF EXISTS ${tableName};`);
      this.createVectorTable(tableName, dimensions);
      console.warn(`Recreated ${tableName} virtual table for ${dimensions} dimensions (was ${existingDimensions ?? 'unknown'}).`);
      return;
    }

    console.warn(
      `${tableName} uses ${existingDimensions ?? 'unknown'} dimensions, but the active embedding profile requires ${dimensions}. ` +
      'Run npm run rebuild:embeddings to recreate derived vectors.'
    );
  }

  public recreateVectorTables(): void {
    if (this.readOnly) {
      throw new Error('Cannot recreate vector tables while SQLITE_READONLY=true.');
    }
    const dimensions = getEmbeddingProviderInfo().dimensions;
    this.db.exec(`
      DROP TABLE IF EXISTS vec_nodes;
      DROP TABLE IF EXISTS vec_chunks;
    `);
    this.createVectorTable('vec_nodes', dimensions);
    this.createVectorTable('vec_chunks', dimensions);
  }

  private ensureVectorTables(): void {
    if (this.readOnly) {
      return;
    }
    // Wrapper to keep existing public API stable
    this.ensureVectorExtensions();
  }

  private withStartupWriteLock<T>(callback: () => T): T {
    this.db.exec('BEGIN IMMEDIATE');
    try {
      const result = callback();
      this.db.exec('COMMIT');
      return result;
    } catch (error) {
      try {
        this.db.exec('ROLLBACK');
      } catch {}
      throw error;
    }
  }

  private ensureCoreSchema(): void {
    if (this.readOnly) {
      return;
    }

    this.db.exec(`
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

      CREATE TABLE IF NOT EXISTS chunks (
        id INTEGER PRIMARY KEY,
        node_id INTEGER NOT NULL,
        chunk_idx INTEGER,
        text TEXT NOT NULL,
        embedding BLOB,
        embedding_type TEXT DEFAULT 'openai',
        metadata TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (node_id) REFERENCES nodes(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS embedding_profile_state (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        profile TEXT NOT NULL,
        model TEXT NOT NULL,
        dimensions INTEGER NOT NULL,
        vector_backend TEXT NOT NULL,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS chats (
        id INTEGER PRIMARY KEY,
        chat_type TEXT,
        helper_name TEXT,
        agent_type TEXT DEFAULT 'orchestrator',
        delegation_id INTEGER,
        user_message TEXT,
        assistant_message TEXT,
        thread_id TEXT,
        focused_node_id INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        metadata TEXT,
        FOREIGN KEY (focused_node_id) REFERENCES nodes(id) ON DELETE SET NULL
      );

      CREATE INDEX IF NOT EXISTS idx_edges_from ON edges(from_node_id);
      CREATE INDEX IF NOT EXISTS idx_edges_to ON edges(to_node_id);
      CREATE INDEX IF NOT EXISTS idx_nodes_updated_at ON nodes(updated_at DESC);
      CREATE INDEX IF NOT EXISTS idx_chunks_node_id ON chunks(node_id);
      CREATE INDEX IF NOT EXISTS idx_chats_thread ON chats(thread_id);
    `);
  }

  private ensureLoggingAndMemorySchema(): void {
    if (this.readOnly) {
      return;
    }
    this.withStartupWriteLock(() => this.ensureLoggingAndMemorySchemaLocked());
  }

  private ensureLoggingAndMemorySchemaLocked(): void {
    try {
      const hasChats = this.db.prepare("SELECT name FROM sqlite_master WHERE type='table' AND name='chats'").get();
      // Existing installs may already have logs but still need the idempotent schema pass below.
      // Only skip the legacy memory rename step when logs already exists.
      const hasLogs = this.db.prepare("SELECT name FROM sqlite_master WHERE type='table' AND name='logs'").get();
      const hasLegacyMemory = this.db.prepare("SELECT name FROM sqlite_master WHERE type='table' AND name='memory'").get();
      if (!hasLogs && hasLegacyMemory) {
        // Drop old view to release dependency
        this.db.exec(`DROP VIEW IF EXISTS memory_v;`);
        this.db.exec(`ALTER TABLE memory RENAME TO logs;`);
      }

      // 2) Ensure logs table exists (fresh install)
      const hasLogsNow = this.db.prepare("SELECT name FROM sqlite_master WHERE type='table' AND name='logs'").get();
      if (!hasLogsNow) {
        this.db.exec(`
            CREATE TABLE logs (
              id INTEGER PRIMARY KEY,
              ts TEXT NOT NULL DEFAULT (CURRENT_TIMESTAMP),
              table_name TEXT NOT NULL,
              action TEXT NOT NULL,
              row_id INTEGER NOT NULL,
              summary TEXT,
              snapshot_json TEXT
            );
          `);
      }

      // Ensure nodes table has expected columns for memory nodes
      try {
        const nodeCols = this.db.prepare('PRAGMA table_info(nodes)').all() as Array<{ name: string }>;
        const ensureNodeCol = (name: string, ddl: string) => {
          if (!nodeCols.some(col => col.name === name)) {
            try {
              this.db.exec(ddl);
            } catch (colErr) {
              console.warn(`Failed to add nodes.${name}`, colErr);
            }
          }
        };
        ensureNodeCol('description', "ALTER TABLE nodes ADD COLUMN description TEXT;");
        ensureNodeCol('link', 'ALTER TABLE nodes ADD COLUMN link TEXT;');
        ensureNodeCol('source', 'ALTER TABLE nodes ADD COLUMN source TEXT;');
        ensureNodeCol('metadata', 'ALTER TABLE nodes ADD COLUMN metadata TEXT;');
        ensureNodeCol('created_at', "ALTER TABLE nodes ADD COLUMN created_at TEXT DEFAULT CURRENT_TIMESTAMP;");
        ensureNodeCol('updated_at', "ALTER TABLE nodes ADD COLUMN updated_at TEXT DEFAULT CURRENT_TIMESTAMP;");
      } catch (nodeErr) {
        console.warn('Failed to ensure nodes columns:', nodeErr);
      }

        // Ensure chats table tracks creation timestamp for ordering
        try {
          const chatCols = this.db.prepare('PRAGMA table_info(chats)').all() as Array<{ name: string }>;
          if (chatCols.some(col => col.name === 'created_at')) {
            // no-op, column exists
          } else if (chatCols.length > 0) {
            this.db.exec("ALTER TABLE chats ADD COLUMN created_at TEXT DEFAULT (CURRENT_TIMESTAMP);");
          }
        } catch (chatErr) {
          console.warn('Failed to ensure chats.created_at column:', chatErr);
        }

        // 3) Helpful indexes on logs (clean up old names first)
        this.db.exec(`
          DROP INDEX IF EXISTS idx_memory_ts;
          DROP INDEX IF EXISTS idx_memory_table_ts;
          DROP INDEX IF EXISTS idx_memory_table_row;
          CREATE INDEX IF NOT EXISTS idx_logs_ts ON logs(ts);
          CREATE INDEX IF NOT EXISTS idx_logs_table_ts ON logs(table_name, ts);
          CREATE INDEX IF NOT EXISTS idx_logs_table_row ON logs(table_name, row_id);
        `);

        // 4) Recreate triggers to write to logs (use CREATE IF NOT EXISTS)
        this.db.exec(`
          DROP TRIGGER IF EXISTS trg_nodes_ai;
          DROP TRIGGER IF EXISTS trg_nodes_au;
          CREATE TRIGGER IF NOT EXISTS trg_nodes_ai AFTER INSERT ON nodes BEGIN
            INSERT INTO logs(table_name, action, row_id, summary, snapshot_json)
            VALUES('nodes', 'insert', NEW.id,
                   printf('node created: %s', COALESCE(NEW.title,'')),
                   json_object('id', NEW.id, 'title', NEW.title, 'link', NEW.link));
          END;
          CREATE TRIGGER IF NOT EXISTS trg_nodes_au AFTER UPDATE ON nodes BEGIN
            INSERT INTO logs(table_name, action, row_id, summary, snapshot_json)
            VALUES('nodes', 'update', NEW.id,
                   printf('node updated: %s', COALESCE(NEW.title,'')),
                   json_object('id', NEW.id, 'title', NEW.title, 'link', NEW.link));
          END;

          DROP TRIGGER IF EXISTS trg_edges_ai;
          DROP TRIGGER IF EXISTS trg_edges_au;
          CREATE TRIGGER IF NOT EXISTS trg_edges_ai AFTER INSERT ON edges BEGIN
            INSERT INTO logs(table_name, action, row_id, summary, snapshot_json)
            VALUES('edges', 'insert', NEW.id,
                   printf('edge %d→%d (%s)', NEW.from_node_id, NEW.to_node_id, COALESCE(NEW.source,'')),
                   json_object(
                     'id', NEW.id,
                     'from', NEW.from_node_id,
                     'to', NEW.to_node_id,
                     'source', NEW.source,
                     'from_title', substr((SELECT title FROM nodes WHERE id = NEW.from_node_id), 1, 120),
                     'to_title', substr((SELECT title FROM nodes WHERE id = NEW.to_node_id), 1, 120)
                   ));
          END;
          CREATE TRIGGER IF NOT EXISTS trg_edges_au AFTER UPDATE ON edges BEGIN
            INSERT INTO logs(table_name, action, row_id, summary, snapshot_json)
            VALUES('edges', 'update', NEW.id,
                   printf('edge updated %d→%d', NEW.from_node_id, NEW.to_node_id),
                   json_object(
                     'id', NEW.id,
                     'from', NEW.from_node_id,
                     'to', NEW.to_node_id,
                     'source', NEW.source,
                     'from_title', substr((SELECT title FROM nodes WHERE id = NEW.from_node_id), 1, 120),
                     'to_title', substr((SELECT title FROM nodes WHERE id = NEW.to_node_id), 1, 120)
                   ));
          END;
        `);

        if (hasChats) {
          this.db.exec(`
            DROP TRIGGER IF EXISTS trg_chats_ai;
            CREATE TRIGGER IF NOT EXISTS trg_chats_ai AFTER INSERT ON chats BEGIN
              INSERT INTO logs(table_name, action, row_id, summary, snapshot_json)
              VALUES('chats', 'insert', NEW.id,
                     printf('chat: %s (%s)', COALESCE(NEW.helper_name,''), COALESCE(NEW.thread_id,'')),
                     json_object(
                       'id', NEW.id,
                       'helper', NEW.helper_name,
                       'thread', NEW.thread_id,
                       'user_message', COALESCE(NEW.user_message,''),
                       'assistant_message', COALESCE(NEW.assistant_message,''),
                       'user_preview', substr(COALESCE(NEW.user_message,''), 1, 120),
                       'assistant_preview', substr(COALESCE(NEW.assistant_message,''), 1, 120),
                       'system_message', COALESCE(json_extract(NEW.metadata, '$.system_message'), ''),
                       'input_tokens', COALESCE(json_extract(NEW.metadata, '$.input_tokens'), 0),
                       'output_tokens', COALESCE(json_extract(NEW.metadata, '$.output_tokens'), 0),
                       'cost_usd', COALESCE(json_extract(NEW.metadata, '$.estimated_cost_usd'), 0.0),
                       'cache_hit', COALESCE(json_extract(NEW.metadata, '$.cache_hit'), 0),
                       'model', COALESCE(json_extract(NEW.metadata, '$.model_used'), ''),
                       'tools_count', COALESCE(json_extract(NEW.metadata, '$.tool_calls_count'), 0),
                       'tools_used', COALESCE(json_extract(NEW.metadata, '$.tools_used'), json('[]')),
                       'latency_ms', COALESCE(json_extract(NEW.metadata, '$.latency_ms'), 0),
                       'prompt_build_ms', COALESCE(json_extract(NEW.metadata, '$.timing_breakdown.promptBuildMs'), 0),
                       'tools_build_ms', COALESCE(json_extract(NEW.metadata, '$.timing_breakdown.toolsBuildMs'), 0),
                       'model_resolve_ms', COALESCE(json_extract(NEW.metadata, '$.timing_breakdown.modelResolveMs'), 0),
                       'message_assembly_ms', COALESCE(json_extract(NEW.metadata, '$.timing_breakdown.messageAssemblyMs'), 0),
                       'stream_setup_ms', COALESCE(json_extract(NEW.metadata, '$.timing_breakdown.streamSetupMs'), 0),
                       'tool_loop_ms', COALESCE(json_extract(NEW.metadata, '$.timing_breakdown.toolLoopMs'), 0),
                       'first_token_latency_ms', COALESCE(json_extract(NEW.metadata, '$.first_token_latency_ms'), 0),
                       'first_chunk_latency_ms', COALESCE(json_extract(NEW.metadata, '$.first_chunk_latency_ms'), 0),
                       'tool_timings', COALESCE(json_extract(NEW.metadata, '$.tool_timings'), json('[]')),
                       'trace_id', COALESCE(json_extract(NEW.metadata, '$.trace_id'), ''),
                       'voice_tts_chars', COALESCE(json_extract(NEW.metadata, '$.voice_tts_chars'), 0),
                       'voice_tts_cost_usd', COALESCE(json_extract(NEW.metadata, '$.voice_tts_cost_usd'), 0),
                       'voice_tts_chars_total', COALESCE(json_extract(NEW.metadata, '$.voice_tts_chars_total'), 0),
                       'voice_tts_cost_usd_total', COALESCE(json_extract(NEW.metadata, '$.voice_tts_cost_usd_total'), 0),
                       'voice_request_id', COALESCE(json_extract(NEW.metadata, '$.voice_request_id'), ''),
                       'voice_tts_request_count', COALESCE(json_extract(NEW.metadata, '$.voice_tts_request_count'), 0)
                     ));
            END;
          `);
        }

        this.db.exec(`
          CREATE TABLE IF NOT EXISTS voice_usage (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            chat_id INTEGER,
            session_id TEXT,
            helper_name TEXT,
            request_id TEXT,
            message_id TEXT,
            voice TEXT,
            model TEXT,
            chars INTEGER,
            cost_usd REAL,
            duration_ms INTEGER,
            text_preview TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE SET NULL
          );
          CREATE INDEX IF NOT EXISTS idx_voice_usage_session ON voice_usage(session_id, created_at);
          CREATE INDEX IF NOT EXISTS idx_voice_usage_chat ON voice_usage(chat_id);
        `);

        // 5) Views: logs_v (drop any legacy memory_v alias)
        this.db.exec(`DROP VIEW IF EXISTS logs_v; DROP VIEW IF EXISTS memory_v;`);
        try {
          this.db.exec(`
          CREATE VIEW logs_v AS
          SELECT 
            m.id,
            m.ts,
            m.table_name,
            m.action,
            m.row_id,
            m.summary,
            m.enriched_summary,
            m.snapshot_json,
            CASE WHEN m.table_name='nodes' THEN n.title END AS node_title,
            CASE WHEN m.table_name='edges' THEN nf.title END AS edge_from_title,
            CASE WHEN m.table_name='edges' THEN nt.title END AS edge_to_title,
            CASE WHEN m.table_name='chats' THEN c.helper_name END AS chat_helper,
            CASE WHEN m.table_name='chats' THEN substr(c.user_message,1,120) END AS chat_user_preview,
            CASE WHEN m.table_name='chats' THEN substr(c.assistant_message,1,120) END AS chat_assistant_preview,
            CASE WHEN m.table_name='chats' THEN c.user_message END AS chat_user_full,
            CASE WHEN m.table_name='chats' THEN c.assistant_message END AS chat_assistant_full
          FROM logs m
          LEFT JOIN nodes n ON (m.table_name='nodes' AND m.row_id = n.id)
          LEFT JOIN edges e ON (m.table_name='edges' AND m.row_id = e.id)
          LEFT JOIN nodes nf ON e.from_node_id = nf.id
          LEFT JOIN nodes nt ON e.to_node_id = nt.id
          LEFT JOIN chats c ON (m.table_name='chats' AND m.row_id = c.id);
        `);
        } catch (error) {
          if (
            !(error instanceof Error) ||
            !/already exists/i.test(error.message || '')
          ) {
            throw error;
          }
        }
        // Do not recreate memory_v; alias has been removed.

        // 6) Clean up removed chat_memory_state table
        try {
          this.db.exec(`DROP TABLE IF EXISTS chat_memory_state;`);
        } catch (e) {
          // Ignore if table doesn't exist
        }

        // Clean up removed agent_delegations table
        try {
          this.db.exec(`DROP TABLE IF EXISTS agent_delegations;`);
        } catch (e) {
          console.warn('Failed to drop agent_delegations table:', e);
        }

        // 8) Logs retention trigger (~10k most recent rows)
      try {
        this.db.exec(`
            DROP TRIGGER IF EXISTS trg_logs_prune;
            CREATE TRIGGER IF NOT EXISTS trg_logs_prune AFTER INSERT ON logs BEGIN
              DELETE FROM logs WHERE id < NEW.id - 10000;
            END;
          `);
      } catch {}

      // 7) Ensure agents table schema (backward compatibility)
      try {
        const agentCols = this.db.prepare('PRAGMA table_info(agents)').all() as any[];
        if (agentCols.length) {
          const hasKey = agentCols.some(col => col.name === 'key');
          const hasComponentKey = agentCols.some(col => col.name === 'component_key');
          if (!hasKey && hasComponentKey) {
            try { this.db.exec('ALTER TABLE agents RENAME COLUMN component_key TO key;'); } catch {}
          }

          if (!agentCols.some(col => col.name === 'role')) {
            try { this.db.exec("ALTER TABLE agents ADD COLUMN role TEXT NOT NULL DEFAULT 'executor';"); } catch {}
          }
          if (!agentCols.some(col => col.name === 'memory')) {
            try { this.db.exec('ALTER TABLE agents ADD COLUMN memory TEXT;'); } catch {}
          }
          if (!agentCols.some(col => col.name === 'prompts')) {
            try { this.db.exec("ALTER TABLE agents ADD COLUMN prompts TEXT DEFAULT '[]';"); } catch {}
          }
        }
      } catch (e) {
        console.warn('Agent schema ensure failed:', e);
      }

      // 8) Ensure chats schema (remove legacy focused_memory_id, ensure agent columns)
      if (hasChats) {
        try {
          let chatCols = this.db.prepare('PRAGMA table_info(chats)').all() as any[];
          const hasFocusedMemoryId = chatCols.some((c: any) => c.name === 'focused_memory_id');
          if (hasFocusedMemoryId) {
            console.log('Removing legacy chats.focused_memory_id column');
            let flippedForeignKeys = false;
            try {
              this.db.exec('PRAGMA foreign_keys=OFF;');
              flippedForeignKeys = true;
              this.db.exec(`
                BEGIN TRANSACTION;
                ALTER TABLE chats RENAME TO chats_legacy_cleanup;
                CREATE TABLE chats (
                  id INTEGER PRIMARY KEY,
                  chat_type TEXT,
                  helper_name TEXT,
                  agent_type TEXT DEFAULT 'orchestrator',
                  delegation_id INTEGER,
                  user_message TEXT,
                  assistant_message TEXT,
                  thread_id TEXT,
                  focused_node_id INTEGER,
                  created_at TEXT DEFAULT (CURRENT_TIMESTAMP),
                  metadata TEXT,
                  FOREIGN KEY (focused_node_id) REFERENCES nodes(id) ON DELETE SET NULL
                );
                INSERT INTO chats (
                  id, chat_type, helper_name, agent_type, delegation_id,
                  user_message, assistant_message, thread_id, focused_node_id,
                  created_at, metadata
                )
                SELECT id, chat_type, helper_name, agent_type, delegation_id,
                       user_message, assistant_message, thread_id, focused_node_id,
                       created_at, metadata
                  FROM chats_legacy_cleanup;
                DROP TABLE chats_legacy_cleanup;
                CREATE INDEX IF NOT EXISTS idx_chats_thread ON chats(thread_id);
                COMMIT;
              `);
            } catch (migrationErr) {
              console.warn('Failed to migrate chats table (focused_memory_id removal):', migrationErr);
              try { this.db.exec('ROLLBACK;'); } catch {}
            } finally {
              if (flippedForeignKeys) {
                try { this.db.exec('PRAGMA foreign_keys=ON;'); } catch {}
              }
            }
            chatCols = this.db.prepare('PRAGMA table_info(chats)').all() as any[];
          }

          this.db.exec("CREATE INDEX IF NOT EXISTS idx_chats_thread ON chats(thread_id);");

          const ensureCol = (name: string, ddl: string) => {
            if (!chatCols.some((c: any) => c.name === name)) {
              try { this.db.exec(ddl); } catch (colErr) { console.warn(`Failed to add chats.${name}`, colErr); }
            }
          };
          ensureCol('agent_type', "ALTER TABLE chats ADD COLUMN agent_type TEXT DEFAULT 'orchestrator';");
          ensureCol('delegation_id', 'ALTER TABLE chats ADD COLUMN delegation_id INTEGER;');
        } catch (e) {
          console.warn('Failed to update chats schema:', e);
        }
      }

      try {
        const chatColsPost = hasChats
          ? this.db.prepare('PRAGMA table_info(chats)').all() as any[]
          : [];
        const stillHasFocusedMemoryId = chatColsPost.some((c: any) => c.name === 'focused_memory_id');
        if (stillHasFocusedMemoryId) {
          console.warn('Skipping legacy memory table drop because chats.focused_memory_id is still present.');
        } else {
          this.db.exec(`
            DROP TRIGGER IF EXISTS trg_episodic_prune;
            DROP TABLE IF EXISTS episodic_memory;
            DROP TABLE IF EXISTS episodic_pipeline_state;
            DROP TABLE IF EXISTS semantic_memory;
            DROP TABLE IF EXISTS semantic_pipeline_state;
            DROP TABLE IF EXISTS memory_pipeline_state;
            DROP TABLE IF EXISTS memory;
          `);
        }
      } catch (dropLegacyErr) {
        console.warn('Failed to drop legacy memory pipeline tables:', dropLegacyErr);
      }

      // 9) Final schema pass migrations (source-first backfill, event_date, legacy category cleanup, drop dimensions)
      try {
        let nodeCols2 = this.db.prepare('PRAGMA table_info(nodes)').all() as Array<{ name: string }>;
        let nodeColNames = nodeCols2.map(c => c.name);

        if (!nodeColNames.includes('source')) {
          console.log('Adding nodes.source column...');
          this.db.exec('ALTER TABLE nodes ADD COLUMN source TEXT;');
          nodeCols2 = this.db.prepare('PRAGMA table_info(nodes)').all() as Array<{ name: string }>;
          nodeColNames = nodeCols2.map(c => c.name);
        }

        if (!nodeColNames.includes('chunk_status')) {
          this.db.exec("ALTER TABLE nodes ADD COLUMN chunk_status TEXT DEFAULT 'not_chunked';");
          nodeCols2 = this.db.prepare('PRAGMA table_info(nodes)').all() as Array<{ name: string }>;
          nodeColNames = nodeCols2.map(c => c.name);
        }

        if (nodeColNames.includes('source')) {
          if (nodeColNames.includes('content')) {
            this.db.exec(`
              UPDATE nodes
              SET source = content,
                  chunk_status = 'not_chunked'
              WHERE (source IS NULL OR LENGTH(TRIM(source)) = 0)
                AND content IS NOT NULL
                AND LENGTH(TRIM(content)) > 0;
            `);
          }

          if (nodeColNames.includes('notes')) {
            this.db.exec(`
              UPDATE nodes
              SET source = notes,
                  chunk_status = 'not_chunked'
              WHERE (source IS NULL OR LENGTH(TRIM(source)) = 0)
                AND notes IS NOT NULL
                AND LENGTH(TRIM(notes)) > 0;
            `);
          }

          if (nodeColNames.includes('chunk')) {
            this.db.exec(`
              UPDATE nodes
              SET source = chunk,
                  chunk_status = 'not_chunked'
              WHERE (source IS NULL OR LENGTH(TRIM(source)) = 0)
                AND chunk IS NOT NULL
                AND LENGTH(TRIM(chunk)) > 0;
            `);
          }

          this.db.exec(`
            UPDATE nodes
            SET source = title || CASE
              WHEN description IS NOT NULL AND LENGTH(TRIM(description)) > 0
                THEN char(10) || char(10) || description
              ELSE ''
            END,
            chunk_status = 'not_chunked'
            WHERE source IS NULL OR LENGTH(TRIM(source)) = 0;
          `);

          this.db.exec(`
            UPDATE nodes
            SET chunk_status = 'not_chunked'
            WHERE source IS NOT NULL
              AND LENGTH(TRIM(source)) > 0
              AND (chunk_status IS NULL OR chunk_status != 'chunked');
          `);
        }

        // Add event_date
        if (!nodeColNames.includes('event_date')) {
          this.db.exec('ALTER TABLE nodes ADD COLUMN event_date TEXT;');
          // Backfill from metadata.published_date or metadata.source_metadata.published_date where available
          try {
            this.db.exec(`
              UPDATE nodes
              SET event_date = COALESCE(
                json_extract(metadata, '$.source_metadata.published_date'),
                json_extract(metadata, '$.published_date')
              )
              WHERE event_date IS NULL
                AND COALESCE(
                  json_extract(metadata, '$.source_metadata.published_date'),
                  json_extract(metadata, '$.published_date')
                ) IS NOT NULL;
            `);
          } catch {}
        }

        const hasLegacyDimensions = this.db.prepare("SELECT 1 FROM sqlite_master WHERE type='table' AND name='dimensions'").get();
        const hasLegacyNodeDimensions = this.db.prepare("SELECT 1 FROM sqlite_master WHERE type='table' AND name='node_dimensions'").get();
        this.db.exec(`
          CREATE TABLE IF NOT EXISTS dimension_migration_snapshots (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            migrated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
            dimension_count INTEGER NOT NULL,
            assignment_count INTEGER NOT NULL,
            payload TEXT
          );
        `);

        if (hasLegacyDimensions || hasLegacyNodeDimensions) {
          const existingSnapshotCount = Number(
            (this.db.prepare('SELECT COUNT(*) as count FROM dimension_migration_snapshots').get() as { count?: number } | undefined)?.count ?? 0
          );

          if (existingSnapshotCount === 0) {
            const dimensionCount = hasLegacyDimensions
              ? Number((this.db.prepare('SELECT COUNT(*) as count FROM dimensions').get() as { count?: number } | undefined)?.count ?? 0)
              : 0;
            const assignmentCount = hasLegacyNodeDimensions
              ? Number((this.db.prepare('SELECT COUNT(*) as count FROM node_dimensions').get() as { count?: number } | undefined)?.count ?? 0)
              : 0;
            const payload = hasLegacyNodeDimensions
              ? (
                  this.db.prepare(`
                    SELECT COALESCE(
                      json_group_array(
                        json_object(
                          'node_id', nd.node_id,
                          'dimension', nd.dimension,
                          'description', d.description,
                          'icon', d.icon,
                          'is_priority', d.is_priority
                        )
                      ),
                      '[]'
                    ) AS payload
                    FROM node_dimensions nd
                    LEFT JOIN dimensions d ON d.name = nd.dimension
                  `).get() as { payload?: string } | undefined
                )?.payload ?? '[]'
              : '[]';

            this.db.prepare(`
              INSERT INTO dimension_migration_snapshots (dimension_count, assignment_count, payload)
              VALUES (?, ?, ?)
            `).run(dimensionCount, assignmentCount, payload);
          }

          this.db.exec(`
            DROP INDEX IF EXISTS idx_dim_by_dimension;
            DROP INDEX IF EXISTS idx_dim_by_node;
            DROP TABLE IF EXISTS node_dimensions;
            DROP TABLE IF EXISTS dimensions;
          `);
        }

        // Drop dead columns (requires SQLite 3.35+)
        // nodes.type
        if (nodeColNames.includes('type')) {
          try { this.db.exec('ALTER TABLE nodes DROP COLUMN type;'); } catch {}
        }
        // nodes.is_pinned
        if (nodeColNames.includes('is_pinned')) {
          try { this.db.exec('ALTER TABLE nodes DROP COLUMN is_pinned;'); } catch {}
        }
        // edges.user_feedback
        const edgeCols = this.db.prepare('PRAGMA table_info(edges)').all() as Array<{ name: string }>;
        if (edgeCols.some(c => c.name === 'user_feedback')) {
          try { this.db.exec('ALTER TABLE edges DROP COLUMN user_feedback;'); } catch {}
        }
        // edges.explanation (top-level column added alongside context JSON)
        if (!edgeCols.some(c => c.name === 'explanation')) {
          this.db.exec('ALTER TABLE edges ADD COLUMN explanation TEXT;');
          // Backfill from context JSON where available
          try {
            this.db.exec(`
              UPDATE edges SET explanation = json_extract(context, '$.explanation')
              WHERE explanation IS NULL AND json_extract(context, '$.explanation') IS NOT NULL;
            `);
          } catch {}
        }

      } catch (schemaErr) {
        console.warn('Final schema pass migration error:', schemaErr);
      }

      console.log('Logging + memory schema ensured');
    } catch (error) {
      console.error('Failed to ensure logging/memory schema:', error);
    }
  }

  private healVectorTablesIfCorrupt(): void {
    if (this.readOnly) {
      return;
    }
    // Attempt lightweight reads to detect CORRUPT_VTAB; if detected, drop/recreate vtables
    const tryRead = (table: string) => {
      try {
        this.db.prepare(`SELECT COUNT(*) as c FROM ${table}`).get();
      } catch (e: any) {
        const msg = String(e?.message || '');
        const code = (e && e.code) ? String(e.code) : '';
        if (code === 'SQLITE_CORRUPT_VTAB' || msg.includes('database disk image is malformed') || msg.includes('CORRUPT_VTAB')) {
          if (!this.maintenanceMode) {
            console.warn(
              `Detected corrupted virtual table ${table}, but repair is disabled outside RAH_DB_MAINTENANCE=true. Use explicit maintenance/rebuild flow.`
            );
            return;
          }
          console.warn(`Detected corrupted virtual table ${table} (${code || 'error'}). Recreating...`);
          try {
            this.db.exec(`DROP TABLE IF EXISTS ${table};`);
          } catch {}
          const dimensions = getEmbeddingProviderInfo().dimensions;
          const ddl = table === 'vec_nodes'
            ? `CREATE VIRTUAL TABLE vec_nodes USING vec0(node_id INTEGER PRIMARY KEY, embedding FLOAT[${dimensions}]);`
            : `CREATE VIRTUAL TABLE vec_chunks USING vec0(chunk_id INTEGER PRIMARY KEY, embedding FLOAT[${dimensions}]);`;
          try {
            this.db.exec(ddl);
            console.log(`Recreated ${table} virtual table`);
          } catch (re) {
            console.error(`Failed to recreate ${table}:`, re);
          }
        } else {
          // Other errors should bubble up normally
          // eslint-disable-next-line no-unsafe-finally
          throw e;
        }
      }
    };

    tryRead('vec_nodes');
    tryRead('vec_chunks');
  }

  private ensureFtsTables(): void {
    if (this.readOnly) {
      return;
    }

    try {
      const ensureFts = (
        tableName: 'nodes_fts' | 'chunks_fts',
        createSql: string,
        triggerSql: string,
        rebuildSql: string,
        isStale: (sql: string) => boolean,
      ) => {
        const existing = this.db.prepare("SELECT sql FROM sqlite_master WHERE type='table' AND name=?").get(tableName) as { sql?: string } | undefined;
        const existingSql = (existing?.sql || '').toLowerCase().replace(/\s+/g, ' ').trim();
        const missing = !existingSql;
        const stale = !missing && isStale(existingSql);

        if (missing) {
          this.db.exec(createSql);
          this.db.exec(rebuildSql);
        } else if (stale) {
          console.warn(
            `[SQLiteFTS] ${tableName} schema is stale. Skipping destructive startup rebuild; use the offline repair/rebuild path instead.`
          );
        }

        this.db.exec(triggerSql);
      };

      ensureFts(
        'nodes_fts',
        "CREATE VIRTUAL TABLE nodes_fts USING fts5(title, source, description, content='nodes', content_rowid='id');",
        `
          DROP TRIGGER IF EXISTS nodes_fts_ai;
          DROP TRIGGER IF EXISTS nodes_fts_ad;
          DROP TRIGGER IF EXISTS nodes_fts_au;
          CREATE TRIGGER nodes_fts_ai AFTER INSERT ON nodes BEGIN
            INSERT INTO nodes_fts(rowid, title, source, description)
            VALUES (new.id, new.title, new.source, new.description);
          END;
          CREATE TRIGGER nodes_fts_ad AFTER DELETE ON nodes BEGIN
            INSERT INTO nodes_fts(nodes_fts, rowid, title, source, description)
            VALUES('delete', old.id, old.title, old.source, old.description);
          END;
          CREATE TRIGGER nodes_fts_au AFTER UPDATE OF title, source, description ON nodes BEGIN
            INSERT INTO nodes_fts(nodes_fts, rowid, title, source, description)
            VALUES('delete', old.id, old.title, old.source, old.description);
            INSERT INTO nodes_fts(rowid, title, source, description)
            VALUES (new.id, new.title, new.source, new.description);
          END;
        `,
        "INSERT INTO nodes_fts(nodes_fts) VALUES('rebuild');",
        (sql) =>
          !/\bfts5\(\s*title\s*,\s*source\s*,\s*description\b/.test(sql) ||
          !sql.includes("content='nodes'") ||
          !sql.includes("content_rowid='id'") ||
          /\bnotes\b/.test(sql) ||
          /\btitle\s*,\s*content\b/.test(sql),
      );

      ensureFts(
        'chunks_fts',
        "CREATE VIRTUAL TABLE chunks_fts USING fts5(text, content='chunks', content_rowid='id');",
        `
          DROP TRIGGER IF EXISTS chunks_fts_ai;
          DROP TRIGGER IF EXISTS chunks_fts_ad;
          DROP TRIGGER IF EXISTS chunks_fts_au;
          CREATE TRIGGER chunks_fts_ai AFTER INSERT ON chunks BEGIN
            INSERT INTO chunks_fts(rowid, text)
            VALUES (new.id, new.text);
          END;
          CREATE TRIGGER chunks_fts_ad AFTER DELETE ON chunks BEGIN
            INSERT INTO chunks_fts(chunks_fts, rowid, text)
            VALUES('delete', old.id, old.text);
          END;
          CREATE TRIGGER chunks_fts_au AFTER UPDATE OF text ON chunks BEGIN
            INSERT INTO chunks_fts(chunks_fts, rowid, text)
            VALUES('delete', old.id, old.text);
            INSERT INTO chunks_fts(rowid, text)
            VALUES (new.id, new.text);
          END;
        `,
        "INSERT INTO chunks_fts(chunks_fts) VALUES('rebuild');",
        (sql) =>
          !/\bfts5\(\s*text\b/.test(sql) ||
          !sql.includes("content='chunks'") ||
          !sql.includes("content_rowid='id'"),
      );
    } catch (error) {
      console.warn('Failed to ensure FTS tables:', error);
    }
  }

  private buildProbeError(error: unknown): IntegrityProbeResult {
    const message = error instanceof Error ? error.message : String(error);
    const code =
      typeof error === 'object' &&
      error !== null &&
      'code' in error &&
      typeof (error as { code?: unknown }).code === 'string'
        ? String((error as { code: string }).code)
        : undefined;

    return { ok: false, error: message, code };
  }

  private runIntegrityProbe(fn: () => void): IntegrityProbeResult {
    try {
      fn();
      return { ok: true };
    } catch (error) {
      return this.buildProbeError(error);
    }
  }

  private refreshIntegrityReportForCorruptionError(error: unknown): void {
    const message = error instanceof Error ? error.message : String(error);
    const code =
      typeof error === 'object' &&
      error !== null &&
      'code' in error &&
      typeof (error as { code?: unknown }).code === 'string'
        ? String((error as { code: string }).code)
        : '';

    if (
      code.includes('CORRUPT') ||
      message.includes('database disk image is malformed') ||
      message.includes('SQLITE_CORRUPT')
    ) {
      this.getIntegrityReport(true);
    }
  }

  private inspectIntegrity(): DatabaseIntegrityReport {
    const connected = this.runIntegrityProbe(() => {
      this.db.prepare('SELECT 1').get();
    }).ok;

    const quickCheck = this.runIntegrityProbe(() => {
      const rows = this.db.prepare('PRAGMA quick_check').pluck().all() as string[];
      if (!(rows.length === 1 && rows[0] === 'ok')) {
        throw new Error(rows.join('\n') || 'quick_check failed');
      }
    });

    const integrityCheck = this.runIntegrityProbe(() => {
      const rows = this.db.prepare('PRAGMA integrity_check').pluck().all() as string[];
      if (!(rows.length === 1 && rows[0] === 'ok')) {
        throw new Error(rows.join('\n') || 'integrity_check failed');
      }
    });

    const baseTables: Record<'nodes' | 'edges' | 'chunks', IntegrityProbeResult> = {
      nodes: this.runIntegrityProbe(() => {
        this.db.prepare('SELECT COUNT(*) FROM nodes').pluck().get();
      }),
      edges: this.runIntegrityProbe(() => {
        this.db.prepare('SELECT COUNT(*) FROM edges').pluck().get();
      }),
      chunks: this.runIntegrityProbe(() => {
        this.db.prepare('SELECT COUNT(*) FROM chunks').pluck().get();
      }),
    };

    const hasTable = (name: string) =>
      Boolean(this.db.prepare("SELECT 1 FROM sqlite_master WHERE type='table' AND name=?").get(name));

    const ftsSchemaExists: Record<FtsSurfaceName, boolean> = {
      nodes: hasTable('nodes_fts'),
      chunks: hasTable('chunks_fts'),
    };

    const ftsProbeResults: Record<FtsSurfaceName, IntegrityProbeResult> = {
      nodes: ftsSchemaExists.nodes
        ? this.runIntegrityProbe(() => {
            this.db.prepare('SELECT COUNT(*) FROM nodes_fts').pluck().get();
          })
        : { ok: false, error: 'nodes_fts missing' },
      chunks: ftsSchemaExists.chunks
        ? this.runIntegrityProbe(() => {
            this.db.prepare('SELECT COUNT(*) FROM chunks_fts').pluck().get();
          })
        : { ok: false, error: 'chunks_fts missing' },
    };

    const ftsTables = {
      nodes: ftsSchemaExists.nodes && ftsProbeResults.nodes.ok,
      chunks: ftsSchemaExists.chunks && ftsProbeResults.chunks.ok,
    };

    let foreignKeyViolations = -1;
    if (baseTables.nodes.ok && baseTables.edges.ok) {
      const foreignKeyProbe = this.runIntegrityProbe(() => {
        foreignKeyViolations = Number(
          (this.db.prepare('SELECT COUNT(*) FROM pragma_foreign_key_check').pluck().get() as number | undefined) ?? 0
        );
      });
      if (!foreignKeyProbe.ok) {
        foreignKeyViolations = -1;
      }
    }

    const lostAndFoundExists = hasTable('lost_and_found');
    const vecTables = {
      nodes: hasTable('vec_nodes'),
      chunks: hasTable('vec_chunks'),
    };

    const baseTablesReadable = Object.values(baseTables).every(probe => probe.ok);
    const repairableFtsTables = (Object.entries(ftsProbeResults) as Array<[FtsSurfaceName, IntegrityProbeResult]>)
      .filter(([name, probe]) => ftsSchemaExists[name] && !probe.ok)
      .map(([name]) => name);

    let state: DatabaseIntegrityReport['state'] = 'healthy';
    if (!quickCheck.ok || !integrityCheck.ok) {
      state = baseTablesReadable && repairableFtsTables.length > 0 ? 'degraded_fts' : 'corrupt';
    } else if (!baseTablesReadable) {
      state = 'corrupt';
    } else if (repairableFtsTables.length > 0) {
      state = 'degraded_fts';
    }

    let summary = 'Database integrity checks passed.';
    if (state === 'degraded_fts') {
      summary = `Rebuildable FTS surfaces are degraded: ${repairableFtsTables.join(', ')}. Base tables are still readable.`;
    } else if (state === 'corrupt') {
      summary = 'Canonical database integrity checks are failing. Treat the database as corrupted.';
    }

    const firstError =
      quickCheck.error ||
      integrityCheck.error ||
      Object.values(baseTables).find(probe => !probe.ok)?.error ||
      Object.values(ftsProbeResults).find(probe => !probe.ok)?.error;

    return {
      state,
      connected,
      quickCheck,
      integrityCheck,
      baseTables,
      ftsTables,
      ftsProbeResults,
      repairableFtsTables,
      canRepairFts: state === 'degraded_fts' && repairableFtsTables.length > 0,
      foreignKeyViolations,
      lostAndFoundExists,
      vecTables,
      summary,
      error: firstError,
    };
  }

  public getEmbeddingProfileStatus(): EmbeddingProfileStatus {
    const embedding = getEmbeddingProviderInfo();
    const active = {
      profile: embedding.profile,
      model: embedding.model,
      dimensions: embedding.dimensions,
      vector_backend: getVectorBackendType(),
    };

    const stored = this.db.prepare(`
      SELECT profile, model, dimensions, vector_backend, updated_at
      FROM embedding_profile_state
      WHERE id = 1
    `).get() as EmbeddingProfileStatus['stored'] | undefined;

    const nodes = this.countVectorRows('vec_nodes');
    const chunks = this.countVectorRows('vec_chunks');
    const hasVectors = nodes > 0 || chunks > 0;

    let rebuildRequired = false;
    let reason: string | undefined;

    if (!stored && hasVectors) {
      rebuildRequired = true;
      reason = 'Existing vectors do not have recorded provider/model/dimension metadata.';
    } else if (stored) {
      const mismatches = [
        stored.profile !== active.profile ? `profile ${stored.profile} -> ${active.profile}` : '',
        stored.model !== active.model ? `model ${stored.model} -> ${active.model}` : '',
        Number(stored.dimensions) !== active.dimensions ? `dimensions ${stored.dimensions} -> ${active.dimensions}` : '',
        stored.vector_backend !== active.vector_backend ? `backend ${stored.vector_backend} -> ${active.vector_backend}` : '',
      ].filter(Boolean);

      if (mismatches.length > 0) {
        rebuildRequired = hasVectors;
        reason = `Embedding/vector profile changed (${mismatches.join(', ')}). Rebuild embeddings before semantic search.`;
      }
    }

    return {
      active,
      stored: stored || null,
      vectors: { nodes, chunks },
      rebuild_required: rebuildRequired,
      reason,
    };
  }

  public markEmbeddingProfileCurrent(): void {
    if (this.readOnly) return;
    const embedding = getEmbeddingProviderInfo();
    this.db.prepare(`
      INSERT INTO embedding_profile_state (id, profile, model, dimensions, vector_backend, updated_at)
      VALUES (1, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        profile = excluded.profile,
        model = excluded.model,
        dimensions = excluded.dimensions,
        vector_backend = excluded.vector_backend,
        updated_at = excluded.updated_at
    `).run(
      embedding.profile,
      embedding.model,
      embedding.dimensions,
      getVectorBackendType(),
      new Date().toISOString()
    );
  }

  private countVectorRows(tableName: VectorTableName): number {
    try {
      const exists = this.db.prepare("SELECT 1 FROM sqlite_master WHERE type='table' AND name=?").get(tableName);
      if (!exists) return 0;
      const row = this.db.prepare(`SELECT COUNT(*) AS count FROM ${tableName}`).get() as { count?: number } | undefined;
      return Number(row?.count ?? 0);
    } catch {
      return 0;
    }
  }

  public getIntegrityReport(forceRefresh = false): DatabaseIntegrityReport {
    if (!this.integrityReport || forceRefresh) {
      this.integrityReport = this.inspectIntegrity();
    }
    return this.integrityReport;
  }

  public canUseFtsTable(tableName: FtsSurfaceName): boolean {
    return this.getIntegrityReport().ftsTables[tableName];
  }

  private handleError(error: any): DatabaseError {
    return {
      message: error.message || 'SQLite operation failed',
      code: error.code || 'SQLITE_ERROR',
      details: error
    };
  }

  public close(): void {
    this.db.close();
  }
}

// Export singleton instance (similar to PostgreSQL client interface)
export const sqliteDb = SQLiteClient.getInstance();

// Export function to get client instance
export const getSQLiteClient = () => sqliteDb;

// Export class for testing
export { SQLiteClient };
