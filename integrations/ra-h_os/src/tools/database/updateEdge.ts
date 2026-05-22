import { tool } from 'ai';
import { z } from 'zod';
import { edgeService } from '@/services/database/edges';
import { validateEdgeExplanation } from '@/services/database/quality';

export const updateEdgeTool = tool({
  description: 'Update an existing edge only after the user explicitly confirmed the corrected relationship. Use this when the connection already exists and only the explanation or classification needs to change. Explanations must explicitly state why the relationship exists.',
  inputSchema: z.object({
    confirmed_by_user: z.boolean().describe('Must be true. Reject the edge update otherwise.'),
    edge_id: z.number().describe('The ID of the edge to update'),
    updates: z.object({
      explanation: z.string().optional().describe('Updated relationship explanation'),
      context: z.record(z.any()).optional().describe('Updated context information for this edge - can include explanation, relationship type, strength, notes, etc.'),
      source: z.enum(['user', 'ai_similarity', 'helper_name']).optional().describe('Updated source classification for this edge'),
    }).describe('Fields to update on the edge')
  }),
  execute: async (params) => {
    console.log('📝 UpdateEdge tool called with params:', JSON.stringify(params, null, 2));
    
    try {
      if (!params.confirmed_by_user) {
        return {
          success: false,
          error: 'Edge updates require explicit user confirmation before writing to the graph.',
          data: null
        };
      }

      // Validate that edge exists before updating
      const existingEdge = await edgeService.getEdgeById(params.edge_id);
      if (!existingEdge) {
        return {
          success: false,
          error: `Edge with ID ${params.edge_id} not found`,
          data: null
        };
      }

      // Filter out undefined values from updates
      const cleanUpdates = Object.fromEntries(
        Object.entries(params.updates).filter(([_, value]) => value !== undefined)
      );

      if (Object.keys(cleanUpdates).length === 0) {
        return {
          success: false,
          error: 'No valid updates provided',
          data: existingEdge
        };
      }

      if (typeof cleanUpdates.explanation === 'string') {
        const explanationError = validateEdgeExplanation(cleanUpdates.explanation);
        if (explanationError) {
          return {
            success: false,
            error: explanationError,
            data: existingEdge
          };
        }
      }

      if (
        !cleanUpdates.explanation &&
        cleanUpdates.context &&
        typeof cleanUpdates.context === 'object' &&
        !Array.isArray(cleanUpdates.context) &&
        typeof cleanUpdates.context.explanation === 'string'
      ) {
        const explanationError = validateEdgeExplanation(cleanUpdates.context.explanation);
        if (explanationError) {
          return {
            success: false,
            error: explanationError,
            data: existingEdge
          };
        }
      }

      // Update the edge
      const updatedEdge = await edgeService.updateEdge(params.edge_id, cleanUpdates);

      // Build descriptive message
      const updateDescriptions = [];
      if (cleanUpdates.context) updateDescriptions.push('context');
      if (cleanUpdates.source) updateDescriptions.push(`source to ${cleanUpdates.source}`);

      return {
        success: true,
        data: updatedEdge,
        message: `Updated edge ${params.edge_id}: ${updateDescriptions.join(', ')}`
      };
    } catch (error) {
      console.error('UpdateEdge tool error:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to update edge',
        data: null
      };
    }
  }
});
