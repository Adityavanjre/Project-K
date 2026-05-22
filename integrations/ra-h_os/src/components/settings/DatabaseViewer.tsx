"use client";

import { useCallback, useEffect, useMemo, useState, type ChangeEvent } from 'react';
import { Link as LinkIcon } from 'lucide-react';
import { Node } from '@/types/database';
import { openExternalUrl } from '@/utils/openExternalUrl';

interface NodeWithMetrics extends Node {
  edge_count?: number;
}

interface AppliedFilters {
  search?: string;
  sortBy: 'updated' | 'edges';
}

const LIMIT = 50;

export default function DatabaseViewer() {
  const [nodes, setNodes] = useState<NodeWithMetrics[]>([]);
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [searchInput, setSearchInput] = useState('');
  const [sortBy, setSortBy] = useState<'updated' | 'edges'>('updated');
  const [appliedFilters, setAppliedFilters] = useState<AppliedFilters>({ sortBy: 'updated' });
  const [hubNodeIds, setHubNodeIds] = useState<Set<number>>(new Set());

  const filtersActive = useMemo(
    () => Boolean(appliedFilters.search),
    [appliedFilters]
  );

  const fetchNodes = useCallback(
    async (pageNumber: number, filters: AppliedFilters) => {
      setLoading(true);
      setError(null);
      try {
        const params = new URLSearchParams();
        params.set('limit', LIMIT.toString());
        params.set('offset', ((pageNumber - 1) * LIMIT).toString());
        params.set('sortBy', filters.sortBy);
        if (filters.search) params.set('search', filters.search);

        const response = await fetch(`/api/nodes?${params.toString()}`);
        if (!response.ok) {
          throw new Error('Failed to fetch nodes');
        }
        const data = await response.json();
        setNodes(data.data || []);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Unknown error');
        setNodes([]);
      } finally {
        setLoading(false);
      }
    },
    []
  );

  useEffect(() => {
    void fetchNodes(page, appliedFilters);
  }, [page, appliedFilters, fetchNodes]);

  useEffect(() => {
    const loadHubNodes = async () => {
      try {
        const response = await fetch('/api/nodes?sortBy=edges&limit=10');
        if (!response.ok) return;
        const payload = await response.json();
        const ids = new Set<number>((payload.data || []).map((node: Node) => node.id));
        setHubNodeIds(ids);
      } catch (err) {
        console.warn('Failed to load graph hubs', err);
      }
    };

    void loadHubNodes();
  }, []);

  const handleApplyFilters = () => {
    const payload: AppliedFilters = { sortBy };
    if (searchInput.trim()) payload.search = searchInput.trim();
    setAppliedFilters(payload);
    setPage(1);
  };

  const handleClearFilters = () => {
    setSearchInput('');
    setSortBy('updated');
    setAppliedFilters({ sortBy: 'updated' });
    setPage(1);
  };

  const handleSortChange = (event: ChangeEvent<HTMLSelectElement>) => {
    const value = event.target.value === 'edges' ? 'edges' : 'updated';
    setSortBy(value);
    setAppliedFilters((prev) => ({ ...prev, sortBy: value }));
  };

  const handlePrevious = () => {
    setPage((prev) => (prev > 1 ? prev - 1 : prev));
  };

  const handleNext = () => {
    if (nodes.length === LIMIT) {
      setPage((prev) => prev + 1);
    }
  };

  const isFirstPage = page === 1;
  const isLastPage = nodes.length < LIMIT;
  const filterStatus = filtersActive
    ? 'Filtered results'
    : `Showing ${(page - 1) * LIMIT + 1}-${(page - 1) * LIMIT + nodes.length}`;

  const formatTimestamp = (value?: string) => {
    if (!value) return '—';
    const date = new Date(value);
    return date.toLocaleString(undefined, {
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  const formatRelative = (value?: string) => {
    if (!value) return '';
    const diffMs = Date.now() - new Date(value).getTime();
    const diffMinutes = Math.round(diffMs / (1000 * 60));
    if (diffMinutes < 60) return `${diffMinutes}m ago`;
    const diffHours = Math.round(diffMinutes / 60);
    if (diffHours < 24) return `${diffHours}h ago`;
    const diffDays = Math.round(diffHours / 24);
    return `${diffDays}d ago`;
  };

  if (loading) {
    return <div style={{ padding: '40px', textAlign: 'center', color: '#888' }}>Loading database...</div>;
  }

  if (error) {
    return <div style={{ padding: '40px', textAlign: 'center', color: '#ef4444' }}>Error: {error}</div>;
  }

  if (nodes.length === 0) {
    return <div style={{ padding: '40px', textAlign: 'center', color: '#888' }}>No nodes found</div>;
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <div
        style={{
          padding: '16px 24px',
          borderBottom: '1px solid #2a2a2a',
          display: 'flex',
          flexDirection: 'column',
          gap: '12px',
        }}
      >
        <div style={{ display: 'flex', gap: '12px', flexWrap: 'wrap' }}>
          <label style={{ display: 'flex', flexDirection: 'column', fontSize: '11px', color: '#888', gap: '4px' }}>
            Search
            <input
              value={searchInput}
              onChange={(e) => setSearchInput(e.target.value)}
              placeholder="title or content"
              style={{
                background: '#0f0f0f',
                border: '1px solid #2a2a2a',
                color: '#ddd',
                padding: '6px 10px',
                borderRadius: '4px',
                minWidth: '220px',
              }}
            />
          </label>
          <label style={{ display: 'flex', flexDirection: 'column', fontSize: '11px', color: '#888', gap: '4px' }}>
            Sort by
            <select
              value={sortBy}
              onChange={handleSortChange}
              style={{
                background: '#0f0f0f',
                border: '1px solid #2a2a2a',
                color: '#ddd',
                padding: '6px 10px',
                borderRadius: '4px',
              }}
            >
              <option value="updated">Recently updated</option>
              <option value="edges">Most connected</option>
            </select>
          </label>
        </div>

        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div style={{ fontSize: '12px', color: '#666' }}>{filterStatus}</div>
          <div style={{ display: 'flex', gap: '8px' }}>
            <button
              onClick={handleApplyFilters}
              style={{
                padding: '8px 16px',
                background: '#22c55e33',
                border: '1px solid #22c55e66',
                borderRadius: '4px',
                color: '#22c55e',
                cursor: 'pointer',
                fontSize: '12px',
              }}
            >
              Apply
            </button>
            <button
              onClick={handleClearFilters}
              style={{
                padding: '8px 16px',
                background: '#1a1a1a',
                border: '1px solid #333',
                borderRadius: '4px',
                color: '#ccc',
                cursor: 'pointer',
                fontSize: '12px',
              }}
            >
              Clear
            </button>
            <button
              onClick={handlePrevious}
              disabled={isFirstPage || filtersActive}
              style={{
                padding: '8px 12px',
                background: isFirstPage || filtersActive ? '#1a1a1a' : '#2a2a2a',
                border: '1px solid #333',
                borderRadius: '4px',
                color: isFirstPage || filtersActive ? '#555' : '#ccc',
                cursor: isFirstPage || filtersActive ? 'not-allowed' : 'pointer',
                fontSize: '12px',
              }}
            >
              Previous
            </button>
            <button
              onClick={handleNext}
              disabled={isLastPage || filtersActive}
              style={{
                padding: '8px 12px',
                background: isLastPage || filtersActive ? '#1a1a1a' : '#2a2a2a',
                border: '1px solid #333',
                borderRadius: '4px',
                color: isLastPage || filtersActive ? '#555' : '#ccc',
                cursor: isLastPage || filtersActive ? 'not-allowed' : 'pointer',
                fontSize: '12px',
              }}
            >
              Next
            </button>
          </div>
        </div>
      </div>

      <div style={{ flex: 1, overflow: 'auto' }}>
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead style={{ position: 'sticky', top: 0, background: '#1a1a1a', zIndex: 1 }}>
            <tr>
              {['Node', 'Context', 'Edges', 'Highlights', 'Updated', 'Created'].map((column) => (
                <th
                  key={column}
                  style={{
                    padding: '12px 16px',
                    textAlign: 'left',
                    fontSize: '11px',
                    color: '#888',
                    textTransform: 'uppercase',
                    letterSpacing: '0.5px',
                    fontWeight: 'normal',
                    borderBottom: '1px solid #2a2a2a',
                  }}
                >
                  {column}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {nodes.map((node, index) => (
              <tr
                key={node.id}
                style={{
                  background: index % 2 === 0 ? '#080808' : '#0d0d0d',
                  borderBottom: '1px solid #111',
                }}
              >
                <td style={{ padding: '12px 16px', verticalAlign: 'top', width: '34%' }}>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
                    <div style={{ fontWeight: 600, color: '#f5f5f5', display: 'flex', alignItems: 'center', gap: '8px' }}>
                      {node.title || 'Untitled node'}
                      {node.link && (
                        <button
                          onClick={() => {
                            void openExternalUrl(node.link!).catch((openError) => {
                              console.error('[DatabaseViewer] Failed to open original link', openError);
                              window.alert(`Unable to open ${node.link}`);
                            });
                          }}
                          title="Open original link"
                          style={{
                            background: 'transparent',
                            border: 'none',
                            color: '#7de8a5',
                            cursor: 'pointer',
                            padding: 0,
                            display: 'flex',
                            alignItems: 'center',
                          }}
                        >
                          <LinkIcon size={14} />
                        </button>
                      )}
                    </div>
                    <span style={{ fontSize: '11px', color: '#666', fontFamily: 'JetBrains Mono, monospace' }}>ID: {node.id}</span>
                    {node.description && <span style={{ fontSize: '12px', color: '#9ca3af' }}>{node.description}</span>}
                  </div>
                </td>
                <td style={{ padding: '12px 16px', verticalAlign: 'top', width: '18%' }}>
                  <span style={{ fontSize: '11px', color: '#555' }}>—</span>
                </td>
                <td style={{ padding: '12px 16px', verticalAlign: 'top', width: '10%' }}>
                  <div style={{ fontWeight: 600, color: '#e2e8f0' }}>{node.edge_count ?? 0}</div>
                  <div style={{ fontSize: '11px', color: '#666' }}>connections</div>
                </td>
                <td style={{ padding: '12px 16px', verticalAlign: 'top', width: '14%' }}>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
                    {hubNodeIds.has(node.id) ? (
                      <span style={{ fontSize: '11px', color: '#facc15', fontWeight: 600 }}>Graph hub</span>
                    ) : (
                      <span style={{ fontSize: '11px', color: '#475569' }}>—</span>
                    )}
                    {node.metadata?.state && (
                      <span style={{ fontSize: '11px', color: '#7de8a5' }}>{String(node.metadata.state)}</span>
                    )}
                  </div>
                </td>
                <td style={{ padding: '12px 16px', verticalAlign: 'top', width: '12%' }}>
                  <div style={{ fontSize: '12px', color: '#e2e8f0' }}>{formatTimestamp(node.updated_at)}</div>
                  <div style={{ fontSize: '11px', color: '#666' }}>{formatRelative(node.updated_at)}</div>
                </td>
                <td style={{ padding: '12px 16px', verticalAlign: 'top', width: '12%' }}>
                  <div style={{ fontSize: '12px', color: '#cbd5f5' }}>{formatTimestamp(node.created_at)}</div>
                  <div style={{ fontSize: '11px', color: '#666' }}>{formatRelative(node.created_at)}</div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
