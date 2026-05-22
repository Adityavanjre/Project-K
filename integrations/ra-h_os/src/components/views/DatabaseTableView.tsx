"use client";

import { useEffect, useState, useRef, useCallback } from 'react';
import { createPortal } from 'react-dom';
import { ChevronDown, X, ArrowUpDown, Search, Check } from 'lucide-react';
import type { Node } from '@/types/database';
import { formatRelativeDate } from '@/utils/formatDate';
import { getNodeProcessedState } from '@/services/nodes/metadata';

type SortOrder = 'updated' | 'edges' | 'created' | 'event_date';

const SORT_LABELS: Record<SortOrder, string> = {
  updated: 'Recently Updated',
  edges: 'Most Connections',
  created: 'Creation Date',
  event_date: 'Event Date',
};

const FETCH_LIMIT = 2000;
const ROW_HEIGHT = 52;
const OVERSCAN = 10;

interface DatabaseTableViewProps {
  onNodeClick: (nodeId: number) => void;
  refreshToken?: number;
  toolbarHost?: HTMLDivElement | null;
}

function getSourceSignal(node: Node): string {
  if (node.link) {
    return node.link.replace(/^https?:\/\/(www\.)?/, '');
  }

  if (node.source) {
    return node.source.replace(/\s+/g, ' ').trim().slice(0, 120);
  }

  return '—';
}

export default function DatabaseTableView({ onNodeClick, refreshToken = 0, toolbarHost }: DatabaseTableViewProps) {
  const [nodes, setNodes] = useState<Node[]>([]);
  const [loading, setLoading] = useState(true);
  const [sortOrder, setSortOrder] = useState<SortOrder>('updated');
  const [searchQuery, setSearchQuery] = useState('');
  const [activeSearch, setActiveSearch] = useState('');
  const [showSortDropdown, setShowSortDropdown] = useState(false);
  const [hoveredRow, setHoveredRow] = useState<number | null>(null);
  const [scrollTop, setScrollTop] = useState(0);
  const [viewportHeight, setViewportHeight] = useState(480);

  const sortDropdownRef = useRef<HTMLDivElement>(null);
  const listRef = useRef<HTMLDivElement>(null);

  const fetchNodes = useCallback(async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams({
        limit: String(FETCH_LIMIT),
        offset: '0',
        sortBy: sortOrder,
      });
      if (activeSearch) {
        params.set('search', activeSearch);
      }

      const res = await fetch(`/api/nodes?${params}`);
      const data = await res.json();
      if (data.success) {
        setNodes(data.data || []);
      } else {
        setNodes([]);
      }
    } catch (error) {
      console.error('Error fetching nodes:', error);
      setNodes([]);
    } finally {
      setLoading(false);
    }
  }, [activeSearch, sortOrder]);

  useEffect(() => {
    fetchNodes();
  }, [fetchNodes, refreshToken]);

  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (showSortDropdown && sortDropdownRef.current && !sortDropdownRef.current.contains(e.target as HTMLElement)) {
        setShowSortDropdown(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, [showSortDropdown]);

  useEffect(() => {
    const node = listRef.current;
    if (!node) return;

    const updateHeight = () => {
      setViewportHeight(node.clientHeight);
    };

    updateHeight();
    const observer = new ResizeObserver(updateHeight);
    observer.observe(node);
    return () => observer.disconnect();
  }, []);

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setActiveSearch(searchQuery);
  };

  const totalRows = nodes.length;
  const startIndex = Math.max(0, Math.floor(scrollTop / ROW_HEIGHT) - OVERSCAN);
  const visibleCount = Math.ceil(viewportHeight / ROW_HEIGHT) + OVERSCAN * 2;
  const endIndex = Math.min(totalRows, startIndex + visibleCount);
  const visibleRows = nodes.slice(startIndex, endIndex);
  const topSpacer = startIndex * ROW_HEIGHT;
  const bottomSpacer = Math.max(0, (totalRows - endIndex) * ROW_HEIGHT);

  const toolbar = (
    <div style={{ width: '100%', display: 'flex', alignItems: 'center', gap: '8px', minWidth: 0 }}>
      <form onSubmit={handleSearchSubmit} style={{ display: 'flex', alignItems: 'center', gap: '0' }}>
        <div style={{ display: 'flex', alignItems: 'center', background: 'var(--rah-bg-base)', border: '1px solid var(--rah-border)', borderRadius: '8px', padding: '0 8px', gap: '6px' }}>
          <Search size={12} style={{ color: 'var(--rah-text-muted)', flexShrink: 0 }} />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search nodes..."
            style={{
              background: 'transparent',
              border: 'none',
              color: 'var(--rah-text-active)',
              fontSize: '12px',
              padding: '7px 0',
              outline: 'none',
              width: '160px',
            }}
          />
          {activeSearch && (
            <button
              type="button"
              onClick={() => {
                setSearchQuery('');
                setActiveSearch('');
              }}
              style={{ background: 'transparent', border: 'none', color: 'var(--rah-text-muted)', cursor: 'pointer', padding: 0, display: 'flex' }}
            >
              <X size={11} />
            </button>
          )}
        </div>
      </form>

      <div style={{ flex: 1 }} />

      <div style={{ position: 'relative' }} ref={sortDropdownRef}>
        <button
          onClick={() => setShowSortDropdown((prev) => !prev)}
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '4px',
            padding: '6px 8px',
            background: 'transparent',
            border: '1px solid var(--rah-border)',
            borderRadius: '8px',
            color: 'var(--rah-text-soft)',
            fontSize: '11px',
            cursor: 'pointer',
            whiteSpace: 'nowrap',
          }}
        >
          <ArrowUpDown size={11} />
          {SORT_LABELS[sortOrder]}
          <ChevronDown size={10} />
        </button>

        {showSortDropdown && (
          <div
            style={{
              position: 'absolute',
              top: '100%',
              right: 0,
              marginTop: '6px',
              background: 'var(--rah-bg-panel)',
              border: '1px solid var(--rah-border)',
              borderRadius: '12px',
              padding: '4px',
              minWidth: '180px',
              zIndex: 1000,
              boxShadow: '0 8px 24px rgba(0,0,0,0.4)',
            }}
          >
            {(Object.keys(SORT_LABELS) as SortOrder[]).map((key) => (
              <button
                key={key}
                onClick={() => {
                  setSortOrder(key);
                  setShowSortDropdown(false);
                }}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '8px',
                  width: '100%',
                  padding: '8px 10px',
                  background: sortOrder === key ? 'rgba(255,255,255,0.04)' : 'transparent',
                  border: 'none',
                  borderRadius: '8px',
                  color: sortOrder === key ? 'var(--rah-text-active)' : 'var(--rah-text-soft)',
                  fontSize: '12px',
                  cursor: 'pointer',
                  textAlign: 'left',
                }}
              >
                {sortOrder === key && <span style={{ color: 'var(--rah-accent-green)', fontSize: '12px' }}>✓</span>}
                {SORT_LABELS[key]}
              </button>
            ))}
          </div>
        )}
      </div>

      <div style={{ fontSize: '11px', color: 'var(--rah-text-muted)', whiteSpace: 'nowrap' }}>
        {loading ? 'Loading…' : `${nodes.length} nodes`}
      </div>
    </div>
  );

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%', background: 'transparent' }}>
      {toolbarHost ? createPortal(toolbar, toolbarHost) : (
        <div style={{ padding: '8px 12px', borderBottom: '1px solid var(--rah-border)', display: 'flex', alignItems: 'center', gap: '8px' }}>
          {toolbar}
        </div>
      )}

      <div style={{ padding: '0 12px 12px', display: 'flex', flexDirection: 'column', minHeight: 0, flex: 1 }}>
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: '40px minmax(240px, 2fr) 72px 140px 64px minmax(220px, 1.3fr) 110px minmax(180px, 1fr)',
            gap: '12px',
            alignItems: 'center',
            minHeight: '38px',
            borderBottom: '1px solid var(--rah-border)',
            color: 'var(--rah-text-muted)',
            fontSize: '10px',
            fontWeight: 600,
            letterSpacing: '0.08em',
            textTransform: 'uppercase',
            padding: '0 8px',
            flexShrink: 0,
          }}
        >
          <span>✓</span>
          <span>Title</span>
          <span>ID</span>
          <span>Context</span>
          <span>Edges</span>
          <span>Description</span>
          <span>Updated</span>
          <span>Source</span>
        </div>

        <div
          ref={listRef}
          onScroll={(e) => setScrollTop(e.currentTarget.scrollTop)}
          style={{ flex: 1, minHeight: 0, overflow: 'auto' }}
        >
          {loading ? (
            <div style={{ padding: '40px', color: 'var(--rah-text-muted)', textAlign: 'center', fontSize: '13px' }}>Loading...</div>
          ) : nodes.length === 0 ? (
            <div style={{ padding: '40px', color: 'var(--rah-text-muted)', textAlign: 'center', fontSize: '13px' }}>
              {activeSearch ? 'No nodes match your search.' : 'No nodes yet.'}
            </div>
          ) : (
            <div style={{ paddingTop: `${topSpacer}px`, paddingBottom: `${bottomSpacer}px` }}>
              {visibleRows.map((node) => {
                const processed = getNodeProcessedState(node.metadata) === 'processed';
                const sourceSignal = getSourceSignal(node);
                const description = node.description?.replace(/\s+/g, ' ').trim() || '—';

                return (
                  <button
                    key={node.id}
                    type="button"
                    onClick={() => onNodeClick(node.id)}
                    onMouseEnter={() => setHoveredRow(node.id)}
                    onMouseLeave={() => setHoveredRow(null)}
                    style={{
                      width: '100%',
                      height: `${ROW_HEIGHT}px`,
                      display: 'grid',
                      gridTemplateColumns: '40px minmax(240px, 2fr) 72px 140px 64px minmax(220px, 1.3fr) 110px minmax(180px, 1fr)',
                      gap: '12px',
                      alignItems: 'center',
                      border: 'none',
                      borderBottom: '1px solid var(--rah-border)',
                      background: hoveredRow === node.id ? 'var(--rah-bg-panel)' : 'transparent',
                      color: 'inherit',
                      textAlign: 'left',
                      padding: '0 8px',
                      cursor: 'pointer',
                    }}
                  >
                    <span style={{ display: 'inline-flex', alignItems: 'center', justifyContent: 'center', color: processed ? 'var(--rah-accent-green)' : 'var(--rah-text-muted)' }}>
                      {processed ? <Check size={14} strokeWidth={3} /> : null}
                    </span>

                    <span style={{ display: 'flex', flexDirection: 'column', minWidth: 0 }}>
                      <span style={{ fontSize: '13px', color: 'var(--rah-text-base)', fontWeight: 500, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                        {node.title || 'Untitled'}
                      </span>
                    </span>

                    <span style={{ fontFamily: 'ui-monospace, SFMono-Regular, Menlo, monospace', fontSize: '11px', color: 'var(--rah-text-muted)' }}>
                      {node.id}
                    </span>

                    <span style={{ minWidth: 0, fontSize: '11px', color: 'var(--rah-text-muted)' }}>—</span>

                    <span style={{ fontSize: '12px', color: node.edge_count ? 'var(--rah-text-soft)' : 'var(--rah-text-muted)' }}>
                      {node.edge_count ?? 0}
                    </span>

                    <span style={{ fontSize: '11px', color: 'var(--rah-text-soft)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                      {description}
                    </span>

                    <span style={{ fontSize: '11px', color: 'var(--rah-text-muted)' }}>
                      {formatRelativeDate(node.updated_at)}
                    </span>

                    <span style={{ fontSize: '11px', color: sourceSignal === '—' ? 'var(--rah-text-muted)' : 'var(--rah-text-soft)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                      {sourceSignal}
                    </span>
                  </button>
                );
              })}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
