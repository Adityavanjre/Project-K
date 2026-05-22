import { tool } from 'ai';
import { z } from 'zod';
import { edgeService } from '@/services/database/edges';
import { formatNodeForChat } from '../infrastructure/nodeFormatter';

function truncateText(value: unknown, maxLength = 180): string | null {
  if (typeof value !== 'string') return null;
  const trimmed = value.trim();
  if (!trimmed) return null;
  if (trimmed.length <= maxLength) return trimmed;
  if (maxLength <= 3) return trimmed.slice(0, maxLength);
  return `${trimmed.slice(0, maxLength - 3)}...`;
}

export const queryEdgeTool = tool({
  description: 'Find edges by node/direction/source/ID',
  inputSchema: z.object({
    filters: z.object({
      node_id: z.number().optional().describe('Get all edges connected to this specific node (both incoming and outgoing)'),
      from_node_id: z.number().optional().describe('Get edges originating from this specific node'),
      to_node_id: z.number().optional().describe('Get edges pointing to this specific node'),
      source: z.enum(['user', 'ai_similarity', 'helper_name']).optional().describe('Filter edges by their source type'),
      edge_id: z.number().optional().describe('Get a specific edge by its ID'),
      limit: z.number().min(1).max(100).default(20).describe('Maximum number of results to return')
    }).optional().describe('Filters to apply when querying edges')
  }),
  execute: async ({ filters = {} }) => {
    console.log('🔍 QueryEdge tool called with filters:', JSON.stringify(filters, null, 2));
    
    try {
      let result;
      let message = '';

      // Handle specific edge ID lookup
      if (filters.edge_id) {
        const edge = await edgeService.getEdgeById(filters.edge_id);
        return {
          success: true,
          data: {
            edges: edge ? [edge] : [],
            count: edge ? 1 : 0,
            filters_applied: filters
          },
          message: edge ? `Found edge ${filters.edge_id}` : `Edge ${filters.edge_id} not found`
        };
      }

      // Handle node connections (most common use case)
      if (filters.node_id) {
        const effectiveLimit = Math.min(filters.limit || 20, 12);
        const connections = await edgeService.getNodeConnections(filters.node_id);
        const edges = connections.map(conn => conn.edge);
        
        // Apply additional filters if specified
        let filteredEdges = edges;
        if (filters.source) {
          filteredEdges = edges.filter(edge => edge.source === filters.source);
        }
        
        // Apply limit and format connected nodes
        const limitedConnections = connections.slice(0, effectiveLimit);
        const formattedConnections = limitedConnections.map(connection => {
          const formattedNode = formatNodeForChat({
            id: connection.connected_node.id,
            title: connection.connected_node.title
          });

          const context = connection.edge.context as Record<string, unknown> | undefined;
          
          return {
            edge: {
              id: connection.edge.id,
              from_node_id: connection.edge.from_node_id,
              to_node_id: connection.edge.to_node_id,
              source: connection.edge.source,
              created_at: connection.edge.created_at,
              context: {
                type: typeof context?.type === 'string' ? context.type : null,
                explanation: truncateText(context?.explanation),
                confidence: typeof context?.confidence === 'number' ? context.confidence : null,
              }
            },
            connected_node: {
              id: connection.connected_node.id,
              title: connection.connected_node.title,
              description: truncateText(connection.connected_node.description, 140),
              formatted_display: formattedNode
            }
          };
        });

        const summarizedEdges = formattedConnections.map(connection => ({
          id: connection.edge.id,
          from_node_id: connection.edge.from_node_id,
          to_node_id: connection.edge.to_node_id,
          source: connection.edge.source,
          created_at: connection.edge.created_at,
          context: connection.edge.context,
          connected_node: connection.connected_node.formatted_display,
        }));
        
        // Create message with formatted connected nodes
        const connectedNodeLabels = formattedConnections.map(conn => conn.connected_node.formatted_display).join(', ');
        const message = `Found ${filteredEdges.length} edges for node ${filters.node_id}. Showing ${formattedConnections.length}${connectedNodeLabels ? `. Connected nodes: ${connectedNodeLabels}` : ''}`;

        return {
          success: true,
          data: {
            edges: summarizedEdges,
            connections: formattedConnections,
            count: filteredEdges.length,
            returned_count: formattedConnections.length,
            filters_applied: filters
          },
          message: message
        };
      }

      // Handle directional queries or get all edges
      const allEdges = await edgeService.getEdges();
      let filteredEdges = allEdges;

      // Apply filters
      if (filters.from_node_id) {
        filteredEdges = filteredEdges.filter(edge => edge.from_node_id === filters.from_node_id);
        message += `from node ${filters.from_node_id} `;
      }
      
      if (filters.to_node_id) {
        filteredEdges = filteredEdges.filter(edge => edge.to_node_id === filters.to_node_id);
        message += `to node ${filters.to_node_id} `;
      }
      
      if (filters.source) {
        filteredEdges = filteredEdges.filter(edge => edge.source === filters.source);
        message += `with source ${filters.source} `;
      }

      // Apply limit
      const limitedEdges = filteredEdges.slice(0, filters.limit || 20);

      return {
        success: true,
        data: {
          edges: limitedEdges,
          count: filteredEdges.length,
          total_available: allEdges.length,
          filters_applied: filters
        },
        message: `Found ${filteredEdges.length} edges ${message}`.trim()
      };
    } catch (error) {
      console.error('QueryEdge tool error:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to query edges',
        data: {
          edges: [],
          count: 0,
          filters_applied: filters
        }
      };
    }
  }
});
