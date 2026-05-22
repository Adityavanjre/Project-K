import { tool } from 'ai';
import { z } from 'zod';
import { getInternalApiBaseUrl } from '@/services/runtime/apiBase';
import { getInternalAuthHeaders } from '@/services/auth/internalAuth';

export const updateNodeTool = tool({
  description: 'Update node fields when the existing node is clearly the same artifact and a net-new node would be redundant. Explicit user-directed updates should proceed once the target node is clear; if you are only proposing a change, ask first. Use this to enrich or correct nodes without losing canonical source content. When changing source on an existing node, inspect the current source first via the focused-node excerpt or getNodesById, then include source_update_basis as a short exact excerpt you inspected. When fixing a user-authored idea node, source should preserve the user\'s original wording as fully as possible. Never block an update because the description is incomplete. If the new description framing is materially inferred, complete the update and then invite one concise user feedback pass.',
  inputSchema: z.object({
    id: z.number().describe('The ID of the node to update'),
    updates: z.object({
      title: z.string().optional().describe('New title'),
      description: z.string().max(500).optional().describe('Optional natural description. Replace the whole field with one clean description when you are improving context. It should read like normal prose, not labels.'),
      source: z.string().optional().describe('Canonical source content for embedding. Use this to set or correct the raw source text. For user-authored ideas or dictated notes, preserve the user\'s original wording with only minimal cleanup rather than compressing it into a summary.'),
      link: z.string().optional().describe('New link'),
      event_date: z.string().optional().describe('When the thing actually happened (ISO 8601). Not when it was added to the graph.'),
      metadata: z.record(z.any()).optional().describe('Metadata patch. It now merges with existing metadata instead of replacing the full blob. Use canonical keys: type, state, captured_method, captured_by, source_metadata.')
    }).passthrough().describe('Object containing the fields to update. Derived analysis should be stored in a separate linked node, not appended to the source node.'),
    source_update_basis: z.string().optional().describe('When updating source on a node that already has source text, include a short exact excerpt from the current source you inspected first. This is required for source rewrites unless the existing source is empty.')
  }),
  execute: async ({ id, updates, source_update_basis }) => {
    try {
      if (!updates || Object.keys(updates).length === 0) {
        return {
          success: false,
          error: 'updateNode requires at least one field in the updates object.',
          data: null
        };
      }

      // Call the nodes API endpoint
      const response = await fetch(`${getInternalApiBaseUrl()}/api/nodes/${id}`, {
        method: 'PUT',
        headers: getInternalAuthHeaders({ 'Content-Type': 'application/json' }),
        body: JSON.stringify({ ...updates, source_update_basis })
      });

      const result = await response.json();
      
      if (!response.ok) {
        return {
          success: false,
          error: result.error || 'Failed to update node',
          data: null
        };
      }

      return {
        success: true,
        data: result.node,
        message: `Updated node ID ${id}`
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to update node',
        data: null
        };
    }
  }
});

// Legacy export for backwards compatibility
export const updateItemTool = updateNodeTool;
