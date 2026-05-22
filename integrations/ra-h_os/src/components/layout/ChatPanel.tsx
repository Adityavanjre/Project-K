"use client";

import { MessageSquare, X } from 'lucide-react';
import type { ChatPanelProps } from '../panes/types';

export default function ChatPanel({
  isOpen,
  onClose,
  onOpen,
}: ChatPanelProps) {
  if (!isOpen) {
    return (
      <div
        style={{
          position: 'fixed',
          right: 20,
          bottom: 20,
          zIndex: 100,
        }}
      >
        <button
          onClick={onOpen}
          title="Open chat"
          style={{
            width: 48,
            height: 48,
            borderRadius: '50%',
            border: 'none',
            background: 'var(--rah-accent-green)',
            color: 'var(--rah-text-inverse)',
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            boxShadow: 'var(--rah-shadow-floating)',
          }}
        >
          <MessageSquare size={20} />
        </button>
      </div>
    );
  }

  return (
    <div
      style={{
        flex: 1,
        minWidth: 0,
        height: '100%',
        display: 'flex',
        flexDirection: 'column',
        background: 'var(--rah-bg-surface)',
        borderRadius: 10,
        overflow: 'hidden',
      }}
    >
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          padding: '10px 12px',
          borderBottom: '1px solid var(--rah-border)',
        }}
      >
        <span style={{ color: 'var(--rah-text-soft)', fontSize: 12, fontWeight: 500, letterSpacing: '0.05em' }}>
          Chat
        </span>
        <button
          onClick={onClose}
          title="Close chat"
          style={{
            width: 28,
            height: 28,
            borderRadius: 6,
            border: '1px solid var(--rah-border-strong)',
            background: 'var(--rah-bg-surface)',
            color: 'var(--rah-text-muted)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            cursor: 'pointer',
          }}
        >
          <X size={14} />
        </button>
      </div>

      <div
        style={{
          flex: 1,
          minHeight: 0,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          padding: 24,
          color: 'var(--rah-text-muted)',
          fontSize: 13,
          textAlign: 'center',
        }}
      >
        Chat UI is not included in this open-source parity slice. The graph, MCP, retrieval, and skill surfaces remain available.
      </div>
    </div>
  );
}
