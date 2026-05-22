"use client";

import { Inbox } from 'lucide-react';
import { Node } from '@/types/database';
import { getNodeIcon } from '@/utils/nodeIcons';
import { formatRelativeDate } from '@/utils/formatDate';
import { getNodeProcessedState } from '@/services/nodes/metadata';

interface ListViewProps {
  nodes: Node[];
  onNodeClick: (nodeId: number) => void;
}

export default function ListView({ nodes, onNodeClick }: ListViewProps) {

  const truncateContent = (content?: string, maxLength: number = 100) => {
    if (!content) return '';
    if (content.length <= maxLength) return content;
    return content.substring(0, maxLength) + '...';
  };

  if (nodes.length === 0) {
    return (
      <div style={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        gap: '8px',
        height: '100%',
        color: 'var(--rah-text-muted)',
        padding: '40px 20px',
        textAlign: 'center',
      }}>
        <Inbox size={28} strokeWidth={1.5} style={{ opacity: 0.4 }} />
        <span style={{ fontSize: '14px', color: 'var(--rah-text-secondary)' }}>Nothing here yet</span>
        <span style={{ fontSize: '12px', opacity: 0.7 }}>
          Try adjusting your filters, or add a node with ⌘N
        </span>
      </div>
    );
  }

  return (
    <div style={{
      height: '100%',
      overflowY: 'auto',
      padding: '8px'
    }}>
      {nodes.map(node => {
        const processedState = getNodeProcessedState(node.metadata);
        const isProcessed = processedState === 'processed';

        return (
          <button
            key={node.id}
            onClick={() => onNodeClick(node.id)}
            style={{
              width: '100%',
              display: 'flex',
              alignItems: 'flex-start',
              gap: '12px',
              padding: '12px',
              marginBottom: '4px',
              background: isProcessed ? 'var(--rah-bg-subtle, var(--rah-bg-base))' : 'var(--rah-bg-base)',
              border: '1px solid var(--rah-border)',
              borderLeft: `2px solid ${isProcessed ? 'var(--rah-accent-green, #4ade80)' : 'var(--rah-border-stronger)'}`,
              borderRadius: '6px',
              cursor: 'pointer',
              textAlign: 'left',
              transition: 'all 0.15s ease',
              opacity: isProcessed ? 0.82 : 1
            }}
            onMouseEnter={(e) => {
              e.currentTarget.style.background = 'var(--rah-bg-surface)';
              e.currentTarget.style.borderColor = 'var(--rah-border-strong)';
              e.currentTarget.style.transform = 'translateY(-1px)';
              e.currentTarget.style.boxShadow = 'var(--rah-shadow-floating)';
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.background = 'var(--rah-bg-base)';
              e.currentTarget.style.borderColor = 'var(--rah-border)';
              e.currentTarget.style.transform = 'translateY(0)';
              e.currentTarget.style.boxShadow = 'none';
            }}
          >
            {/* Icon */}
            <div style={{
              width: '32px',
              height: '32px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              background: 'var(--rah-bg-active)',
              borderRadius: '6px',
              flexShrink: 0
            }}>
              {getNodeIcon(node, 16)}
            </div>

            {/* Content */}
            <div style={{ flex: 1, minWidth: 0 }}>
              {/* Title */}
              <div style={{
                fontSize: '14px',
                fontWeight: 500,
                color: 'var(--rah-text-base)',
                marginBottom: '4px',
                overflow: 'hidden',
                textOverflow: 'ellipsis',
                whiteSpace: 'nowrap'
              }}>
                {node.title || 'Untitled'}
              </div>

              {/* Description or Content Preview */}
              {(node.description || node.source) && (
                <div style={{
                  fontSize: '13px',
                  color: 'var(--rah-text-muted)',
                  marginBottom: '8px',
                  lineHeight: '1.4',
                  display: '-webkit-box',
                  WebkitLineClamp: 2,
                  WebkitBoxOrient: 'vertical',
                  overflow: 'hidden'
                }}>
                  {node.description || truncateContent(node.source)}
                </div>
              )}

              {/* Metadata Row */}
              <div style={{
                display: 'flex',
                alignItems: 'center',
                gap: '12px',
                flexWrap: 'wrap'
              }}>
                <span style={{
                  padding: '2px 8px',
                  background: isProcessed ? 'rgba(74, 222, 128, 0.10)' : 'var(--rah-bg-active)',
                  border: `1px solid ${isProcessed ? 'rgba(74, 222, 128, 0.35)' : 'var(--rah-border-strong)'}`,
                  borderRadius: '999px',
                  fontSize: '11px',
                  color: isProcessed ? 'var(--rah-accent-green, #4ade80)' : 'var(--rah-text-muted)'
                }}>
                  {processedState}
                </span>
                {/* Date */}
                <span style={{
                  fontSize: '11px',
                  color: 'var(--rah-text-muted)'
                }}>
                  {formatRelativeDate(node.updated_at || node.created_at)}
                </span>

                {/* Edge count */}
                {node.edge_count !== undefined && node.edge_count > 0 && (
                  <span style={{
                    fontSize: '11px',
                    color: 'var(--rah-text-muted)'
                  }}>
                    {node.edge_count} connections
                  </span>
                )}
              </div>
            </div>
          </button>
        );
      })}
    </div>
  );
}
