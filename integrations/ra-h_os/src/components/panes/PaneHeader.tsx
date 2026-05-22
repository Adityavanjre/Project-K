"use client";

import { useState } from 'react';
import { GripVertical, X } from 'lucide-react';
import { PaneHeaderProps } from './types';

export default function PaneHeader({
  slot,
  onCollapse,
  onSwapPanes,
  tabBar,
  children,
  toolbarHostRef,
}: PaneHeaderProps) {
  const [isDragging, setIsDragging] = useState(false);
  const [isDragOver, setIsDragOver] = useState(false);

  const handleDragStart = (e: React.DragEvent) => {
    if (!slot) return;
    e.dataTransfer.setData('application/x-rah-pane', slot);
    e.dataTransfer.effectAllowed = 'move';
    setIsDragging(true);
  };

  const handleDragEnd = () => {
    setIsDragging(false);
  };

  const handleDragOver = (e: React.DragEvent) => {
    if (!e.dataTransfer.types.includes('application/x-rah-pane')) return;
    e.preventDefault();
    e.dataTransfer.dropEffect = 'move';
    setIsDragOver(true);
  };

  const handleDragLeave = () => {
    setIsDragOver(false);
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragOver(false);

    if (!slot) return;
    const sourceSlot = e.dataTransfer.getData('application/x-rah-pane');
    if (sourceSlot && sourceSlot !== slot && onSwapPanes) {
      onSwapPanes(sourceSlot as typeof slot, slot);
    }
  };

  return (
    <div
      onDragOver={handleDragOver}
      onDragLeave={handleDragLeave}
      onDrop={handleDrop}
      style={{
        display: 'flex',
        alignItems: 'center',
        gap: '10px',
        background: isDragOver ? 'rgba(34, 197, 94, 0.1)' : 'transparent',
        opacity: isDragging ? 0.5 : 1,
        borderRadius: isDragOver ? '6px' : '0',
        transition: 'background 0.15s ease, opacity 0.15s ease',
        padding: '8px 12px',
        minHeight: '48px',
      }}
    >
      {slot && onSwapPanes ? (
        <div
          draggable
          onDragStart={handleDragStart}
          onDragEnd={handleDragEnd}
          title="Drag to swap panes"
          style={{
            width: '28px',
            height: '28px',
            borderRadius: '8px',
            border: '1px solid var(--rah-border-strong)',
            background: isDragging ? 'var(--rah-bg-hover)' : 'var(--rah-bg-elevated)',
            color: isDragging ? 'var(--rah-text-soft)' : 'var(--rah-text-muted)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            cursor: 'grab',
            flexShrink: 0,
            transition: 'all 0.15s ease',
          }}
        >
          <GripVertical size={14} />
        </div>
      ) : null}

      <div style={{ flex: 1, display: 'flex', alignItems: 'center', gap: '8px', minWidth: 0 }}>
        {tabBar ? (
          <div style={{ display: 'flex', alignItems: 'center', gap: '4px', minWidth: 0 }}>
            {tabBar}
          </div>
        ) : null}
        {children ? (
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', minWidth: 0, flexWrap: 'wrap' }}>
            {children}
          </div>
        ) : null}
        {toolbarHostRef ? (
          <div
            ref={toolbarHostRef}
            style={{
              flex: 1,
              minWidth: 0,
              display: 'flex',
              alignItems: 'center',
            }}
          />
        ) : null}
        {!tabBar && !children && !toolbarHostRef ? (
          <div style={{ color: 'var(--rah-text-muted)', fontSize: '12px' }} />
        ) : null}
      </div>

      {/* Close button (when onCollapse is provided) */}
      {onCollapse && (
        <button
          onClick={onCollapse}
          style={{
            width: '32px',
            height: '32px',
            borderRadius: '8px',
            border: '1px solid var(--rah-border-stronger)',
            background: 'var(--rah-bg-elevated)',
            color: 'var(--rah-text-secondary)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            cursor: 'pointer',
            transition: 'all 0.15s ease',
            flexShrink: 0,
          }}
          title="Close pane"
          onMouseEnter={(e) => {
            e.currentTarget.style.background = 'rgba(127, 29, 29, 0.22)';
            e.currentTarget.style.borderColor = 'rgba(248, 113, 113, 0.5)';
            e.currentTarget.style.color = '#fca5a5';
          }}
          onMouseLeave={(e) => {
            e.currentTarget.style.background = 'var(--rah-bg-elevated)';
            e.currentTarget.style.borderColor = 'var(--rah-border-stronger)';
            e.currentTarget.style.color = 'var(--rah-text-secondary)';
          }}
        >
          <X size={15} strokeWidth={2.25} />
        </button>
      )}
    </div>
  );
}
