import { tool } from 'ai';
import { z } from 'zod';
import { edgeService } from '@/services/database/edges';
import { nodeService } from '@/services/database/nodes';
import { formatNodeForChat } from '../infrastructure/nodeFormatter';
import { validateEdgeExplanation } from '@/services/database/quality';

export const createEdgeTool = tool({
  description:
    'Create a relationship between two nodes only after the user has explicitly confirmed the proposed connection. Check for an existing relationship first, then use this as the execution step after you surfaced candidate edges in plain language and got a clear yes. Provide an explanation and the system will infer the type and direction.\n\n' +
    'Examples of explanations:\n' +
    '- "Written by" (book → author)\n' +
    '- "Episode of this podcast" (episode → podcast)\n' +
    '- "Inspired this insight" (source → derivative)\n' +
    '- "Related concept" (general relationship)\n',
  inputSchema: z.object({
    from_node_id: z.number().describe('The ID of the source node'),
    to_node_id: z.number().describe('The ID of the target node'),
    explanation: z.string().describe(
      'REQUIRED: Why does this connection exist? The system will infer the relationship type from your explanation.'
    ),
    confirmed_by_user: z.boolean().describe(
      'Must be true. Only create the edge after the user has explicitly approved this proposed relationship.'
    ),
    source: z.enum(['user', 'ai', 'ai_similarity', 'helper_name']).default('ai').describe(
      'Source of this edge. Use "ai" for AI-created, "user" for manual, "ai_similarity" for similarity-based.'
    )
  }),
  execute: async (params) => {
    console.log('🔗 CreateEdge tool called with params:', JSON.stringify(params, null, 2));
    
    try {
      if (!params.confirmed_by_user) {
        return {
          success: false,
          error: 'createEdge requires explicit user confirmation before writing the relationship.',
          data: null,
        };
      }

      // Validate basic IDs
      if (!Number.isFinite(params.from_node_id) || params.from_node_id <= 0) {
        return {
          success: false,
          error: 'from_node_id must be a positive integer. Use queryNodes to confirm the source node ID before creating the edge.',
          data: null,
        };
      }

      if (!Number.isFinite(params.to_node_id) || params.to_node_id <= 0) {
        return {
          success: false,
          error: 'to_node_id must be a positive integer. Run queryNodes to fetch the target node ID before creating the edge.',
          data: null,
        };
      }

      if (params.from_node_id === params.to_node_id) {
        return {
          success: false,
          error: 'Cannot create edge from a node to itself',
          data: null
        };
      }

      const explanation = (params.explanation || '').trim();
      if (!explanation) {
        return {
          success: false,
          error: 'explanation is required. Provide a clear reason for why these two nodes should be connected.',
          data: null
        };
      }
      const explanationError = validateEdgeExplanation(explanation);
      if (explanationError) {
        return {
          success: false,
          error: explanationError,
          data: null
        };
      }

      const [fromNode, toNode] = await Promise.all([
        nodeService.getNodeById(params.from_node_id),
        nodeService.getNodeById(params.to_node_id)
      ]);

      if (!fromNode) {
        return {
          success: false,
          error: `Source node ${params.from_node_id} not found. Use queryNodes to confirm the ID before creating the edge.`,
          data: null
        };
      }

      if (!toNode) {
        return {
          success: false,
          error: `Target node ${params.to_node_id} not found. Run queryNodes to fetch the correct ID before creating the edge.`,
          data: null
        };
      }

      // Check if edge already exists
      const exists = await edgeService.edgeExists(params.from_node_id, params.to_node_id);
      if (exists) {
        return {
          success: false,
          error: `Edge already exists between node ${params.from_node_id} and node ${params.to_node_id}`,
          data: null
        };
      }

      // Normalize and create the edge
      const source = (() => {
        if (params.source === 'ai') return 'helper_name';
        if (params.source === 'helper_name') return 'helper_name';
        if (params.source === 'ai_similarity') return 'ai_similarity';
        if (params.source === 'user') return 'user';
        return 'helper_name';
      })();

      const newEdge = await edgeService.createEdge({
        from_node_id: params.from_node_id,
        to_node_id: params.to_node_id,
        explanation,
        created_via: 'agent',
        source
      });

      const fromLabel = formatNodeForChat({
        id: fromNode.id,
        title: fromNode.title
      });

      const toLabel = formatNodeForChat({
        id: toNode.id,
        title: toNode.title
      });

      return {
        success: true,
        data: newEdge,
        message: `Created edge connection from ${fromLabel} to ${toLabel}`,
        formatted_labels: {
          from: fromLabel,
          to: toLabel
        }
      };
    } catch (error) {
      console.error('CreateEdge tool error:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to create edge',
        data: null
      };
    }
  }
});
