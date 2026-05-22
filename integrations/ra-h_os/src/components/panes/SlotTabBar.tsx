"use client";

import { useEffect, useRef, useState, useCallback } from 'react';
import { X, LayoutList, Map, FileText, Table2, BookOpen } from 'lucide-react';
import type { SlotTab, PaneType, SlotId } from './types';

const TAB_TYPE_ICONS: Record<PaneType, typeof LayoutList> = {
  views: LayoutList,
  map: Map,
  node: FileText,
  table: Table2,
  skills: BookOpen,
};

const TAB_TYPE_LABELS: Record<PaneType, string> = {
  views: 'Feed',
  map: 'Map',
  node: 'Node',
  table: 'Table',
  skills: 'Skills',
};

interface SlotTabBarProps {
  tabs: SlotTab[];
  activeTabId: string;
  slot: SlotId;
  onTabSelect: (tabId: string) => void;
  onTabClose: (tabId: string) => void;
  onReorderTabs?: (fromIndex: number, toIndex: number) => void;
  onCrossSlotDrop?: (tab: SlotTab, fromSlot: SlotId) => void;
}

function truncateTitle(title: string, maxLength = 18): string {
  if (title.length <= maxLength) return title;
  return `${title.slice(0, maxLength - 1)}\u2026`;
}

export default function SlotTabBar({
  tabs,
  activeTabId,
  slot,
  onTabSelect,
  onTabClose,
  onReorderTabs,
  onCrossSlotDrop,
}: SlotTabBarProps) {
  const [nodeTitles, setNodeTitles] = useState<Record<string, string>>({});
  const fetchedRef = useRef<Set<string>>(new Set());
  const [dragOverIndex, setDragOverIndex] = useState<number | null>(null);

  useEffect(() => {
    const nodeTabs = tabs.filter((tab) => tab.type === 'node' && tab.nodeId != null);
    for (const tab of nodeTabs) {
      if (fetchedRef.current.has(tab.id)) continue;
      fetchedRef.current.add(tab.id);

      fetch(`/api/nodes/${tab.nodeId}`)
        .then((response) => (response.ok ? response.json() : null))
        .then((payload) => {
          if (payload?.success && payload.node) {
            setNodeTitles((prev) => ({ ...prev, [tab.id]: payload.node.title || 'Untitled' }));
          }
        })
        .catch(() => {
          fetchedRef.current.delete(tab.id);
        });
    }
  }, [tabs]);

  useEffect(() => {
    const currentIds = new Set(tabs.map((tab) => tab.id));
    fetchedRef.current.forEach((id) => {
      if (!currentIds.has(id)) {
        fetchedRef.current.delete(id);
      }
    });
  }, [tabs]);

  const handleDragStart = useCallback((event: React.DragEvent, index: number, tab: SlotTab) => {
    event.dataTransfer.setData(
      'application/x-rah-tab',
      JSON.stringify({
        sourceSlot: slot,
        sourceIndex: index,
        tab,
      })
    );
    event.dataTransfer.effectAllowed = 'move';
  }, [slot]);

  const handleDrop = useCallback((event: React.DragEvent, targetIndex: number) => {
    event.preventDefault();
    setDragOverIndex(null);

    const raw = event.dataTransfer.getData('application/x-rah-tab');
    if (!raw) return;

    try {
      const parsed = JSON.parse(raw) as {
        sourceSlot: SlotId;
        sourceIndex: number;
        tab: SlotTab;
      };

      if (parsed.sourceSlot === slot) {
        onReorderTabs?.(parsed.sourceIndex, targetIndex);
        return;
      }

      onCrossSlotDrop?.(parsed.tab, parsed.sourceSlot);
    } catch {
      // Ignore malformed drag payloads.
    }
  }, [onCrossSlotDrop, onReorderTabs, slot]);

  const handleBarDrop = useCallback((event: React.DragEvent) => {
    event.preventDefault();
    setDragOverIndex(null);

    const raw = event.dataTransfer.getData('application/x-rah-tab');
    if (!raw) return;

    try {
      const parsed = JSON.parse(raw) as {
        sourceSlot: SlotId;
        tab: SlotTab;
      };

      if (parsed.sourceSlot !== slot) {
        onCrossSlotDrop?.(parsed.tab, parsed.sourceSlot);
      }
    } catch {
      // Ignore malformed drag payloads.
    }
  }, [onCrossSlotDrop, slot]);

  if (tabs.length === 0) return null;

  return (
    <div
      onDragOver={(event) => {
        if (event.dataTransfer.types.includes('application/x-rah-tab')) {
          event.preventDefault();
          event.dataTransfer.dropEffect = 'move';
        }
      }}
      onDrop={handleBarDrop}
      style={{ display: 'flex', alignItems: 'center', gap: '4px', minWidth: 0, overflow: 'hidden' }}
    >
      {tabs.map((tab, index) => {
        const isActive = tab.id === activeTabId;
        const Icon = TAB_TYPE_ICONS[tab.type];
        const label = tab.type === 'node'
          ? truncateTitle(nodeTitles[tab.id] || 'Loading...')
          : TAB_TYPE_LABELS[tab.type];
        const isDragOver = dragOverIndex === index;

        return (
          <div
            key={tab.id}
            draggable={tab.type === 'node'}
            onDragStart={(event) => handleDragStart(event, index, tab)}
            onDragOver={(event) => {
              if (!event.dataTransfer.types.includes('application/x-rah-tab')) return;
              event.preventDefault();
              setDragOverIndex(index);
            }}
            onDragLeave={() => setDragOverIndex(null)}
            onDrop={(event) => handleDrop(event, index)}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              minWidth: 0,
              padding: '6px 10px',
              borderRadius: '10px',
              border: isDragOver ? '1px dashed var(--rah-accent-green)' : '1px solid var(--rah-border)',
              background: isActive ? 'var(--rah-bg-hover)' : 'var(--rah-bg-panel)',
              color: isActive ? 'var(--rah-text-primary)' : 'var(--rah-text-secondary)',
              cursor: tab.type === 'node' ? 'grab' : 'pointer',
            }}
          >
            <button
              type="button"
              onClick={() => onTabSelect(tab.id)}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '6px',
                minWidth: 0,
                background: 'transparent',
                border: 'none',
                color: 'inherit',
                cursor: 'pointer',
                padding: 0,
              }}
            >
              <Icon size={14} />
              <span style={{ fontSize: '12px', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                {label}
              </span>
            </button>

            {tabs.length > 1 ? (
              <button
                type="button"
                onClick={() => onTabClose(tab.id)}
                style={{
                  width: '16px',
                  height: '16px',
                  border: 'none',
                  borderRadius: '999px',
                  background: 'transparent',
                  color: 'inherit',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  cursor: 'pointer',
                  padding: 0,
                  flexShrink: 0,
                }}
              >
                <X size={12} />
              </button>
            ) : null}
          </div>
        );
      })}
    </div>
  );
}
