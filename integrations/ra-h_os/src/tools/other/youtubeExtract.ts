import { tool } from 'ai';
import { z } from 'zod';
import { extractYouTube } from '@/services/typescript/extractors/youtube';
import { getInternalApiBaseUrl } from '@/services/runtime/apiBase';
import { formatNodeForChat } from '../infrastructure/nodeFormatter';
import { validateExplicitDescription } from '@/services/database/quality';
import { generateUtilityText } from '@/services/llm/provider';

function ensureNodeDescription(candidate: string | undefined, fallbackLead: string): string {
  const normalizedCandidate = typeof candidate === 'string'
    ? candidate.trim().replace(/\s+/g, ' ')
    : '';

  if (normalizedCandidate && !validateExplicitDescription(normalizedCandidate)) {
    return normalizedCandidate.slice(0, 500);
  }

  const lead = normalizedCandidate || fallbackLead.trim();
  const suffix = 'It was added via extraction and the exact reason it belongs in the graph is not yet inferred from the available context, and it has not been reviewed yet.';
  const joined = `${lead}${/[.!?]$/.test(lead) ? ' ' : '. '}${suffix}`;
  return joined.slice(0, 500);
}

// AI-powered content analysis
async function analyzeContentWithAI(
  title: string,
  description: string,
  contentType: string
) {
  try {
    const prompt = `Analyze this ${contentType} content and provide classification.

Title: "${title}"
Description: "${description}"

CRITICAL — nodeDescription rules (max 500 chars):
1. Write natural prose, not labels or a checklist.
2. Make clear what this literally is: "Podcast episode where…", "Talk by…", "Interview with…", "Video essay on…"
3. Name people by their role: the channel/host is the creator, anyone in the title is likely the guest or subject.
4. State the actual claim or thesis from the title — don't paraphrase into vague abstractions.
5. Make clear why it belongs in the graph. If that cannot be inferred, say so naturally.
6. Make the workflow status clear. If unknown, say naturally that it has not been reviewed yet.
7. ABSOLUTELY FORBIDDEN: "discusses", "explores", "examines", "talks about", "delves into", "emphasizing the need for", "insightful for understanding", "relevant to". State things directly.

Examples:
- Title: "Dario Amodei — We are near the end of the exponential" / Channel: Dwarkesh Patel
  GOOD: "Dwarkesh Patel interview with Anthropic CEO Dario Amodei — argues we're nearing the end of exponential AI scaling. It was added via extraction and the exact reason it belongs in the graph is not yet inferred from the available context, and it has not been reviewed yet."
  BAD: "By Dario Amodei — discusses reaching the limits of exponential growth in AI, emphasizing the need for a critical perspective."

- Title: "The spell of language models" / Channel: Andrej Karpathy
  GOOD: "Karpathy talk on how LLMs work under the hood — tokenization, attention, and why they feel like magic but aren't. It was added via extraction and the exact reason it belongs in the graph is not yet inferred from the available context, and it has not been reviewed yet."
  BAD: "By Andrej Karpathy — explores the nature of language models and their capabilities."

Respond with ONLY valid JSON (no markdown, no code blocks):
{
  "enhancedDescription": "A comprehensive summary (3-6 paragraphs, 800-1500 chars). Cover key points, arguments, takeaways.",
  "nodeDescription": "<your natural description following the rules above>",
  "reasoning": "Brief explanation of classification choices"
}`;

    const text = await generateUtilityText({
      prompt,
      maxOutputTokens: 800,
      responseFormat: 'json',
      task: 'extraction_analysis',
    });

    let content = text || '{}';

    // Clean up the response - remove markdown code blocks if present
    content = content.replace(/```json\s*/g, '').replace(/```\s*/g, '').trim();

    const result = JSON.parse(content);

    return {
      enhancedDescription: result.enhancedDescription || description,
      nodeDescription: typeof result.nodeDescription === 'string' ? result.nodeDescription.slice(0, 500) : undefined,
      reasoning: result.reasoning || 'AI analysis completed'
    };
  } catch (error) {
    const message = error instanceof Error ? error.message : 'unknown error';
    console.warn('YouTube analysis fallback (using default description):', message);
    return {
      enhancedDescription: description,
      nodeDescription: undefined,
      reasoning: 'Fallback description used'
    };
  }
}

async function summariseTranscript(title: string, transcript: string): Promise<string | null> {
  if (!transcript || transcript.trim().length === 0) {
    return null;
  }

  // Limit transcript length to keep token costs manageable
  const MAX_CHARS = 16000;
  let excerpt = transcript.trim();
  if (excerpt.length > MAX_CHARS) {
    const head = excerpt.slice(0, MAX_CHARS / 2);
    const tail = excerpt.slice(-MAX_CHARS / 2);
    excerpt = `${head}\n[...]\n${tail}`;
  }

  const prompt = `You are summarising a long-form recording for a knowledge graph entry. Title: "${title}".

Using the transcript excerpt below, write a concise 3-4 sentence summary covering the main themes, notable claims, and outcomes. If specific terms, frameworks, or memorable lines appear, mention them. Keep the tone factual (no marketing language). If the excerpt appears truncated, note that the summary is based on the portion provided.

Transcript excerpt:
"""
${excerpt}
"""
`;

  try {
    const text = await generateUtilityText({
      prompt,
      maxOutputTokens: 400,
      task: 'extraction_analysis',
    });
    return text?.trim() || null;
  } catch (error) {
    console.warn('Transcript summarisation failed, falling back to AI analysis description:', error);
    return null;
  }
}

export const youtubeExtractTool = tool({
  description: 'Extract a YouTube transcript and metadata, create a node, and return summary details',
  inputSchema: z.object({
    url: z.string().describe('The YouTube video URL to add to knowledge base'),
    title: z.string().optional().describe('Custom title (auto-generated if not provided)')
  }),
  execute: async ({ url, title }) => {
    console.log('🎯 YouTubeExtract tool called with URL:', url);
    try {
      // Validate YouTube URL
      if (!url.includes('youtube.com') && !url.includes('youtu.be')) {
        return {
          success: false,
          error: 'Invalid YouTube URL format',
          data: null
        };
      }

      let result: { success: boolean; source?: string; metadata?: any; error?: string };

      console.log('📝 Using TypeScript yt-dlp extractor');
      try {
        const extractionResult = await extractYouTube(url);
        result = {
          success: extractionResult.success,
          source: extractionResult.chunk || extractionResult.content,
          metadata: {
            video_title: extractionResult.metadata.video_title,
            channel_name: extractionResult.metadata.channel_name,
            channel_url: extractionResult.metadata.channel_url,
            thumbnail_url: extractionResult.metadata.thumbnail_url,
            video_id: extractionResult.metadata.video_id,
            transcript_length: extractionResult.metadata.transcript_length,
            total_segments: extractionResult.metadata.total_segments,
            language: extractionResult.metadata.language,
            extraction_method: extractionResult.metadata.extraction_method
          },
          error: extractionResult.error
        };
      } catch (error: any) {
        result = {
          success: false,
          error: error.message || 'TypeScript extraction failed'
        };
      }

      if (!result.success || !result.source) {
        return {
          success: false,
          error: result.error || 'Failed to extract YouTube content',
          data: null
        };
      }

      console.log('🎯 YouTube extraction successful, analyzing with AI...');

      // Step 2: AI Analysis for enhanced metadata
      const aiAnalysis = await analyzeContentWithAI(
        result.metadata?.video_title || 'YouTube Video',
        `Video by ${result.metadata?.channel_name || 'Unknown Channel'}`,
        'youtube'
      );

      // Step 3: Create node with extracted content and AI analysis
      const nodeTitle = title || result.metadata?.video_title || `YouTube Video ${url.split('/').pop()?.split('?')[0]}`;
      const transcriptSummary = await summariseTranscript(nodeTitle, result.source);
      const fallbackDescriptionLead = `YouTube video from ${result.metadata?.channel_name || 'an unknown channel'} titled "${nodeTitle}"`;
      const finalDescription = ensureNodeDescription(aiAnalysis?.nodeDescription, fallbackDescriptionLead);
      const capturedAt = new Date().toISOString();

      const createResponse = await fetch(`${getInternalApiBaseUrl()}/api/nodes`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: nodeTitle,
          description: finalDescription,
          source: result.source,
          link: url,
          metadata: {
            type: 'youtube',
            state: 'not_processed',
            captured_method: 'youtube_extract',
            captured_by: 'human',
            source_metadata: {
              capture_origin: 'extraction',
              capture_path: 'youtube_extract',
              explicit_capture: true,
              source_url: url,
              video_id: result.metadata?.video_id,
              channel_name: result.metadata?.channel_name,
              channel_url: result.metadata?.channel_url,
              thumbnail_url: result.metadata?.thumbnail_url,
              transcript_length: result.metadata?.transcript_length,
              total_segments: result.metadata?.total_segments,
              language: result.metadata?.language,
              extraction_method: result.metadata?.extraction_method,
              summary_origin: transcriptSummary ? 'transcript_summary' : 'metadata_description',
              transcript_summary: transcriptSummary,
              captured_at: capturedAt,
              refined_at: capturedAt,
            }
          }
        })
      });

      const createResult = await createResponse.json();

      if (!createResponse.ok) {
        return {
          success: false,
          error: createResult.error || 'Failed to create item',
          data: null
        };
      }

      console.log('🎯 YouTubeExtract completed successfully');

      const formattedNode = createResult.data?.id
        ? formatNodeForChat({ id: createResult.data.id, title: nodeTitle })
        : nodeTitle;

      return {
        success: true,
        message: `Added ${formattedNode}`,
        data: {
          nodeId: createResult.data?.id,
          title: nodeTitle,
          contentLength: result.source.length,
          url: url
        }
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to extract YouTube content',
        data: null
      };
    }
  }
});
