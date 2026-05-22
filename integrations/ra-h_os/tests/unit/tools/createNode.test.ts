import { describe, expect, it, vi, beforeEach } from 'vitest';

import { createNodeTool } from '@/tools/database/createNode';

const fetchMock = vi.fn();

global.fetch = fetchMock as typeof fetch;

// Helper to call tool execute with proper AI SDK signature
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const executeCreateNode = async (params: any) => {
  const result = await createNodeTool.execute!(params, { toolCallId: 'test', messages: [] });
  return result as { success: boolean; error?: string; data?: { formatted_display: string } };
};

describe('createNodeTool', () => {
  beforeEach(() => {
    fetchMock.mockReset();
  });

  it('creates nodes without requiring dimensions', async () => {
    fetchMock.mockResolvedValueOnce({
      ok: true,
      json: async () => ({
        data: { id: 1, title: 'Test' },
      }),
    });

    const result = await executeCreateNode({
      title: 'Test',
      description: 'Note capturing a concrete test artifact and why it matters.',
    });

    expect(result.success).toBe(true);
    expect(fetchMock).toHaveBeenCalled();
    expect(JSON.parse(fetchMock.mock.calls[0][1].body as string)).not.toHaveProperty('dimensions');
    expect(result.data?.formatted_display).toContain('[NODE:1');
  });

  it('returns error when API fails', async () => {
    fetchMock.mockResolvedValueOnce({
      ok: false,
      json: async () => ({ error: 'Failed' }),
    });

    const result = await executeCreateNode({
      title: 'Bad',
      description: 'Note capturing a failing API case and why the error matters.',
    });

    expect(result.success).toBe(false);
    expect(result.error).toContain('Failed');
  });

  it('accepts explicit test node descriptions', async () => {
    fetchMock.mockResolvedValueOnce({
      ok: true,
      json: async () => ({
        data: { id: 2, title: 'Eval Edge B' },
      }),
    });

    const result = await executeCreateNode({
      title: 'Eval Edge B',
      description: 'This is a test node used as the target in an evaluation of edge creation. It matters because it verifies relationship storage and retrieval.',
    });

    expect(result.success).toBe(true);
    expect(fetchMock).toHaveBeenCalledOnce();
  });
});
