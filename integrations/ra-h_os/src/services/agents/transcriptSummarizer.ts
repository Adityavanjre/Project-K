import { generateUtilityText } from '@/services/llm/provider';

export interface TranscriptSummaryResult {
  subject?: string;
  summary?: string;
  intent?: string;
  progress?: string;
  highlights?: string[];
  openQuestions?: string[];
  participants?: string[];
  stickingPoints?: string[];
  truncated?: boolean;
}

const MAX_TRANSCRIPT_CHARS = 15000;

function buildPrompt(snippet: string) {
  return `You will receive a raw conversation transcript copy/pasted from various chat apps. It may contain timestamps, "You said:", "ChatGPT said:", missing speaker labels, or UI noise like "Thought for 11s".

Return ONLY valid JSON with this exact shape (no markdown, no commentary):
{
  "subject": "Short descriptive thread title",
  "summary": "2-3 sentence narrative describing what was discussed and why it matters",
  "intent": "What the human seemed to be trying to accomplish (1 sentence, second-person)",
  "progress": "Where the conversation actually moved forward (1-2 sentences, second-person)",
  "stickingPoints": ["Concise phrases describing where you got stuck or needed help"],
  "highlights": ["Key takeaway 1", "Key takeaway 2"],
  "openQuestions": ["Follow-up 1"],
  "participants": ["user", "assistant"]
}

Guidelines:
- Never mention the formatting noise; describe the substance.
- Keep highlights concise bullet phrases (<=12 words).
- Sticking points should be authentic blockers, not restatements of highlights.
- Open questions are the clearest next steps; omit the array when nothing actionable exists.
- Participants should be lowercase role labels (user, assistant, reviewer, etc.).
- Prefer phrasing that sounds like you're talking directly to the user ("you were trying to...").

Transcript:
${snippet}`;
}

export async function summarizeTranscript(transcript: string): Promise<TranscriptSummaryResult> {
  const limited = transcript.length > MAX_TRANSCRIPT_CHARS
    ? transcript.slice(0, MAX_TRANSCRIPT_CHARS)
    : transcript;

  try {
    const text = await generateUtilityText({
      prompt: buildPrompt(limited),
      maxOutputTokens: 600,
      responseFormat: 'json',
      task: 'transcript_summary',
    });

    let content = text || '';
    content = content.replace(/```json/gi, '').replace(/```/g, '').trim();
    const parsed = JSON.parse(content);

    return {
      subject: typeof parsed.subject === 'string' ? parsed.subject : undefined,
      summary: typeof parsed.summary === 'string' ? parsed.summary : undefined,
      intent: typeof parsed.intent === 'string' ? parsed.intent : undefined,
      progress: typeof parsed.progress === 'string' ? parsed.progress : undefined,
      highlights: Array.isArray(parsed.highlights)
        ? parsed.highlights.filter((h: unknown) => typeof h === 'string' && h.trim().length > 0)
        : [],
      openQuestions: Array.isArray(parsed.openQuestions)
        ? parsed.openQuestions.filter((q: unknown) => typeof q === 'string' && q.trim().length > 0)
        : [],
      participants: Array.isArray(parsed.participants)
        ? parsed.participants.filter((p: unknown) => typeof p === 'string' && p.trim().length > 0)
        : [],
      stickingPoints: Array.isArray(parsed.stickingPoints)
        ? parsed.stickingPoints.filter((s: unknown) => typeof s === 'string' && s.trim().length > 0)
        : [],
      truncated: transcript.length > MAX_TRANSCRIPT_CHARS,
    };
  } catch (error) {
    console.warn('[TranscriptSummarizer] Failed to summarize transcript, falling back', error);
    return {
      summary: '',
      intent: '',
      progress: '',
      highlights: [],
      openQuestions: [],
      participants: [],
      stickingPoints: [],
      truncated: transcript.length > MAX_TRANSCRIPT_CHARS,
    };
  }
}
