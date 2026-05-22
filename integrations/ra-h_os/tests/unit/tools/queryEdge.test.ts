import { describe, expect, it, vi } from 'vitest';

vi.mock('@/services/database/edges', () => ({
  edgeService: {
    getEdgeById: vi.fn(),
    getNodeConnections: vi.fn(),
    getEdges: vi.fn(),
  },
}));

import { edgeService } from '@/services/database/edges';
import { queryEdgeTool } from '@/tools/database/queryEdge';

// Helper to call tool execute with proper AI SDK signature
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const executeQueryEdge = async (params: any) => {
  const result = await queryEdgeTool.execute!(params, { toolCallId: 'test', messages: [] });
  return result as { success: boolean; data?: { edges: any[]; connections?: any[] } };
};

describe('queryEdgeTool', () => {
  it('returns empty list when no edges for from_node_id', async () => {
    vi.mocked(edgeService.getEdges).mockResolvedValueOnce([]);

    const result = await executeQueryEdge({ filters: { from_node_id: 1, limit: 10 } });

    expect(result.success).toBe(true);
    expect(result.data?.edges).toHaveLength(0);
  });

  it('returns edges when found for from_node_id', async () => {
    vi.mocked(edgeService.getEdges).mockResolvedValueOnce([
      { id: 1, from_node_id: 1, to_node_id: 2, source: 'user', created_at: '' },
    ]);

    const result = await executeQueryEdge({ filters: { from_node_id: 1, limit: 10 } });

    expect(result.success).toBe(true);
    expect(result.data?.edges).toHaveLength(1);
  });

  it('returns edge by ID when edge_id provided', async () => {
    vi.mocked(edgeService.getEdgeById).mockResolvedValueOnce({
      id: 9,
      from_node_id: 1,
      to_node_id: 2,
      source: 'user',
      created_at: '',
    });

    const result = await executeQueryEdge({ filters: { edge_id: 9, limit: 10 } });

    expect(result.success).toBe(true);
    expect(result.data?.edges).toHaveLength(1);
  });

  it('returns compact connection payloads for node traversal', async () => {
    vi.mocked(edgeService.getNodeConnections).mockResolvedValueOnce([
      {
        edge: {
          id: 42,
          from_node_id: 1,
          to_node_id: 2,
          source: 'user',
          created_at: '',
          context: {
            type: 'related_to',
            explanation: 'A'.repeat(300),
            confidence: 0.8,
          },
        },
        connected_node: {
          id: 2,
          title: 'Connected node',
          description: 'B'.repeat(250),
          notes: 'Hidden notes should not be returned',
          chunk: 'Hidden chunk should not be returned',
        },
      },
    ] as any);

    const result = await executeQueryEdge({ filters: { node_id: 1, limit: 20 } });

    expect(result.success).toBe(true);
    expect(result.data?.edges).toHaveLength(1);
    expect(result.data?.connections).toHaveLength(1);
    expect(result.data?.connections?.[0].connected_node.notes).toBeUndefined();
    expect(result.data?.connections?.[0].connected_node.chunk).toBeUndefined();
    expect(result.data?.connections?.[0].connected_node.description.length).toBeLessThanOrEqual(140);
    expect(result.data?.edges?.[0].context.explanation.length).toBeLessThanOrEqual(180);
  });
});
