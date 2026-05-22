import { tool } from 'ai';
import { z } from 'zod';
import { getInternalApiBaseUrl } from '@/services/runtime/apiBase';

export const deleteNodeTool = tool({
  description: 'Delete a node from the graph by ID',
  inputSchema: z.object({
    id: z.number().int().positive().describe('Node ID to delete'),
  }),
  execute: async ({ id }) => {
    try {
      const response = await fetch(`${getInternalApiBaseUrl()}/api/nodes/${id}`, {
        method: 'DELETE',
        headers: { 'Content-Type': 'application/json' },
      });

      if (!response.ok) {
        let errorMessage = 'Failed to delete node';
        try {
          const errorResult = await response.json();
          errorMessage = errorResult.error || errorMessage;
        } catch {
          errorMessage = `Failed to delete node: ${response.status} ${response.statusText}`;
        }

        return {
          success: false,
          error: errorMessage,
          data: null,
        };
      }

      const result = await response.json();

      return {
        success: true,
        data: { nodeId: id, ...(result.data || {}) },
        message: result.message || `Node ${id} deleted successfully`,
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to delete node',
        data: null,
      };
    }
  },
});
