import { tool } from 'ai';
import { z } from 'zod';
import { retrieveQueryContext } from '@/services/retrieval/queryContext';

export const retrieveQueryContextTool = tool({
  description: 'Given a raw user query plus optional focused node state, retrieve the most relevant graph context to ground the current turn. Use this when the user is asking a substantive question or request that would benefit from one or more prior nodes, chunks, or neighbors. Do not use this as the first tool when the user is clearly trying to find a specific existing node; use queryNodes first for direct node retrieval.',
  inputSchema: z.object({
    query: z.string().min(1).describe('The raw user query for this turn.'),
    focused_node_id: z.number().int().positive().nullable().optional().describe('Optional currently focused node ID.'),
    limit: z.number().int().min(1).max(12).optional().describe('Maximum number of nodes to return.'),
  }),
  execute: async ({ query, focused_node_id, limit }) => {
    try {
      const result = await retrieveQueryContext({
        query,
        focused_node_id: focused_node_id ?? null,
        limit,
      });

      return {
        success: true,
        data: result,
        message: result.shouldRetrieve
          ? `Retrieved ${result.nodes.length} node(s) and ${result.chunks.length} supporting chunk(s) for the current turn.`
          : result.reason,
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to retrieve query context',
        data: null,
      };
    }
  },
});
