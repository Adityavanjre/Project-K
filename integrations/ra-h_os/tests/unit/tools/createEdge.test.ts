import { describe, expect, it, vi } from 'vitest';

vi.mock('@/services/database/nodes', () => ({
  nodeService: {
    getNodeById: vi.fn(),
  },
}));

vi.mock('@/services/database/edges', () => ({
  edgeService: {
    edgeExists: vi.fn(),
    createEdge: vi.fn(),
  },
}));

import { nodeService } from '@/services/database/nodes';
import { edgeService } from '@/services/database/edges';
import { createEdgeTool } from '@/tools/database/createEdge';

// Helper to call tool execute with proper AI SDK signature
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const executeCreateEdge = async (params: any) => {
  const result = await createEdgeTool.execute!(params, { toolCallId: 'test', messages: [] });
  return result as { success: boolean; error?: string; data?: { id: number } };
};

describe('createEdgeTool', () => {
  it('rejects invalid from_node_id', async () => {
    const result = await executeCreateEdge({
      from_node_id: 0,
      to_node_id: 2,
      source: 'ai',
    });

    expect(result.success).toBe(false);
    expect(result.error).toMatch(/from_node_id/);
  });

  it('returns error when edge already exists', async () => {
    vi.mocked(nodeService.getNodeById).mockResolvedValueOnce({
      id: 1, title: 'From', created_at: '', updated_at: ''
    });
    vi.mocked(nodeService.getNodeById).mockResolvedValueOnce({
      id: 2, title: 'To', created_at: '', updated_at: ''
    });
    vi.mocked(edgeService.edgeExists).mockResolvedValueOnce(true);

    const result = await executeCreateEdge({
      from_node_id: 1,
      to_node_id: 2,
      explanation: 'Source node references the target node directly.',
      source: 'ai',
    });

    expect(result.success).toBe(false);
    expect(result.error).toMatch(/already exists/i);
  });

  it('creates edge when valid and not existing', async () => {
    vi.mocked(nodeService.getNodeById).mockResolvedValueOnce({
      id: 1, title: 'From', created_at: '', updated_at: ''
    });
    vi.mocked(nodeService.getNodeById).mockResolvedValueOnce({
      id: 2, title: 'To', created_at: '', updated_at: ''
    });
    vi.mocked(edgeService.edgeExists).mockResolvedValueOnce(false);
    vi.mocked(edgeService.createEdge).mockResolvedValueOnce({
      id: 10,
      from_node_id: 1,
      to_node_id: 2,
      source: 'helper_name',
      context: {},
      created_at: '',
    });

    const result = await executeCreateEdge({
      from_node_id: 1,
      to_node_id: 2,
      explanation: 'Episode belongs to the podcast represented by the target node.',
      source: 'ai',
    });

    expect(result.success).toBe(true);
    expect(result.data?.id).toBe(10);
  });
});
