import { tool } from 'ai';
import { z } from 'zod';
import { nodeService } from '@/services/database/nodes';

export const getNodesByIdTool = tool({
  description: 'Load full node records by IDs. Use this before rewriting an existing node source when the focused-node excerpt is insufficient, because it returns the current description, source text, metadata, and timestamps needed for disciplined updates.',
  inputSchema: z.object({
    nodeIds: z.array(z.number().int().positive()).min(1).max(10).describe('List of node IDs to load'),
    includeSource: z.boolean().default(true).describe('Whether to return source text for each node'),
    sourceCharLimit: z.number().int().min(200).max(20000).default(10000).describe('Max source characters per node before truncation metadata is added'),
  }),
  execute: async ({ nodeIds, includeSource, sourceCharLimit }) => {
    const uniqueIds = Array.from(new Set(nodeIds.filter(id => Number.isFinite(id) && id > 0)));
    if (uniqueIds.length === 0) {
      return {
        success: false,
        error: 'No valid node IDs provided',
        data: { nodes: [] },
      };
    }

    const nodes = await Promise.all(
      uniqueIds.map(async id => {
        try {
          const node = await nodeService.getNodeById(id);
          if (!node) return null;
          const rawSource = typeof node.source === 'string' ? node.source : '';
          const source = includeSource
            ? rawSource.slice(0, sourceCharLimit).trim() || null
            : null;
          const sourceLength = rawSource.length;
          const sourceTruncated = includeSource ? sourceLength > sourceCharLimit : false;

          return {
            id: node.id,
            title: node.title,
            description: node.description ?? null,
            source,
            source_length: sourceLength,
            source_truncated: sourceTruncated,
            link: node.link,
            event_date: node.event_date ?? null,
            chunk_status: node.chunk_status || 'unknown',
            created_at: node.created_at,
            updated_at: node.updated_at,
            metadata: node.metadata ?? null,
          };
        } catch (error) {
          console.warn(`getNodesByIdTool: failed to load node ${id}`, error);
          return null;
        }
      })
    );

    const foundNodes = nodes.filter(Boolean);

    return {
      success: true,
      data: {
        nodes: foundNodes,
        requested: uniqueIds,
        missing: uniqueIds.filter(id => !foundNodes.find(node => node && node.id === id)),
      },
      message: `Loaded ${foundNodes.length} of ${uniqueIds.length} requested nodes.`,
    };
  },
});
