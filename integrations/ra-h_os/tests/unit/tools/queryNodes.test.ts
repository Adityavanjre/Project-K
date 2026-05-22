import { describe, expect, it, vi } from 'vitest';

vi.mock('@/services/database/nodes', () => ({
  nodeService: {
    getNodeById: vi.fn(),
    getNodes: vi.fn(),
  },
}));

import { nodeService } from '@/services/database/nodes';
import { queryNodesTool } from '@/tools/database/queryNodes';

// Helper to call tool execute with proper AI SDK signature
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const executeQueryNodes = async (params: any) => {
  const result = await queryNodesTool.execute!(params, { toolCallId: 'test', messages: [] });
  return result as { success: boolean; data?: { nodes: { id: number }[]; count: number } };
};

describe('queryNodesTool', () => {
  it('returns a single node when search is numeric and node exists', async () => {
    vi.mocked(nodeService.getNodeById).mockResolvedValueOnce({
      id: 123,
      title: 'Test Node',
      created_at: '',
      updated_at: '',
    });

    const result = await executeQueryNodes({
      filters: { search: '123', limit: 5 },
    });

    expect(result.success).toBe(true);
    expect(result.data?.nodes).toHaveLength(1);
    expect(result.data?.nodes[0].id).toBe(123);
  });

  it('returns empty when search is numeric and node is missing', async () => {
    vi.mocked(nodeService.getNodeById).mockResolvedValueOnce(null);

    const result = await executeQueryNodes({
      filters: { search: '999', limit: 5 },
    });

    expect(result.success).toBe(true);
    expect(result.data?.nodes).toHaveLength(0);
    expect(result.data?.count).toBe(0);
  });

  it('respects limit and reports total count', async () => {
    vi.mocked(nodeService.getNodes).mockResolvedValueOnce([
      { id: 1, title: 'A', created_at: '', updated_at: '' },
      { id: 2, title: 'B', created_at: '', updated_at: '' },
    ]);

    const result = await executeQueryNodes({
      filters: { limit: 1 },
    });

    expect(result.success).toBe(true);
    expect(result.data?.nodes).toHaveLength(1);
    expect(result.data?.count).toBe(2);
  });
});
