import { tool } from 'ai';
import { z } from 'zod';
import { extractPaper } from '@/services/typescript/extractors/paper';
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
async function analyzeContentWithAI(title: string, description: string, contentType: string) {
  try {
    const prompt = `Analyze this ${contentType} content and provide classification.

Title: "${title}"
Description: "${description}"

CRITICAL — nodeDescription rules (max 500 chars):
1. Write natural prose, not labels or a checklist.
2. Make clear what this literally is: "Paper by…", "Research from…", "Preprint introducing…"
3. Name the authors if known from the metadata.
4. State the actual finding, method, or contribution — not "a study on X" but what they actually found or built.
5. Make clear why it belongs in the graph. If that cannot be inferred, say so naturally.
6. Make the workflow status clear. If unknown, say naturally that it has not been reviewed yet.
7. ABSOLUTELY FORBIDDEN: "discusses", "explores", "examines", "talks about", "delves into", "emphasizing the need for", "insightful for understanding", "relevant to". State things directly.

Examples:
- Title: "Attention Is All You Need" / Authors: Vaswani et al.
  GOOD: "Vaswani et al. introduce the Transformer architecture — replaces recurrence with self-attention for sequence modeling. It was added via extraction and the exact reason it belongs in the graph is not yet inferred from the available context, and it has not been reviewed yet."
  BAD: "This paper discusses a new architecture called the Transformer and explores its applications."

- Title: "Scaling Laws for Neural Language Models" / Authors: Kaplan et al.
  GOOD: "Kaplan et al. show that LLM performance scales as a power law with compute, data, and parameters — and compute matters most. It was added via extraction and the exact reason it belongs in the graph is not yet inferred from the available context, and it has not been reviewed yet."
  BAD: "A study examining how neural language models scale with different factors."

Respond with ONLY valid JSON (no markdown, no code blocks):
{
  "enhancedDescription": "A comprehensive summary (3-6 paragraphs, 800-1500 chars). Cover key points, arguments, takeaways.",
  "nodeDescription": "<your natural description following the rules above>",
  "tags": ["relevant", "semantic", "tags"],
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
      tags: Array.isArray(result.tags) ? result.tags : [],
      reasoning: result.reasoning || 'AI analysis completed'
    };
  } catch (error) {
    const message = error instanceof Error ? error.message : 'unknown error';
    console.warn('Paper analysis fallback (using default description):', message);
    return {
      enhancedDescription: description,
      nodeDescription: undefined,
      tags: [],
      reasoning: 'Fallback description used'
    };
  }
}

export const paperExtractTool = tool({
  description: 'Extract a PDF or research paper into a node with summary, metadata, and full-text source',
  inputSchema: z.object({
    url: z.string().describe('The PDF URL to add to inbox'),
    title: z.string().optional().describe('Custom title (auto-generated if not provided)')
  }),
  execute: async ({ url, title }) => {
    try {
      // Validate PDF URL
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        return {
          success: false,
          error: 'Invalid URL format - must start with http:// or https://',
          data: null
        };
      }

      // Check if URL likely points to a PDF
      if (!url.toLowerCase().includes('.pdf') && !url.includes('arxiv.org')) {
        return {
          success: false,
          error: 'URL does not appear to point to a PDF file',
          data: null
        };
      }

      let result: { success: boolean; source?: string; metadata?: any; error?: string };

      try {
        const extractionResult = await extractPaper(url);
        result = {
          success: true,
          source: extractionResult.chunk || extractionResult.content,
          metadata: {
            title: extractionResult.metadata.title,
            pages: extractionResult.metadata.pages,
            info: extractionResult.metadata.info,
            text_length: extractionResult.metadata.text_length,
            filename: extractionResult.metadata.filename,
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
          error: result.error || 'Failed to extract PDF content',
          data: null
        };
      }

      console.log('🎯 PDF extraction successful, analyzing with AI...');

      // Step 2: AI Analysis for enhanced metadata
      const aiAnalysis = await analyzeContentWithAI(
        result.metadata?.title || `PDF: ${new URL(url).pathname.split('/').pop()?.replace('.pdf', '')}`,
        result.source.substring(0, 2000) || 'PDF document content',
        'pdf'
      );

      // Step 3: Create node with extracted content and AI analysis
      const nodeTitle = title || result.metadata?.title || `PDF: ${new URL(url).pathname.split('/').pop()?.replace('.pdf', '')}`;
      const fallbackDescriptionLead = `PDF document titled "${nodeTitle}"`;
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
            type: 'pdf',
            state: 'not_processed',
            captured_method: 'paper_extract',
            captured_by: 'human',
            source_metadata: {
              capture_origin: 'extraction',
              capture_path: 'paper_extract',
              explicit_capture: true,
              source_url: url,
              hostname: new URL(url).hostname,
              author: result.metadata?.author || result.metadata?.info?.Author,
              pages: result.metadata?.pages,
              file_size: result.metadata?.file_size,
              content_length: result.source.length,
              extraction_method: result.metadata?.extraction_method || 'python_pdfplumber',
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

      console.log('🎯 PaperExtract completed successfully');

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
        error: error instanceof Error ? error.message : 'Failed to extract PDF content',
        data: null
      };
    }
  }
});
