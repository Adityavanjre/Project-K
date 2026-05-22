export interface LogEntry {
  id: number;
  ts: string;
  table_name: string;
  action: string;
  row_id: number;
  summary: string | null;
  snapshot_json: string | null;
  enriched_summary: string | null;
}

export interface LogsResponse {
  logs: LogEntry[];
  page: number;
  limit: number;
  threadId?: string;
  traceId?: string;
  table?: string;
}
