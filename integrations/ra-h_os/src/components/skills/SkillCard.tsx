"use client";

import { Trash2 } from 'lucide-react';
import type { SkillMeta } from '@/types/skills';

interface SkillCardProps {
  skill: SkillMeta;
  onSelect: (name: string) => void;
  onDelete?: (name: string, e: React.MouseEvent<HTMLButtonElement>) => void;
  deleting?: string | null;
  isActive?: boolean;
}

export default function SkillCard({
  skill,
  onSelect,
  onDelete,
  deleting = null,
  isActive = false,
}: SkillCardProps) {
  const isDeleting = deleting === skill.name;

  return (
    <div
      onMouseEnter={(e) => {
        if (!isActive) {
          e.currentTarget.style.background = 'var(--rah-bg-hover)';
          e.currentTarget.style.borderColor = 'var(--rah-border-stronger)';
        }
      }}
      onMouseLeave={(e) => {
        if (!isActive) {
          e.currentTarget.style.background = 'var(--rah-bg-panel)';
          e.currentTarget.style.borderColor = 'var(--rah-border)';
        }
      }}
      style={{
        display: 'flex',
        alignItems: 'center',
        gap: '10px',
        padding: '10px',
        background: isActive ? 'var(--rah-bg-active)' : 'var(--rah-bg-panel)',
        border: `1px solid ${isActive ? 'var(--rah-accent-green)' : 'var(--rah-border)'}`,
        borderRadius: '8px',
        transition: 'all 0.15s ease',
      }}
    >
      <button
        type="button"
        onClick={() => onSelect(skill.name)}
        style={{
          flex: 1,
          minWidth: 0,
          background: 'transparent',
          border: 'none',
          cursor: 'pointer',
          textAlign: 'left',
          padding: 0,
        }}
      >
        <span style={{ color: 'var(--rah-text-base)', fontSize: '13px', fontWeight: 500, display: 'block' }}>
          {skill.name}
        </span>
        <span
          style={{
            color: 'var(--rah-text-muted)',
            fontSize: '12px',
            lineHeight: '1.4',
            display: 'block',
            marginTop: '2px',
            overflow: 'hidden',
            textOverflow: 'ellipsis',
            whiteSpace: 'nowrap',
          }}
          title={skill.description}
        >
          {skill.description}
        </span>
      </button>
      {onDelete && !skill.immutable && (
        <button
          type="button"
          onClick={(e) => onDelete(skill.name, e)}
          disabled={isDeleting}
          style={{
            background: 'transparent',
            border: 'none',
            color: 'var(--rah-text-muted)',
            cursor: isDeleting ? 'default' : 'pointer',
            padding: '4px',
            borderRadius: '4px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            flexShrink: 0,
            opacity: isDeleting ? 0.3 : 1,
          }}
          onMouseEnter={(e) => {
            e.currentTarget.style.color = '#ef4444';
          }}
          onMouseLeave={(e) => {
            e.currentTarget.style.color = 'var(--rah-text-muted)';
          }}
          aria-label={`Delete ${skill.name}`}
        >
          <Trash2 size={14} />
        </button>
      )}
    </div>
  );
}
