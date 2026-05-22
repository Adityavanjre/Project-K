import Database from 'better-sqlite3';
import fs from 'fs';
import path from 'path';
import { randomUUID } from 'crypto';
import { RequestContext } from '@/services/context/requestContext';

type EvalToolCallLog = {
  toolName: string;
  args?: unknown;
  result?: unknown;
  error?: unknown;
  latencyMs?: number;
};

type EvalChatLog = {
  traceId?: string;
  spanId?: string;
  helperName?: string;
  model?: string;
  promptVersion?: string;
  systemMessage?: string | null;
  userMessage?: string | null;
  assistantMessage?: string | null;
  inputTokens?: number;
  outputTokens?: number;
  totalTokens?: number;
  cacheWriteTokens?: number;
  cacheReadTokens?: number;
  cacheHit?: boolean;
  cacheSavingsPct?: number;
  estimatedCostUsd?: number;
  provider?: string | null;
  mode?: string | null;
  workflowKey?: string | null;
  workflowNodeId?: number | null;
  latencyMs?: number;
  firstChunkLatencyMs?: number | null;
  firstTokenLatencyMs?: number | null;
  promptBuildMs?: number | null;
  toolsBuildMs?: number | null;
  modelResolveMs?: number | null;
  messageAssemblyMs?: number | null;
  streamSetupMs?: number | null;
  toolLoopMs?: number | null;
  toolsUsed?: string[] | null;
  toolCallsCount?: number | null;
  success?: boolean;
  error?: string | null;
};

const EVALS_LOG_FLAG = process.env.RAH_EVALS_LOG;
const EVALS_LOG_ENABLED = EVALS_LOG_FLAG === '1' || EVALS_LOG_FLAG === 'true';
const LOG_DIR = path.join(process.cwd(), 'logs');
const DB_PATH = path.join(LOG_DIR, 'evals.sqlite');

let evalsDb: Database.Database | null = null;

function shouldLogEvals() {
  // Log ALL interactions when RAH_EVALS_LOG=1
  // - Real app interactions: scenario_id will be NULL
  // - Synthetic scenarios: scenario_id will be set
  return EVALS_LOG_ENABLED;
}

function ensureSchema(db: Database.Database) {
  db.exec(`
    CREATE TABLE IF NOT EXISTS tool_calls (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      ts TEXT NOT NULL,
      trace_id TEXT,
      span_id TEXT,
      parent_span_id TEXT,
      helper_name TEXT,
      tool_name TEXT NOT NULL,
      args_json TEXT,
      result_json TEXT,
      success INTEGER,
      latency_ms INTEGER,
      error TEXT,
      dataset_id TEXT,
      scenario_id TEXT
    );
    CREATE INDEX IF NOT EXISTS idx_tool_calls_trace ON tool_calls(trace_id);
    CREATE INDEX IF NOT EXISTS idx_tool_calls_scenario ON tool_calls(scenario_id);
  `);

  db.exec(`
    CREATE TABLE IF NOT EXISTS llm_chats (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      ts TEXT NOT NULL,
      trace_id TEXT,
      span_id TEXT,
      helper_name TEXT,
      model TEXT,
      prompt_version TEXT,
      system_message TEXT,
      user_message TEXT,
      assistant_message TEXT,
      input_tokens INTEGER,
      output_tokens INTEGER,
      total_tokens INTEGER,
      cache_write_tokens INTEGER,
      cache_read_tokens INTEGER,
      cache_hit INTEGER,
      cache_savings_pct INTEGER,
      estimated_cost_usd REAL,
      provider TEXT,
      mode TEXT,
      workflow_key TEXT,
      workflow_node_id INTEGER,
      latency_ms INTEGER,
      first_chunk_latency_ms INTEGER,
      first_token_latency_ms INTEGER,
      prompt_build_ms INTEGER,
      tools_build_ms INTEGER,
      model_resolve_ms INTEGER,
      message_assembly_ms INTEGER,
      stream_setup_ms INTEGER,
      tool_loop_ms INTEGER,
      tools_used_json TEXT,
      tool_calls_count INTEGER,
      success INTEGER,
      error TEXT,
      dataset_id TEXT,
      scenario_id TEXT
    );
    CREATE INDEX IF NOT EXISTS idx_llm_chats_trace ON llm_chats(trace_id);
    CREATE INDEX IF NOT EXISTS idx_llm_chats_scenario ON llm_chats(scenario_id);
  `);

  const columns = db.prepare(`PRAGMA table_info(llm_chats);`).all() as { name: string }[];
  const columnNames = new Set(columns.map(column => column.name));
  if (!columnNames.has('system_message')) {
    db.exec(`ALTER TABLE llm_chats ADD COLUMN system_message TEXT;`);
  }
  if (!columnNames.has('cache_write_tokens')) {
    db.exec(`ALTER TABLE llm_chats ADD COLUMN cache_write_tokens INTEGER;`);
  }
  if (!columnNames.has('cache_read_tokens')) {
    db.exec(`ALTER TABLE llm_chats ADD COLUMN cache_read_tokens INTEGER;`);
  }
  if (!columnNames.has('cache_hit')) {
    db.exec(`ALTER TABLE llm_chats ADD COLUMN cache_hit INTEGER;`);
  }
  if (!columnNames.has('cache_savings_pct')) {
    db.exec(`ALTER TABLE llm_chats ADD COLUMN cache_savings_pct INTEGER;`);
  }
  if (!columnNames.has('estimated_cost_usd')) {
    db.exec(`ALTER TABLE llm_chats ADD COLUMN estimated_cost_usd REAL;`);
  }
  if (!columnNames.has('provider')) {
    db.exec(`ALTER TABLE llm_chats ADD COLUMN provider TEXT;`);
  }
  if (!columnNames.has('mode')) {
    db.exec(`ALTER TABLE llm_chats ADD COLUMN mode TEXT;`);
  }
  if (!columnNames.has('workflow_key')) {
    db.exec(`ALTER TABLE llm_chats ADD COLUMN workflow_key TEXT;`);
  }
  if (!columnNames.has('workflow_node_id')) {
    db.exec(`ALTER TABLE llm_chats ADD COLUMN workflow_node_id INTEGER;`);
  }
  if (!columnNames.has('first_chunk_latency_ms')) {
    db.exec(`ALTER TABLE llm_chats ADD COLUMN first_chunk_latency_ms INTEGER;`);
  }
  if (!columnNames.has('first_token_latency_ms')) {
    db.exec(`ALTER TABLE llm_chats ADD COLUMN first_token_latency_ms INTEGER;`);
  }
  if (!columnNames.has('prompt_build_ms')) {
    db.exec(`ALTER TABLE llm_chats ADD COLUMN prompt_build_ms INTEGER;`);
  }
  if (!columnNames.has('tools_build_ms')) {
    db.exec(`ALTER TABLE llm_chats ADD COLUMN tools_build_ms INTEGER;`);
  }
  if (!columnNames.has('model_resolve_ms')) {
    db.exec(`ALTER TABLE llm_chats ADD COLUMN model_resolve_ms INTEGER;`);
  }
  if (!columnNames.has('message_assembly_ms')) {
    db.exec(`ALTER TABLE llm_chats ADD COLUMN message_assembly_ms INTEGER;`);
  }
  if (!columnNames.has('stream_setup_ms')) {
    db.exec(`ALTER TABLE llm_chats ADD COLUMN stream_setup_ms INTEGER;`);
  }
  if (!columnNames.has('tool_loop_ms')) {
    db.exec(`ALTER TABLE llm_chats ADD COLUMN tool_loop_ms INTEGER;`);
  }
  if (!columnNames.has('tools_used_json')) {
    db.exec(`ALTER TABLE llm_chats ADD COLUMN tools_used_json TEXT;`);
  }
  if (!columnNames.has('tool_calls_count')) {
    db.exec(`ALTER TABLE llm_chats ADD COLUMN tool_calls_count INTEGER;`);
  }
}

function getDb() {
  if (!EVALS_LOG_ENABLED) return null;
  if (evalsDb) return evalsDb;

  fs.mkdirSync(LOG_DIR, { recursive: true });
  evalsDb = new Database(DB_PATH);
  evalsDb.pragma('journal_mode = WAL');
  evalsDb.pragma('synchronous = NORMAL');
  evalsDb.pragma('busy_timeout = 3000');
  ensureSchema(evalsDb);
  return evalsDb;
}

function stringifySafe(value: unknown) {
  if (value === undefined) return null;
  try {
    return JSON.stringify(value);
  } catch (error) {
    return JSON.stringify({
      error: 'Failed to serialize payload',
      message: error instanceof Error ? error.message : String(error),
    });
  }
}

export function logEvalToolCall(entry: EvalToolCallLog) {
  if (!shouldLogEvals()) return;
  const context = RequestContext.get();
  const traceId = context.traceId;
  if (!traceId) return;

  const db = getDb();
  if (!db) return;

  const now = new Date().toISOString();
  const spanId = randomUUID();
  const parentSpanId = context.evalChatSpanId || null;
  const helperName = context.helperName || null;
  const datasetId = context.evalDatasetId || null;
  const scenarioId = context.evalScenarioId || null;
  const errorMessage = entry.error instanceof Error
    ? entry.error.message
    : entry.error
      ? String(entry.error)
      : null;
  const success = typeof entry.error === 'undefined'
    ? entry.result && typeof (entry.result as any).success === 'boolean'
      ? ((entry.result as any).success ? 1 : 0)
      : 1
    : 0;

  db.prepare(`
    INSERT INTO tool_calls (
      ts, trace_id, span_id, parent_span_id, helper_name,
      tool_name, args_json, result_json, success, latency_ms, error,
      dataset_id, scenario_id
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `).run(
    now,
    traceId,
    spanId,
    parentSpanId,
    helperName,
    entry.toolName,
    stringifySafe(entry.args),
    stringifySafe(entry.result),
    success,
    entry.latencyMs ?? null,
    errorMessage,
    datasetId,
    scenarioId
  );
}

export function logEvalChat(entry: EvalChatLog) {
  if (!shouldLogEvals()) return;
  const context = RequestContext.get();
  const traceId = entry.traceId || context.traceId;
  if (!traceId) return;

  const db = getDb();
  if (!db) return;

  const now = new Date().toISOString();
  const spanId = entry.spanId || context.evalChatSpanId || randomUUID();
  const datasetId = context.evalDatasetId || null;
  const scenarioId = context.evalScenarioId || null;

  db.prepare(`
    INSERT INTO llm_chats (
      ts, trace_id, span_id, helper_name, model, prompt_version, system_message,
      user_message, assistant_message, input_tokens, output_tokens, total_tokens,
      cache_write_tokens, cache_read_tokens, cache_hit, cache_savings_pct,
      estimated_cost_usd, provider, mode, workflow_key, workflow_node_id,
      latency_ms, first_chunk_latency_ms, first_token_latency_ms,
      prompt_build_ms, tools_build_ms, model_resolve_ms, message_assembly_ms,
      stream_setup_ms, tool_loop_ms, tools_used_json, tool_calls_count,
      success, error, dataset_id, scenario_id
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `).run(
    now,
    traceId,
    spanId,
    entry.helperName ?? null,
    entry.model ?? null,
    entry.promptVersion ?? null,
    entry.systemMessage ?? null,
    entry.userMessage ?? null,
    entry.assistantMessage ?? null,
    entry.inputTokens ?? null,
    entry.outputTokens ?? null,
    entry.totalTokens ?? null,
    entry.cacheWriteTokens ?? null,
    entry.cacheReadTokens ?? null,
    typeof entry.cacheHit === 'boolean' ? (entry.cacheHit ? 1 : 0) : null,
    entry.cacheSavingsPct ?? null,
    entry.estimatedCostUsd ?? null,
    entry.provider ?? null,
    entry.mode ?? null,
    entry.workflowKey ?? null,
    entry.workflowNodeId ?? null,
    entry.latencyMs ?? null,
    entry.firstChunkLatencyMs ?? null,
    entry.firstTokenLatencyMs ?? null,
    entry.promptBuildMs ?? null,
    entry.toolsBuildMs ?? null,
    entry.modelResolveMs ?? null,
    entry.messageAssemblyMs ?? null,
    entry.streamSetupMs ?? null,
    entry.toolLoopMs ?? null,
    stringifySafe(entry.toolsUsed ?? null),
    entry.toolCallsCount ?? null,
    typeof entry.success === 'boolean' ? (entry.success ? 1 : 0) : null,
    entry.error ?? null,
    datasetId,
    scenarioId
  );
}
