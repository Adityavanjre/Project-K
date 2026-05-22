import { tool } from 'ai';
import { z } from 'zod';
import { extractWebsite } from '@/services/typescript/extractors/website';
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

function inferWebsiteContentType(url: string): 'website' | 'tweet' {
  try {
    const hostname = new URL(url).hostname.toLowerCase();
    return hostname === 'x.com' || hostname.endsWith('.x.com') || hostname === 'twitter.com' || hostname.endsWith('.twitter.com')
      ? 'tweet'
      : 'website';
  } catch {
    return 'website';
  }
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
2. Make clear what this literally is using explicit entity words like "Blog post by…", "Article from…", "Essay arguing…", "Tutorial on…", "Thread by…", "Tweet by…", "Post by…"
3. Name the author/site if known from the metadata.
4. State the actual claim or thesis — don't paraphrase into vague abstractions.
5. Make clear why it belongs in the graph. If that cannot be inferred, say so naturally.
6. Make the workflow status clear. If unknown, say naturally that it has not been reviewed yet.
7. ABSOLUTELY FORBIDDEN: "discusses", "explores", "examines", "talks about", "delves into", "emphasizing the need for", "insightful for understanding", "relevant to". State things directly.

Examples:
- Title: "Software is eating the world — again" / Author: Andrej Karpathy
  GOOD: "Karpathy's blog post arguing AI agents make software fluid — they can rip functionality from repos instead of taking dependencies. It was added via extraction and the exact reason it belongs in the graph is not yet inferred from the available context, and it has not been reviewed yet."
  BAD: "By Karpathy — discusses the importance of software becoming more fluid and malleable with agents."

- Title: "The case for slowing down AI" / Site: The Atlantic
  GOOD: "Atlantic article making the case that AI labs should voluntarily slow capability research until safety catches up. It was added via extraction and the exact reason it belongs in the graph is not yet inferred from the available context, and it has not been reviewed yet."
  BAD: "This article explores ideas about slowing down AI development and its implications."

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
    console.warn('Website analysis fallback (using default description):', message);
    return {
      enhancedDescription: description,
      nodeDescription: undefined,
      reasoning: 'Fallback description used'
    };
  }
}

export const websiteExtractTool = tool({
  description: 'Extract website content and metadata into a node with summary and raw source text',
  inputSchema: z.object({
    url: z.string().describe('The website URL to add to knowledge base'),
    title: z.string().optional().describe('Custom title (auto-generated if not provided)')
  }),
  execute: async ({ url, title }) => {
    try {
      // Validate URL format
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        return {
          success: false,
          error: 'Invalid URL format - must start with http:// or https://',
          data: null
        };
      }

      let result: { success: boolean; source?: string; metadata?: any; error?: string };

      try {
        const extractionResult = await extractWebsite(url);
        result = {
          success: true,
          source: extractionResult.chunk || extractionResult.content,
          metadata: {
            title: extractionResult.metadata.title,
            author: extractionResult.metadata.author,
            date: extractionResult.metadata.date,
            description: extractionResult.metadata.description,
            og_image: extractionResult.metadata.og_image,
            site_name: extractionResult.metadata.site_name,
            extraction_method: 'typescript'
          }
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
          error: result.error || 'Failed to extract website content',
          data: null
        };
      }

      console.log('🎯 Website extraction successful, analyzing with AI...');

      // Step 2: AI Analysis for enhanced metadata
      const contentType = inferWebsiteContentType(url);
      const aiAnalysis = await analyzeContentWithAI(
        result.metadata?.title || `Website: ${new URL(url).hostname}`,
        result.source.substring(0, 2000) || 'Website content',
        contentType
      );

      // Step 3: Create node with extracted content and AI analysis
      const nodeTitle = title || result.metadata?.title || `Website: ${new URL(url).hostname}`;
      const fallbackDescriptionLead = `${contentType === 'tweet' ? 'Tweet' : 'Website article'} from ${result.metadata?.author || result.metadata?.site_name || new URL(url).hostname} titled "${nodeTitle}"`;
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
          event_date: result.metadata?.published_date || result.metadata?.date || null,
          metadata: {
            type: contentType,
            state: 'not_processed',
            captured_method: 'website_extract',
            captured_by: 'human',
            source_metadata: {
              capture_origin: 'extraction',
              capture_path: 'website_extract',
              explicit_capture: true,
              source_url: url,
              hostname: new URL(url).hostname,
              author: result.metadata?.author,
              published_date: result.metadata?.published_date || result.metadata?.date,
              content_length: result.source.length,
              extraction_method: result.metadata?.extraction_method || 'python_beautifulsoup',
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
          error: createResult.error || 'Failed to create node',
          data: null
        };
      }

      console.log('🎯 WebsiteExtract completed successfully');

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
        error: error instanceof Error ? error.message : 'Failed to extract website content',
        data: null
      };
    }
  }
});
