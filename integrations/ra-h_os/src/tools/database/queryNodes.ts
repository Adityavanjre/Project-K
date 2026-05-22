import { tool } from 'ai';
import { z } from 'zod';
import { formatNodeForChat } from '../infrastructure/nodeFormatter';
import { directNodeLookup } from '@/services/retrieval/directNodeLookup';

type QueryNodeFilters = {
  search?: string;
  limit?: number;
  createdAfter?: string;
  createdBefore?: string;
  eventAfter?: string;
  eventBefore?: string;
};

export const queryNodesTool = tool({
  description: 'Find specific existing nodes in the graph by searching title, description, and source. Use this first when the user is trying to locate a node they already created or a specific existing podcast, article, idea, person, project, or note. For broader current-turn grounding of a substantive question, use retrieveQueryContext instead.',
  inputSchema: z.object({
    filters: z.object({
      search: z.string().describe('Search term to match against node title, description, or source').optional(),
      limit: z.number().min(1).max(50).default(10).describe('Maximum number of results to return'),
      createdAfter: z.string().optional().describe('ISO date (YYYY-MM-DD). Only return nodes created on or after this date.'),
      createdBefore: z.string().optional().describe('ISO date (YYYY-MM-DD). Only return nodes created before this date.'),
      eventAfter: z.string().optional().describe('ISO date (YYYY-MM-DD). Only return nodes with event_date on or after this date.'),
      eventBefore: z.string().optional().describe('ISO date (YYYY-MM-DD). Only return nodes with event_date before this date.'),
    }).passthrough().optional()
  }),
  execute: async ({ filters = {} }: { filters?: QueryNodeFilters }) => {
    console.log('🔍 QueryNodes tool called with filters:', JSON.stringify(filters, null, 2));
    try {
      const result = await directNodeLookup({
        search: filters.search,
        limit: filters.limit,
        createdAfter: filters.createdAfter,
        createdBefore: filters.createdBefore,
        eventAfter: filters.eventAfter,
        eventBefore: filters.eventBefore,
      });

      // Format nodes for chat display
      const formattedNodes = result.nodes.map(node => {
        const formatted = formatNodeForChat({
          id: node.id,
          title: node.title,
        });
        return {
          id: node.id,
          title: node.title,
          created_at: node.created_at,
          updated_at: node.updated_at,
          event_date: node.event_date ?? null,
          formatted_display: formatted
        };
      });

      // Create message with formatted node labels only (no full node payload)
      const formattedLabels = formattedNodes.map(node => node.formatted_display).join(', ');
      const message = `Found ${result.count} nodes${result.filtersApplied.search ? ` matching: "${result.filtersApplied.search}"` : ''}${formattedLabels ? `:\n${formattedLabels}` : ''}`;

      return {
        success: true,
        data: {
          nodes: formattedNodes,
          count: result.count,
          filters_applied: result.filtersApplied
        },
        message: message
      };
    } catch (error) {
      console.error('QueryNodes tool error:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to query nodes',
        data: {
          nodes: [],
          count: 0,
          filters_applied: filters
        }
      };
    }
  }
});

// Legacy export for backwards compatibility
export const queryItemsTool = queryNodesTool;
