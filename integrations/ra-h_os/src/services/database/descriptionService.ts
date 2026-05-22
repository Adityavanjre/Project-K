import { generateUtilityText } from '@/services/llm/provider';
import type { CanonicalNodeMetadata } from '@/types/database';

export interface DescriptionInput {
  title: string;
  source?: string;
  link?: string;
  metadata?: CanonicalNodeMetadata & {
    source?: string;
    channel_name?: string;
    author?: string;
    site_name?: string;
    original_filename?: string;
    pages?: number;
    text_length?: number;
  };
}

/**
 * Generate a context-rich description for a knowledge node.
 * The result must cover what the artifact is, why it is in the graph, and workflow status.
 */
export async function generateDescription(input: DescriptionInput): Promise<string> {
  try {
    const prompt = buildDescriptionPrompt(input);

    console.log(`[DescriptionService] Generating description for: "${input.title}"`);

    const text = await generateUtilityText({
      prompt,
      maxOutputTokens: 100,
      temperature: 0.3,
      task: 'description',
    });

    const description = sanitizeDescription(text, input);

    console.log(`[DescriptionService] Generated: "${description}"`);

    return description;
  } catch (error) {
    console.error('[DescriptionService] Error generating description:', error);
    // Fallback: just use the title — more useful than a vague template
    return `${input.title}. Added via Quick Add with no further context yet, so the reason it belongs in the graph is not fully inferred. It has not been reviewed yet.`.slice(0, 500);
  }
}

function buildDescriptionPrompt(input: DescriptionInput): string {
  const sourceMetadata = input.metadata?.source_metadata as Record<string, unknown> | undefined;
  const sourceType = typeof input.metadata?.type === 'string'
    ? input.metadata.type
    : typeof input.metadata?.source === 'string'
      ? input.metadata.source
      : '';
  const normalizedSource = sourceType.toLowerCase();
  const url = typeof input.link === 'string' ? input.link.trim() : '';

  // Best-effort creator hint from structured metadata (when available),
  // but never assume a particular extraction source (YouTube vs paper vs website vs note).
  const creatorHint =
    (typeof sourceMetadata?.author === 'string' ? sourceMetadata.author.trim() : '') ||
    (typeof sourceMetadata?.channel_name === 'string' ? sourceMetadata.channel_name.trim() : '') ||
    (typeof input.metadata?.author === 'string' ? input.metadata.author.trim() : '') ||
    (typeof input.metadata?.channel_name === 'string' ? input.metadata.channel_name.trim() : '') ||
    '';

  // Best-effort publisher / container hint (less ideal than a true author, but better than nothing).
  const publisherHint =
    (typeof sourceMetadata?.site_name === 'string' ? sourceMetadata.site_name.trim() : '') ||
    (typeof input.metadata?.site_name === 'string' ? input.metadata.site_name.trim() : '') ||
    '';

  const likelyExternal =
    Boolean(url) ||
    normalizedSource.includes('youtube') ||
    normalizedSource.includes('extract') ||
    normalizedSource.includes('paper') ||
    normalizedSource.includes('pdf') ||
    normalizedSource.includes('website');

  const likelyUserAuthored =
    !likelyExternal &&
    (normalizedSource.includes('quick-add-note') ||
      normalizedSource.includes('quick-add-chat') ||
      normalizedSource.includes('note') ||
      normalizedSource.length === 0);

  const lines: string[] = [`Title: ${input.title}`];

  if (input.link) lines.push(`URL: ${input.link}`);
  if (sourceMetadata?.channel_name || input.metadata?.channel_name) lines.push(`Channel: ${sourceMetadata?.channel_name || input.metadata?.channel_name}`);
  if (sourceMetadata?.author || input.metadata?.author) lines.push(`Author: ${sourceMetadata?.author || input.metadata?.author}`);
  if (sourceMetadata?.site_name || input.metadata?.site_name) lines.push(`Site: ${sourceMetadata?.site_name || input.metadata?.site_name}`);
  if (sourceType) lines.push(`Source type: ${sourceType}`);
  if (sourceMetadata?.original_filename || input.metadata?.original_filename) lines.push(`Original filename: ${sourceMetadata?.original_filename || input.metadata?.original_filename}`);
  if (typeof sourceMetadata?.pages === 'number' || typeof input.metadata?.pages === 'number') lines.push(`Pages: ${sourceMetadata?.pages || input.metadata?.pages}`);
  if (typeof sourceMetadata?.text_length === 'number' || typeof input.metadata?.text_length === 'number') lines.push(`Text length: ${sourceMetadata?.text_length || input.metadata?.text_length}`);
  if (creatorHint) lines.push(`Creator hint: ${creatorHint}`);
  if (publisherHint) lines.push(`Publisher hint: ${publisherHint}`);
  lines.push(`Likely user-authored: ${likelyUserAuthored ? 'yes' : 'no'}`);

  const sourcePreview = input.source?.slice(0, 800) || '';
  if (sourcePreview) lines.push(`Source excerpt: ${sourcePreview}${input.source && input.source.length > 800 ? '...' : ''}`);

  return `Write a natural description for this knowledge node. Max 500 characters.

The description should read like normal prose, not a template or checklist. In one compact paragraph or a few natural sentences, make sure it clearly conveys:
1) what this literally is
2) why it is in Brad's graph
3) its current status in Brad's workflow

RULES:
1) Name the format only if the context clearly supports it: "Podcast episode where…", "Blog post arguing…", "Personal note capturing…", "Research paper showing…", "Resume/CV for…", "Document likely containing…", "Idea that…"
2) Name people by role — channel/host is the creator, title figures are guests/subjects. Use the Creator hint if available.
3) State the actual claim, finding, or insight from the content — not a vague summary of the topic.
4) If the reason it belongs in the graph cannot be inferred from title, source excerpt, URL, or metadata, say that naturally rather than inventing context.
5) If workflow status is unknown, say that naturally, for example by noting it has not been reviewed yet.
6) Do NOT use labels or headings like "WHAT:", "WHY:", or "STATUS:".
7) ABSOLUTELY FORBIDDEN — these words and phrases will be rejected: "discusses", "explores", "examines", "talks about", "is about", "delves into", "emphasizing the need for", "insightful for understanding", "relevant to", "important for", "useful for understanding". State things directly instead.
8) Do NOT start with "Your note —" or "This note —". Use a concrete opener tied to the actual artifact.
9) If the artifact type is unclear, say so explicitly using words like "likely", "appears to be", or "unclear" rather than guessing a confident format.

GOOD: "CS153 lecture by ElevenLabs co-founder Mati Staniszewski on production AI voice systems. Brad likely saved it as a follow-on to his interest in the ElevenLabs voice pipeline after CS153 ep.1, and it has not been reviewed yet."
GOOD: "YouTube talk by Lex Fridman with Sam Altman on AGI timelines and OpenAI strategy. It was added via Quick Add and the exact reason it belongs in the graph is not yet inferred from the available context, and it has not been reviewed yet."
GOOD: "Personal note capturing a recurring pattern: morning optimism reverses to evening pessimism. It belongs in the graph because it points to a belief-level pattern worth tracking against Brad's decision quality, and it has already been processed."
BAD: "By Dario Amodei — discusses reaching the limits of exponential growth in AI, emphasizing the need for a critical perspective on future advancements."
BAD: "This article explores ideas about how software is changing."

Return ONLY the description text. Nothing else.

${lines.join('\n')}`;
}

function sanitizeDescription(rawText: string, input: DescriptionInput): string {
  const singleLine = rawText
    .trim()
    .replace(/\s+/g, ' ')
    .replace(/^["']|["']$/g, '');

  if (!singleLine) {
    return `${input.title}. Added via Quick Add with no further context yet, so the reason it belongs in the graph is not fully inferred. It has not been reviewed yet.`.slice(0, 500);
  }

  // Guard against weak generic openings from model drift.
  const noGenericPrefix = singleLine.replace(
    /^(your note|this note)\s*[—:-]\s*/i,
    'Personal note capturing '
  );

  return noGenericPrefix.slice(0, 500);
}

export const descriptionService = {
  generateDescription
};
