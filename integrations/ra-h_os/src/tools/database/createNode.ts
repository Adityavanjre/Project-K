import { tool } from 'ai';
import { z } from 'zod';
import { getInternalApiBaseUrl } from '@/services/runtime/apiBase';
import { formatNodeForChat } from '../infrastructure/nodeFormatter';
import { getInternalAuthHeaders } from '@/services/auth/internalAuth';

function extractTextFromMessageContent(content: unknown): string {
  if (typeof content === 'string') {
    return content;
  }

  if (!Array.isArray(content)) {
    return '';
  }

  return content
    .map((part) => {
      if (!part || typeof part !== 'object') return '';
      const candidate = part as Record<string, unknown>;
      if (typeof candidate.text === 'string') return candidate.text;
      if (candidate.type === 'text' && typeof candidate.value === 'string') return candidate.value;
      return '';
    })
    .filter(Boolean)
    .join('\n');
}

function inferSourceFromContext(params: { title: string; description?: string; source?: string }, context: any): string | undefined {
  if (typeof params.source === 'string' && params.source.trim()) {
    return params.source.trim();
  }

  const messages = Array.isArray(context?.messages) ? context.messages : [];
  const latestUserMessage = [...messages].reverse().find((message: any) => message?.role === 'user');
  if (!latestUserMessage) {
    return undefined;
  }

  const rawUserText = extractTextFromMessageContent(latestUserMessage.content).trim();
  if (!rawUserText) {
    return undefined;
  }

  if (/^https?:\/\//i.test(rawUserText)) {
    return undefined;
  }

  const normalized = rawUserText.replace(/\r\n/g, '\n').trim();
  const descriptionLength = typeof params.description === 'string' ? params.description.trim().length : 0;
  const isSubstantialCapture = normalized.length >= Math.max(280, descriptionLength + 120) || normalized.includes('\n');

  if (!isSubstantialCapture) {
    return undefined;
  }

  return normalized;
}

export const createNodeTool = tool({
  description: 'Create a node after you have already decided this should be a net-new write. Search first when practical, and prefer updateNode if the artifact is clearly the same thing and a new node would be redundant. If the user explicitly asked to save or import something and duplicate/update checks are complete, write immediately. If you are only suggesting a save, propose the node first and wait for confirmation. Focus on a clean title, a strong natural description that says what the thing is, preserved source text, and the right metadata. When the node comes from the user\'s own idea, note, or dictated thought, preserve their actual wording in source with only minimal cleanup instead of flattening it into a summary. Do not block creation if the description is incomplete. If the description framing is materially inferred, create the node first and then invite one concise user correction pass.',
  inputSchema: z.object({
    title: z.string().describe('The title of the node'),
    description: z.string().max(500).optional().describe('Optional natural description. If you have enough context, describe what this is, why it belongs in Brad\'s graph, and its current workflow status in normal prose. Do not use labels like WHAT:, WHY:, or STATUS:.'),
    source: z.string().optional().describe('Canonical source content for embedding. For external content, store the actual transcript/article/document text. For user-authored ideas or dictated notes, store the user\'s original wording as fully as possible with only minimal cleanup such as obvious whitespace or transcription artifacts. Do not replace raw user thinking with a thin summary.'),
    link: z.string().optional().describe('A URL link to the source'),
    event_date: z.string().optional().describe('When the thing actually happened (ISO 8601). Not when it was added to the graph.'),
    metadata: z.record(z.any()).optional().describe('Optional node metadata. Use canonical keys when known: type, state, captured_method, captured_by, and source_metadata. Source-specific facts belong inside source_metadata.')
  }).passthrough(),
  execute: async (params, context) => {
    console.log('🎯 CreateNode tool called with params:', JSON.stringify(params, null, 2));
    try {
      const canonicalSource = inferSourceFromContext(params, context);

      // Call the nodes API endpoint
      const response = await fetch(`${getInternalApiBaseUrl()}/api/nodes`, {
        method: 'POST',
        headers: getInternalAuthHeaders({ 'Content-Type': 'application/json' }),
        body: JSON.stringify({ ...params, source: canonicalSource ?? params.source })
      });

      const result = await response.json();
      
      if (!response.ok) {
        return {
          success: false,
          error: result.error || 'Failed to create node',
          data: null
        };
      }

      // Format the created node for chat display
      const formattedDisplay = formatNodeForChat({
        id: result.data.id,
        title: result.data.title,
      });

      return {
        success: true,
        data: {
          ...result.data,
          formatted_display: formattedDisplay
        },
        message: `Created node ${formattedDisplay}`
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to create node',
        data: null
      };
    }
  }
});

// Legacy export for backwards compatibility
export const createItemTool = createNodeTool;
