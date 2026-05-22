import Database from 'better-sqlite3';
import fs from 'fs';
import path from 'path';

export type EvalChatRow = {
  id: number;
  ts: string;
  trace_id: string;
  span_id: string | null;
  helper_name: string | null;
  model: string | null;
  prompt_version: string | null;
  system_message: string | null;
  user_message: string | null;
  assistant_message: string | null;
  input_tokens: number | null;
  output_tokens: number | null;
  total_tokens: number | null;
  cache_write_tokens: number | null;
  cache_read_tokens: number | null;
  cache_hit: number | null;
  cache_savings_pct: number | null;
  estimated_cost_usd: number | null;
  provider: string | null;
  mode: string | null;
  workflow_key: string | null;
  workflow_node_id: number | null;
  latency_ms: number | null;
  first_chunk_latency_ms: number | null;
  first_token_latency_ms: number | null;
  prompt_build_ms: number | null;
  tools_build_ms: number | null;
  model_resolve_ms: number | null;
  message_assembly_ms: number | null;
  stream_setup_ms: number | null;
  tool_loop_ms: number | null;
  tools_used_json: string | null;
  tool_calls_count: number | null;
  success: number | null;
  error: string | null;
  dataset_id: string | null;
  scenario_id: string | null;
};

export type EvalToolCallRow = {
  id: number;
  ts: string;
  trace_id: string;
  span_id: string | null;
  parent_span_id: string | null;
  helper_name: string | null;
  tool_name: string;
  args_json: string | null;
  result_json: string | null;
  success: number | null;
  latency_ms: number | null;
  error: string | null;
  dataset_id: string | null;
  scenario_id: string | null;
};

export type EvalTrace = {
  chat: EvalChatRow;
  toolCalls: EvalToolCallRow[];
  comment: string | null;
};

const LOG_DB_PATH = path.join(process.cwd(), 'logs', 'evals.sqlite');

function ensureCommentSchema(db: Database.Database) {
  db.exec(`
    CREATE TABLE IF NOT EXISTS eval_comments (
      trace_id TEXT PRIMARY KEY,
      scenario_id TEXT,
      comment TEXT,
      updated_at TEXT
    );
    CREATE INDEX IF NOT EXISTS idx_eval_comments_scenario ON eval_comments(scenario_id);
  `);
}

export function upsertEvalComment(traceId: string, scenarioId: string | null, comment: string) {
  if (!fs.existsSync(LOG_DB_PATH)) {
    return;
  }
  const db = new Database(LOG_DB_PATH);
  ensureCommentSchema(db);
  const now = new Date().toISOString();
  db.prepare(`
    INSERT INTO eval_comments (trace_id, scenario_id, comment, updated_at)
    VALUES (?, ?, ?, ?)
    ON CONFLICT(trace_id) DO UPDATE SET
      comment = excluded.comment,
      updated_at = excluded.updated_at,
      scenario_id = excluded.scenario_id
  `).run(traceId, scenarioId, comment, now);
}

export function loadEvalTraces(limit = 25): EvalTrace[] {
  if (!fs.existsSync(LOG_DB_PATH)) {
    return [];
  }

  const db = new Database(LOG_DB_PATH, { readonly: true, fileMustExist: true });
  const chats = db.prepare(`
    SELECT *
    FROM llm_chats
    ORDER BY ts DESC
    LIMIT ?
  `).all(limit) as EvalChatRow[];

  if (chats.length === 0) return [];

  const traceIds = Array.from(new Set(chats.map(chat => chat.trace_id)));
  const placeholders = traceIds.map(() => '?').join(', ');
  const toolCalls = db.prepare(`
    SELECT *
    FROM tool_calls
    WHERE trace_id IN (${placeholders})
    ORDER BY ts ASC
  `).all(...traceIds) as EvalToolCallRow[];

  const toolCallsByTrace = new Map<string, EvalToolCallRow[]>();
  toolCalls.forEach(call => {
    const list = toolCallsByTrace.get(call.trace_id) || [];
    list.push(call);
    toolCallsByTrace.set(call.trace_id, list);
  });

  const commentsByTrace = new Map<string, string | null>();
  if (placeholders.length > 0) {
    try {
      const commentRows = db.prepare(`
        SELECT trace_id, comment
        FROM eval_comments
        WHERE trace_id IN (${placeholders})
      `).all(...traceIds) as Array<{ trace_id: string; comment: string | null }>;
      commentRows.forEach(row => {
        commentsByTrace.set(row.trace_id, row.comment ?? null);
      });
    } catch {
      // Comments table doesn't exist yet in readonly mode.
    }
  }

  return chats.map(chat => ({
    chat,
    toolCalls: toolCallsByTrace.get(chat.trace_id) || [],
    comment: commentsByTrace.get(chat.trace_id) ?? null,
  }));
}
