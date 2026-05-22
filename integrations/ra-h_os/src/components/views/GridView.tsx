"use client";

import { Node } from '@/types/database';
import { getNodeIcon } from '@/utils/nodeIcons';
import { getNodeProcessedState } from '@/services/nodes/metadata';

interface GridViewProps {
  nodes: Node[];
  onNodeClick: (nodeId: number) => void;
}

export default function GridView({ nodes, onNodeClick }: GridViewProps) {
  const truncateContent = (content?: string, maxLength: number = 120) => {
    if (!content) return '';
    if (content.length <= maxLength) return content;
    return content.substring(0, maxLength) + '...';
  };

  if (nodes.length === 0) {
    return (
      <div style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        height: '100%',
        color: '#666',
        fontSize: '13px'
      }}>
        No nodes match the current filters
      </div>
    );
  }

  return (
    <div style={{
      height: '100%',
      overflowY: 'auto',
      padding: '12px'
    }}>
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fill, minmax(240px, 1fr))',
        gap: '12px'
      }}>
        {nodes.map(node => {
          const processedState = getNodeProcessedState(node.metadata);
          const isProcessed = processedState === 'processed';

          return (
            <button
              key={node.id}
              onClick={() => onNodeClick(node.id)}
              style={{
                display: 'flex',
                flexDirection: 'column',
                padding: '16px',
                background: isProcessed ? 'rgba(34, 58, 42, 0.45)' : '#0a0a0a',
                border: `1px solid ${isProcessed ? 'rgba(74, 222, 128, 0.28)' : '#1a1a1a'}`,
                borderRadius: '8px',
                cursor: 'pointer',
                textAlign: 'left',
                transition: 'all 0.2s',
                minHeight: '140px',
                opacity: isProcessed ? 0.84 : 1
              }}
              onMouseEnter={(e) => {
                e.currentTarget.style.background = '#111';
                e.currentTarget.style.borderColor = '#333';
                e.currentTarget.style.transform = 'translateY(-2px)';
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.background = '#0a0a0a';
                e.currentTarget.style.borderColor = '#1a1a1a';
                e.currentTarget.style.transform = 'translateY(0)';
              }}
            >
              {/* Header with Icon */}
              <div style={{
                display: 'flex',
                alignItems: 'flex-start',
                gap: '10px',
                marginBottom: '10px'
              }}>
                <div style={{
                  width: '28px',
                  height: '28px',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  background: '#1a1a1a',
                  borderRadius: '6px',
                  flexShrink: 0
                }}>
                  {getNodeIcon(node, 14)}
                </div>
                <div style={{
                  fontSize: '13px',
                  fontWeight: 500,
                  color: '#e5e5e5',
                  lineHeight: '1.3',
                  overflow: 'hidden',
                  display: '-webkit-box',
                  WebkitLineClamp: 2,
                  WebkitBoxOrient: 'vertical'
                }}>
                  {node.title || 'Untitled'}
                </div>
              </div>

              <div style={{
                marginBottom: '10px',
                fontSize: '10px',
                color: isProcessed ? '#86efac' : '#888',
                textTransform: 'lowercase'
              }}>
                {processedState}
              </div>

              {/* Description or Content Preview */}
              {(node.description || node.source) && (
                <div style={{
                  flex: 1,
                  fontSize: '11px',
                  color: '#666',
                  lineHeight: '1.5',
                  overflow: 'hidden',
                  display: '-webkit-box',
                  WebkitLineClamp: 2,
                  WebkitBoxOrient: 'vertical',
                  marginBottom: '10px'
                }}>
                  {node.description || truncateContent(node.source)}
                </div>
              )}

            </button>
          );
        })}
      </div>
    </div>
  );
}
