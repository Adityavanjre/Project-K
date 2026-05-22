"use client";

import { useState } from 'react';
import { LogEntry } from '@/types/logs';

interface LogsRowProps {
  log: LogEntry;
  isEven: boolean;
}

interface SnapshotMetrics {
  thread?: string;
  trace_id?: string;
  input_tokens?: number;
  output_tokens?: number;
  cost_usd?: number;
  cache_hit?: number;
  latency_ms?: number;
  first_token_latency_ms?: number;
  first_chunk_latency_ms?: number;
  prompt_build_ms?: number;
  tools_build_ms?: number;
  model_resolve_ms?: number;
  message_assembly_ms?: number;
  stream_setup_ms?: number;
  tool_loop_ms?: number;
  tools_count?: number;
  tools_used?: string[];
  tool_timings?: Array<{ toolName?: string; durationMs?: number }>;
  model?: string;
  system_message?: string;
}

export default function LogsRow({ log, isEven }: LogsRowProps) {
  const [expanded, setExpanded] = useState(false);

  const formatTimestamp = (ts: string) => {
    const date = new Date(ts);
    return date.toISOString().replace('T', ' ').substring(0, 19);
  };

  const formatJson = (jsonStr: string | null) => {
    if (!jsonStr) return 'null';
    try {
      const parsed = JSON.parse(jsonStr);
      return JSON.stringify(parsed, null, 2);
    } catch {
      return jsonStr;
    }
  };

  const highlightJson = (jsonStr: string) => {
    return jsonStr
      .replace(/"([^"]+)":/g, '<span style="color: #60a5fa">"$1"</span>:')
      .replace(/: "([^"]*)"/g, ': <span style="color: #34d399">"$1"</span>')
      .replace(/: (\d+)/g, ': <span style="color: #fb923c">$1</span>')
      .replace(/: (true|false|null)/g, ': <span style="color: #a78bfa">$1</span>');
  };

  const getMetricsFromSnapshot = (): SnapshotMetrics | null => {
    if (!log.snapshot_json || log.table_name !== 'chats') return null;
    try {
      const snapshot = JSON.parse(log.snapshot_json);
      return {
        thread: snapshot.thread,
        trace_id: snapshot.trace_id,
        input_tokens: snapshot.input_tokens,
        output_tokens: snapshot.output_tokens,
        cost_usd: snapshot.cost_usd,
        cache_hit: snapshot.cache_hit,
        latency_ms: snapshot.latency_ms,
        first_token_latency_ms: snapshot.first_token_latency_ms,
        first_chunk_latency_ms: snapshot.first_chunk_latency_ms,
        prompt_build_ms: snapshot.prompt_build_ms,
        tools_build_ms: snapshot.tools_build_ms,
        model_resolve_ms: snapshot.model_resolve_ms,
        message_assembly_ms: snapshot.message_assembly_ms,
        stream_setup_ms: snapshot.stream_setup_ms,
        tool_loop_ms: snapshot.tool_loop_ms,
        tools_count: snapshot.tools_count,
        tools_used: snapshot.tools_used,
        tool_timings: snapshot.tool_timings,
        model: snapshot.model,
        system_message: snapshot.system_message
      };
    } catch {
      return null;
    }
  };

  const metrics = getMetricsFromSnapshot();
  const metricsSafe: SnapshotMetrics = metrics ?? {};

  return (
    <>
      <tr
        onClick={() => setExpanded(!expanded)}
        style={{
          background: isEven ? 'var(--rah-bg-surface)' : 'var(--rah-bg-panel)',
          cursor: 'pointer',
          borderBottom: '1px solid var(--rah-border-strong)'
        }}
        onMouseEnter={(e) => {
          e.currentTarget.style.background = 'var(--rah-bg-active)';
        }}
        onMouseLeave={(e) => {
          e.currentTarget.style.background = isEven ? 'var(--rah-bg-surface)' : 'var(--rah-bg-panel)';
        }}
      >
        <td style={{ padding: '12px 16px', fontSize: '12px', fontFamily: 'JetBrains Mono, monospace', width: '60px' }}>
          {log.id}
        </td>
        <td style={{ padding: '12px 16px', fontSize: '12px', fontFamily: 'JetBrains Mono, monospace', width: '180px' }}>
          {formatTimestamp(log.ts)}
        </td>
        <td style={{ padding: '12px 16px', fontSize: '12px', fontFamily: 'JetBrains Mono, monospace', width: '100px' }}>
          {log.table_name}
        </td>
        <td style={{ padding: '12px 16px', fontSize: '12px', fontFamily: 'JetBrains Mono, monospace', width: '80px' }}>
          {log.action}
        </td>
        <td style={{ padding: '12px 16px', fontSize: '12px', fontFamily: 'JetBrains Mono, monospace' }}>
          <div>{log.summary || '-'}</div>
          {metrics && (
            <div style={{ marginTop: '6px', fontSize: '10px', color: 'var(--rah-text-muted)', display: 'flex', gap: '12px', flexWrap: 'wrap' }}>
              {metrics.trace_id && (
                <span title={`Trace: ${metrics.trace_id}`}>
                  🔗 {metrics.trace_id.substring(0, 8)}
                </span>
              )}
              {metrics.thread && (
                <span title={`Thread: ${metrics.thread}`}>
                  🧵 {metrics.thread.substring(0, 16)}…
                </span>
              )}
              {metrics.input_tokens !== undefined && metrics.output_tokens !== undefined && (
                <span>
                  📊 {metrics.input_tokens}↓ {metrics.output_tokens}↑
                </span>
              )}
              {metrics.latency_ms !== undefined && metrics.latency_ms > 0 && (
                <span>
                  ⏱ {metrics.latency_ms}ms
                </span>
              )}
              {metrics.first_token_latency_ms !== undefined && metrics.first_token_latency_ms > 0 && (
                <span>
                  ⚡ {metrics.first_token_latency_ms}ms first
                </span>
              )}
              {metrics.first_chunk_latency_ms !== undefined && metrics.first_chunk_latency_ms > 0 && (
                <span>
                  ⌁ {metrics.first_chunk_latency_ms}ms chunk
                </span>
              )}
              {metrics.tools_count !== undefined && metrics.tools_count > 0 && (
                <span>
                  🛠 {metrics.tools_count} tools
                </span>
              )}
              {metrics.cache_hit !== undefined && metrics.cache_hit === 1 && (
                <span style={{ color: '#60a5fa' }}>
                  ⚡ Cache Hit
                </span>
              )}
            </div>
          )}
        </td>
        <td style={{ padding: '12px 16px', fontSize: '12px', fontFamily: 'JetBrains Mono, monospace', width: '80px' }}>
          {log.row_id}
        </td>
      </tr>
      {expanded && (
        <tr style={{ background: 'var(--rah-bg-base)', borderTop: '1px solid var(--rah-border-stronger)', borderBottom: '1px solid var(--rah-border-stronger)' }}>
          <td colSpan={6} style={{ padding: '16px 24px' }}>
            {metrics?.system_message && (
              <div style={{ marginBottom: '16px' }}>
                <div style={{ fontSize: '11px', color: 'var(--rah-text-muted)', marginBottom: '8px', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                  System Message
                </div>
                <pre
                  style={{
                    fontSize: '10px',
                    fontFamily: 'JetBrains Mono, monospace',
                    lineHeight: '1.5',
                    whiteSpace: 'pre-wrap',
                    wordBreak: 'break-word',
                    margin: 0,
                    color: '#60a5fa',
                    background: 'var(--rah-bg-surface)',
                    padding: '12px',
                    borderRadius: '4px',
                    border: '1px solid var(--rah-bg-active)',
                    maxHeight: '300px',
                    overflow: 'auto'
                  }}
                >
                  {metrics.system_message}
                </pre>
              </div>
            )}
            <div style={{ marginBottom: '12px' }}>
              {((metrics?.prompt_build_ms ?? 0) > 0 ||
                (metrics?.tools_build_ms ?? 0) > 0 ||
                (metrics?.model_resolve_ms ?? 0) > 0 ||
                (metrics?.message_assembly_ms ?? 0) > 0 ||
                (metrics?.stream_setup_ms ?? 0) > 0 ||
                (metrics?.tool_loop_ms ?? 0) > 0) && (
                <div style={{ marginBottom: '16px' }}>
                  <div style={{ fontSize: '11px', color: 'var(--rah-text-muted)', marginBottom: '8px', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                    Latency Breakdown
                  </div>
                  <div style={{ fontSize: '11px', color: 'var(--rah-text-secondary)', display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
                    {(metricsSafe.prompt_build_ms ?? 0) > 0 && <span>prompt {metricsSafe.prompt_build_ms}ms</span>}
                    {(metricsSafe.tools_build_ms ?? 0) > 0 && <span>tools {metricsSafe.tools_build_ms}ms</span>}
                    {(metricsSafe.model_resolve_ms ?? 0) > 0 && <span>model {metricsSafe.model_resolve_ms}ms</span>}
                    {(metricsSafe.message_assembly_ms ?? 0) > 0 && <span>messages {metricsSafe.message_assembly_ms}ms</span>}
                    {(metricsSafe.stream_setup_ms ?? 0) > 0 && <span>stream {metricsSafe.stream_setup_ms}ms</span>}
                    {(metricsSafe.tool_loop_ms ?? 0) > 0 && <span>tool-loop {metricsSafe.tool_loop_ms}ms</span>}
                    {(metricsSafe.first_chunk_latency_ms ?? 0) > 0 && <span>first-chunk {metricsSafe.first_chunk_latency_ms}ms</span>}
                    {(metricsSafe.first_token_latency_ms ?? 0) > 0 && <span>first-token {metricsSafe.first_token_latency_ms}ms</span>}
                  </div>
                </div>
              )}
              {Array.isArray(metrics?.tool_timings) && metrics.tool_timings.length > 0 && (
                <div style={{ marginBottom: '16px' }}>
                  <div style={{ fontSize: '11px', color: 'var(--rah-text-muted)', marginBottom: '8px', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                    Tool Timings
                  </div>
                  <div style={{ fontSize: '11px', color: 'var(--rah-text-secondary)', display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
                    {metrics.tool_timings.map((tool: any, index: number) => (
                      <span key={`${tool.toolName || 'tool'}-${index}`}>
                        {tool.toolName || 'tool'} {tool.durationMs ?? 0}ms
                      </span>
                    ))}
                  </div>
                </div>
              )}
              {Array.isArray(metrics?.tools_used) && metrics.tools_used.length > 0 && (
                <div style={{ marginBottom: '16px' }}>
                  <div style={{ fontSize: '11px', color: 'var(--rah-text-muted)', marginBottom: '8px', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                    Tools Used
                  </div>
                  <div style={{ fontSize: '11px', color: 'var(--rah-text-secondary)' }}>
                    {metrics.tools_used.join(', ')}
                  </div>
                </div>
              )}
              <div style={{ fontSize: '11px', color: 'var(--rah-text-muted)', marginBottom: '8px', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                Snapshot JSON
              </div>
              <pre
                style={{
                  fontSize: '11px',
                  fontFamily: 'JetBrains Mono, monospace',
                  lineHeight: '1.6',
                  whiteSpace: 'pre-wrap',
                  wordBreak: 'break-all',
                  margin: 0
                }}
                dangerouslySetInnerHTML={{ __html: highlightJson(formatJson(log.snapshot_json)) }}
              />
            </div>
            {log.enriched_summary && (
              <div>
                <div style={{ fontSize: '11px', color: 'var(--rah-text-muted)', marginBottom: '8px', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                  Enriched Summary
                </div>
                <div style={{ fontSize: '12px', color: 'var(--rah-text-secondary)', lineHeight: '1.6' }}>
                  {log.enriched_summary}
                </div>
              </div>
            )}
          </td>
        </tr>
      )}
    </>
  );
}
