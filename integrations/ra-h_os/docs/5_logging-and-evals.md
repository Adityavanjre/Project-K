# Logging & Evals

## Logging System

RA-H uses a **trigger-based logging system** that automatically captures all database activity in the `logs` table.

### What Gets Logged

**Automatically logged via triggers:**
- **Node operations** - Create, update (via `trg_nodes_ai`, `trg_nodes_au`)
- **Edge operations** - Create, update (via `trg_edges_ai`, `trg_edges_au`)
- **Chat operations** - All conversations with token/cost metadata (via `trg_chats_ai`)

**Log structure:**
```typescript
{
  id: number,
  ts: timestamp,
  table_name: 'nodes' | 'edges' | 'chats',
  action: 'INSERT' | 'UPDATE',
  row_id: number,
  summary: string,              // Human-readable description
  snapshot_json: string,         // Full row data as JSON
  enriched_summary: string | null // Enhanced log entry
}
```

### Chat Metadata

Every chat log includes detailed execution metadata. `helper-interactions.log` is the raw event stream; `chats.metadata` is the persisted summary used for audits and UI inspection.

```typescript
metadata: {
  // Token tracking
  input_tokens: number,
  output_tokens: number,
  total_tokens: number,
  cache_write_tokens?: number,
  cache_read_tokens?: number,
  
  // Cost tracking
  estimated_cost_usd: number,
  model_used: string,
  provider: 'anthropic' | 'openai',
  
  // Tool usage
  tools_used?: string[],         // Unique tool names used in the chat
  tool_calls_count?: number,     // Total tool invocations
  tool_calls?: Array<{
    toolName: string,
    args: unknown,
    result: unknown
  }>,
  
  // Workflow tracking
  workflow_key?: string,
  workflow_node_id?: number,
  
  // Execution trace
  session_id?: string,
  trace_id?: string,
  parent_chat_id?: number
}
```

### Auto-Pruning

**Trigger:** `trg_logs_prune`  
**Behavior:** Keeps last 10,000 log entries  
**Runs:** After every INSERT to logs table

This prevents infinite database growth while preserving recent activity history.

### Enriched Logs View

**View:** `logs_v`  
**Purpose:** Joins log entries with related data for readable activity feed

**Enrichment:**
- Node logs → show node title
- Edge logs → show from/to node titles
- Chat logs → show agent name, user/assistant message previews

## Settings Panel Visibility

**Location:** Settings → Logs tab

**Features:**
- **Real-time activity feed** - Shows last 100 log entries
- **Table filtering** - Filter by nodes/edges/chats
- **Action filtering** - Filter by INSERT/UPDATE
- **Detailed view** - Click to see full snapshot_json
- **Token/cost visibility** - Chat logs show usage and costs
- **Tool usage** - See both the tool set used and full per-call payloads when captured

**Query:**
```sql
SELECT * FROM logs_v 
ORDER BY ts DESC 
LIMIT 100
```

## Cost Tracking

**Automatic cost calculation:**
- Every chat records token counts from LLM response
- Cost computed using model-specific pricing
- Stored in `chats.metadata.cost` (USD)
- Aggregated in Settings → Analytics

**Model pricing (current defaults):**
- GPT-5.4 Mini: $0.75/1M input, $0.075/1M cached input, $4.50/1M output
- GPT-5.4: $2.50/1M input, $0.25/1M cached input, $15.00/1M output
- GPT-5 Mini: $0.25/1M input, $0.025/1M cached input, $2.00/1M output
- GPT-5: $1.25/1M input, $0.125/1M cached input, $10.00/1M output
- GPT-4o Mini: $0.15/1M input, $0.60/1M output
- Claude Sonnet 4.5: $3.00/1M input, $15.00/1M output

**Typical costs:** Vary by prompt size, tool activity, and provider cache hits.

## Token Analytics

**Settings → Analytics panel shows:**
- Total tokens used (all time)
- Total cost (USD)
- Breakdown by helper
- Breakdown by conversation thread
- Average cost per chat

**Query:**
```sql
SELECT 
  helper_name,
  COUNT(*) as chat_count,
  SUM(JSON_EXTRACT(metadata, '$.total_tokens')) as total_tokens,
  SUM(JSON_EXTRACT(metadata, '$.estimated_cost_usd')) as total_cost
FROM chats
WHERE metadata IS NOT NULL
GROUP BY helper_name
```

## Evals Dashboard

The generic Settings -> Logs panel is useful for quick inspection, but it is not the primary trace-review surface.

For proper evals, use:
- `logs/evals.sqlite` as the dev-only trace store
- `/evals` as the main review UI

This evals path stores:
- one `llm_chats` row per traced interaction
- one `tool_calls` row per tool execution
- shared `trace_id` values so chat/tool steps can be reviewed together
- both synthetic scenarios and live app interactions when eval logging is enabled

### How To Run

Start the app with eval logging enabled:

```bash
npm run dev:evals
```

Then:
- use the app normally for live traces
- open [http://localhost:3000/evals](http://localhost:3000/evals)

To run the scenario suite against the local app:

```bash
npm run evals
```

Requirements:
- the dev server must already be running with eval logging enabled via `npm run dev:evals`
- the scenario runner targets `http://localhost:3000` by default
- the runner now waits up to 60s per scenario by default because current real latencies often exceed 10s

Optional overrides:

```bash
RAH_EVALS_BASE_URL=http://localhost:3001 npm run evals
RAH_EVALS_TIMEOUT_MS=90000 npm run evals
```

The `/evals` UI lets you review:
- live runs vs scenario runs
- full system message
- user/assistant turn
- tool spans with args/results
- latency
- token and cost data
- cache fields
- timing breakdown fields when available

### Why This Is Separate From The Logs Table

`logs` in the main SQLite database is trigger-based change logging. It mirrors a compact snapshot of chat rows, nodes, and edges.

`logs/evals.sqlite` is the trace store for evaluation and review. It is the correct place to inspect:
- per-trace chat rows
- per-tool spans
- scenario IDs
- live-vs-scenario separation

If you want to understand one interaction deeply, prefer `/evals` over Settings -> Logs.
