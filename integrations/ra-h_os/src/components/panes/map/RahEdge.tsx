"use client";

import { memo, useState } from 'react';
import {
  BaseEdge,
  getBezierPath,
  type EdgeProps,
} from '@xyflow/react';

interface RahEdgeData {
  explanation?: string;
  [key: string]: unknown;
}

function RahEdgeComponent({
  id,
  sourceX,
  sourceY,
  targetX,
  targetY,
  style,
  data,
  ...rest
}: EdgeProps) {
  const [hovered, setHovered] = useState(false);
  const explanation = (data as RahEdgeData | undefined)?.explanation;

  const [edgePath, labelX, labelY] = getBezierPath({
    sourceX,
    sourceY,
    targetX,
    targetY,
    curvature: 0.18,
  });

  return (
    <g
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
    >
      {/* Invisible wider path for easier hover targeting */}
      <path
        d={edgePath}
        fill="none"
        stroke="transparent"
        strokeWidth={12}
        style={{ cursor: 'default' }}
      />
      <BaseEdge id={id} path={edgePath} style={{ strokeLinecap: 'round', ...style }} />
      {hovered && explanation && (
        <foreignObject
          x={labelX - 80}
          y={labelY - 14}
          width={160}
          height={28}
          style={{ overflow: 'visible', pointerEvents: 'none' }}
        >
          <div
            style={{
              background: 'var(--rah-bg-modal)',
              border: '1px solid var(--rah-border-strong)',
              borderRadius: 4,
              padding: '2px 8px',
              fontSize: 10,
              color: 'var(--rah-text-secondary)',
              textAlign: 'center',
              whiteSpace: 'nowrap',
              overflow: 'hidden',
              textOverflow: 'ellipsis',
              maxWidth: 160,
              boxShadow: 'var(--rah-shadow-floating)',
            }}
          >
            {explanation}
          </div>
        </foreignObject>
      )}
    </g>
  );
}

export const RahEdge = memo(RahEdgeComponent);
