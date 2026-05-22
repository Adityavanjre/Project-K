"use client";

import { useCallback, useEffect, useMemo, useState, type CSSProperties } from 'react';

interface McpStatus {
  enabled: boolean;
  url: string | null;
  port: number | null;
  last_updated?: string | null;
  target_base_url?: string | null;
  last_error?: string | null;
  error?: string | null;
}

const initialStatus: McpStatus = {
  enabled: false,
  url: null,
  port: null
};

export default function ExternalAgentsPanel() {
  const [status, setStatus] = useState<McpStatus>(initialStatus);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [copyState, setCopyState] = useState<'idle' | 'copied'>('idle');

  useEffect(() => {
    const fetchStatus = async () => {
      try {
        setLoading(true);
        const response = await fetch('/api/system/mcp-status');
        const data = await response.json();
        setStatus(data);
        setError(null);
      } catch (err) {
        console.error('Failed to load MCP status', err);
        setError('MCP server not running. See docs/8_mcp.md for setup instructions.');
        setStatus(initialStatus);
      } finally {
        setLoading(false);
      }
    };

    fetchStatus();
    const timer = setInterval(fetchStatus, 5000);
    return () => clearInterval(timer);
  }, []);

  const connectorUrl = useMemo(() => {
    if (status?.url) return status.url;
    if (status?.port) return `http://127.0.0.1:${status.port}/mcp`;
    return null;
  }, [status]);

  const handleCopy = useCallback(async () => {
    if (!connectorUrl) return;
    try {
      await navigator.clipboard.writeText(connectorUrl);
      setCopyState('copied');
      setTimeout(() => setCopyState('idle'), 2000);
    } catch (err) {
      console.error('Copy failed', err);
    }
  }, [connectorUrl]);

  return (
    <div style={containerStyle}>
      <p style={descStyle}>
        Connect Claude, ChatGPT, Gemini, or any MCP-compatible assistant to your local RA-H database.
        Everything stays on device. External tools only talk to the local MCP connector you expose here.
      </p>

      <div style={cardStyle}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div>
            <div style={labelStyle}>Connector URL</div>
            <div style={{ ...statusTextStyle, color: connectorUrl ? 'var(--settings-text)' : 'var(--settings-muted)' }}>
              {loading ? 'Loading…' : connectorUrl ?? 'Unavailable (MCP server not running)'}
            </div>
            {status.last_updated && (
              <div style={microcopyStyle}>
                Updated {new Date(status.last_updated).toLocaleTimeString()}
              </div>
            )}
          </div>
          <button
            type="button"
            onClick={handleCopy}
            disabled={!connectorUrl}
            style={{
              ...buttonStyle,
              cursor: connectorUrl ? 'pointer' : 'not-allowed',
              opacity: connectorUrl ? 1 : 0.4,
            }}
          >
            {copyState === 'copied' ? 'Copied' : 'Copy URL'}
          </button>
        </div>
        {status.last_error && (
          <div style={{ ...helperTextStyle, color: 'var(--settings-danger)', marginTop: 12 }}>
            {status.last_error}
          </div>
        )}
      </div>

      <div style={cardStyle}>
        <div style={labelStyle}>How to use in Claude or ChatGPT</div>
        <ol style={stepsStyle}>
          <li>Open the MCP / connectors settings in your assistant.</li>
          <li>Select “Add connector” → choose HTTP → paste the URL above.</li>
          <li>Give the connector a friendly name (e.g., “RA-H”).</li>
          <li>Ask naturally: “Add this summary to RA-H” or “Search RA-H for my Apollo notes”.</li>
        </ol>
      </div>

      <div style={cardStyle}>
        <div style={helperTextStyle}>
          External agents can edit your local graph. Only enable trusted connectors and monitor their output.
          Disconnect the connector or close RA-H if anything unexpected happens.
        </div>
      </div>

      {error && (
        <div style={{ ...helperTextStyle, color: 'var(--settings-danger)', marginBottom: 16 }}>{error}</div>
      )}

      <div style={{ display: 'grid', gap: '16px' }}>
        <HelperCard
          title="Add to RA-H"
          body={`"Summarize our meeting and add it to RA-H. If a context is obvious, use it. If not, leave context blank."`}
        />
        <HelperCard
          title="Search RA-H"
          body={`"Search RA-H for what I previously wrote about the Apollo launch delays."`}
        />
        <HelperCard
          title="Check nodes before writing"
          body={`"Before adding anything new, call rah.search_nodes to see if the note already exists."`}
        />
      </div>
    </div>
  );
}

function HelperCard({ title, body }: { title: string; body: string }) {
  return (
    <div style={helperCardStyle}>
      <div style={helperCardTitleStyle}>{title}</div>
      <div style={helperCardBodyStyle}>{body}</div>
    </div>
  );
}

const containerStyle: CSSProperties = {
  padding: 24,
  height: '100%',
  overflow: 'auto',
};

const descStyle: CSSProperties = {
  fontSize: 13,
  color: 'var(--settings-muted)',
  marginBottom: 20,
  lineHeight: 1.5,
};

const cardStyle: CSSProperties = {
  background: 'var(--settings-card-bg)',
  border: '1px solid var(--settings-border)',
  borderRadius: 8,
  padding: 16,
  marginBottom: 16,
};

const labelStyle: CSSProperties = {
  fontSize: 12,
  fontWeight: 500,
  color: 'var(--settings-text)',
  marginBottom: 8,
};

const statusTextStyle: CSSProperties = {
  fontSize: 13,
  marginTop: 4,
};

const microcopyStyle: CSSProperties = {
  fontSize: 11,
  color: 'var(--settings-muted)',
  marginTop: 6,
};

const buttonStyle: CSSProperties = {
  padding: '10px 16px',
  background: 'transparent',
  color: 'var(--settings-text)',
  border: '1px solid var(--settings-border-strong)',
  borderRadius: 6,
  fontSize: 12,
  fontWeight: 500,
};

const stepsStyle: CSSProperties = {
  paddingLeft: 20,
  lineHeight: 1.6,
  color: 'var(--settings-subtext)',
  fontSize: 13,
  margin: 0,
};

const helperTextStyle: CSSProperties = {
  fontSize: 12,
  color: 'var(--settings-subtext)',
  lineHeight: 1.5,
};

const helperCardStyle: CSSProperties = {
  border: '1px solid var(--settings-border)',
  borderRadius: 8,
  padding: 14,
  background: 'var(--settings-card-bg)',
};

const helperCardTitleStyle: CSSProperties = {
  fontWeight: 600,
  marginBottom: 6,
  color: 'var(--settings-text)',
  fontSize: 13,
};

const helperCardBodyStyle: CSSProperties = {
  color: 'var(--settings-subtext)',
  fontSize: 13,
  lineHeight: 1.5,
};
