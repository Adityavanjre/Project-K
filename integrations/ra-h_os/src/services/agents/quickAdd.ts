import { summarizeToolExecution } from './toolResultUtils';
import { youtubeExtractTool } from '@/tools/other/youtubeExtract';
import { websiteExtractTool } from '@/tools/other/websiteExtract';
import { paperExtractTool } from '@/tools/other/paperExtract';
import { formatNodeForChat } from '@/tools/infrastructure/nodeFormatter';
import { summarizeTranscript } from './transcriptSummarizer';
import { eventBroadcaster } from '@/services/events';
import { getInternalApiBaseUrl } from '@/services/runtime/apiBase';

export type QuickAddMode = 'link' | 'text';

export type QuickAddInputType = 'youtube' | 'website' | 'pdf' | 'note' | 'chat';

export interface QuickAddInput {
  rawInput: string;
  mode?: QuickAddMode;
  description?: string;
}

export interface QuickAddResult {
  id: string;
  task: string;
  inputType: QuickAddInputType;
  status: 'queued' | 'completed' | 'failed';
  summary?: string;
  error?: string;
}

function isLikelyChatTranscript(raw: string): boolean {
  const newlineCount = (raw.match(/\n/g)?.length ?? 0);
  if (newlineCount >= 3 && raw.length > 300) return true;
  if (/\b\d{1,2}:\d{2}\b/.test(raw) && newlineCount >= 1) return true;
  if (/You said:|ChatGPT said:|Claude said:|Assistant:|User:/i.test(raw)) return true;
  return false;
}

export function detectInputType(raw: string, mode?: QuickAddMode): QuickAddInputType {
  const input = raw.trim();
  const isSingleLine = !input.includes('\n');

  if (mode === 'text') {
    return isLikelyChatTranscript(input) ? 'chat' : 'note';
  }

  if (isSingleLine) {
    if (/youtu(\.be|be\.com)/i.test(input)) return 'youtube';
    if (/\.pdf($|\?)/i.test(input) || /arxiv\.org\//i.test(input)) return 'pdf';
    if (/^https?:\/\//i.test(input)) return 'website';
  }

  if (mode === 'link') {
    return 'website';
  }

  if (!mode && isLikelyChatTranscript(input)) return 'chat';
  return 'note';
}

function buildTaskPrompt(type: QuickAddInputType, input: string): string {
  switch (type) {
    case 'youtube':
      return `Quick Add: extract YouTube video and create node → ${input}`;
    case 'website':
      return `Quick Add: extract webpage and create node → ${input}`;
    case 'pdf':
      return `Quick Add: extract PDF and create node → ${input}`;
    case 'note':
      return `Quick Add note: create a node from this text with optional context → ${input}`;
    case 'chat':
      return `Quick Add: import chat transcript and summarize → ${input.slice(0, 120)}${input.length > 120 ? '…' : ''}`;
  }
}

type ExtractionQuickAddType = Extract<QuickAddInputType, 'youtube' | 'website' | 'pdf'>;

const EXTRACTION_TOOL_MAP = {
  youtube: { toolName: 'youtubeExtract' as const, execute: youtubeExtractTool.execute },
  website: { toolName: 'websiteExtract' as const, execute: websiteExtractTool.execute },
  pdf: { toolName: 'paperExtract' as const, execute: paperExtractTool.execute },
};

interface SummaryParts {
  task: string;
  action: string;
  resultMessage: string;
  nodeReference: string;
}

interface ExtractionToolResultData {
  nodeId?: number;
  title?: string;
}

interface ExtractionToolResult {
  success?: boolean;
  error?: string;
  data?: ExtractionToolResultData | null;
  message?: string;
}

interface CreateNodeResponse {
  success?: boolean;
  data?: { id?: number; title?: string } | null;
  error?: string;
}

function deriveFallbackLinkTitle(rawUrl: string): string {
  const trimmed = rawUrl.trim();
  if (!trimmed) return 'Saved link';

  try {
    const parsed = new URL(trimmed);
    const hostname = parsed.hostname.replace(/^www\./, '');
    const lastSegment = parsed.pathname
      .split('/')
      .filter(Boolean)
      .pop()
      ?.replace(/[-_]+/g, ' ')
      .trim();

    if (lastSegment) {
      return `${hostname}: ${lastSegment}`.slice(0, 160);
    }

    return hostname.slice(0, 160);
  } catch {
    return trimmed.slice(0, 160);
  }
}

function buildStructuredSummary({ task, action, resultMessage, nodeReference }: SummaryParts): string {
  const normalizedResult = resultMessage?.trim().length ? resultMessage.trim() : `${action} completed.`;
  const normalizedNode = nodeReference || 'None';
  return [
    `Task: ${task}`,
    `Actions: ${action}`,
    `Result: ${normalizedResult}`,
    `Node: ${normalizedNode}`,
    'Context sources used: None',
    'Follow-up: None',
  ].join('\n');
}

function deriveNoteTitle(raw: string): string {
  const trimmed = raw.trim();
  if (!trimmed) {
    return 'Quick Add Note';
  }
  const sentenceMatch = trimmed.match(/^(.{1,120}?)([.!?]\s|\n|$)/);
  const candidate = sentenceMatch ? sentenceMatch[1] : trimmed.slice(0, 120);
  const title = candidate.replace(/\s+/g, ' ').trim();
  return title.length >= trimmed.length || title.length <= 120 ? title : `${title.slice(0, 117)}…`;
}

function deriveChatTitle(raw: string, summarySubject?: string): string {
  if (summarySubject && summarySubject.trim().length > 0) {
    return summarySubject.trim();
  }

  const trimmed = raw.trim();
  if (!trimmed) return 'Chat Transcript';
  const firstLine = trimmed.split('\n')[0];
  const cleaned = firstLine.replace(/You said:|ChatGPT said:|Claude said:/gi, '').trim();
  if (!cleaned) return 'Chat Transcript';
  return cleaned.length > 120 ? `${cleaned.slice(0, 117)}…` : cleaned;
}

function isExtractionToolResult(value: unknown): value is ExtractionToolResult {
  if (!value || typeof value !== 'object') {
    return false;
  }
  const candidate = value as Record<string, unknown>;
  if ('success' in candidate && typeof candidate.success !== 'boolean' && candidate.success !== undefined) {
    return false;
  }
  if ('error' in candidate && typeof candidate.error !== 'string' && candidate.error !== undefined && candidate.error !== null) {
    return false;
  }
  if ('data' in candidate && candidate.data !== undefined && candidate.data !== null && typeof candidate.data !== 'object') {
    return false;
  }
  return true;
}

function isCreateNodeResponse(value: unknown): value is CreateNodeResponse {
  if (!value || typeof value !== 'object') {
    return false;
  }
  const candidate = value as Record<string, unknown>;
  if ('success' in candidate && typeof candidate.success !== 'boolean' && candidate.success !== undefined) {
    return false;
  }
  if ('error' in candidate && typeof candidate.error !== 'string' && candidate.error !== undefined && candidate.error !== null) {
    return false;
  }
  if ('data' in candidate && candidate.data !== undefined && candidate.data !== null && typeof candidate.data !== 'object') {
    return false;
  }
  return true;
}

async function handleExtractionQuickAdd(type: ExtractionQuickAddType, url: string, task: string): Promise<string> {
  const { toolName, execute } = EXTRACTION_TOOL_MAP[type];
  if (!execute) {
    throw new Error(`Tool ${toolName} does not have an execute function`);
  }
  try {
    const rawResult = await execute({ url }, { toolCallId: 'quickadd-extract', messages: [] });

    if (!isExtractionToolResult(rawResult)) {
      throw new Error(`Unexpected response from ${toolName}`);
    }

    const toolResult = rawResult;

    if (!toolResult || toolResult.success === false) {
      const errorMessage = toolResult?.error || `Failed to execute ${toolName}`;
      throw new Error(errorMessage);
    }

    const summaryLine = summarizeToolExecution(toolName, { url }, toolResult);
    const nodeId = toolResult.data?.nodeId;
    const nodeTitle = typeof toolResult.data?.title === 'string' && toolResult.data.title.trim().length > 0
      ? toolResult.data.title.trim()
      : nodeId ? `Node ${nodeId}` : 'Created node';
    const nodeReference = nodeId ? formatNodeForChat({ id: nodeId, title: nodeTitle }) : 'None';

    return buildStructuredSummary({
      task,
      action: toolName,
      resultMessage: summaryLine,
      nodeReference,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : `Failed to execute ${toolName}`;
    const capturedAt = new Date().toISOString();
    const title = deriveFallbackLinkTitle(url);
    const description =
      `Link record for this source. RA-H could not correctly process the URL during ingestion because ${message}. Stored so the source is not lost and can be revisited later.`;
    const source = [
      `Original URL: ${url}`,
      `Ingestion failure: ${message}`,
      `Attempted pipeline: ${type}`,
    ].join('\n');

    const response = await fetch(`${getInternalApiBaseUrl()}/api/nodes`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        title,
        description,
        source,
        link: url,
        metadata: {
          type: 'website',
          state: 'not_processed',
          captured_method: 'quick_add_link_fallback',
          captured_by: 'human',
          source_metadata: {
            capture_origin: 'quick_add',
            capture_path: 'quick_add_link_fallback',
            explicit_capture: true,
            source_url: url,
            attempted_pipeline: type,
            extraction_failed: true,
            extraction_error: message,
            captured_at: capturedAt,
            refined_at: capturedAt,
          },
        },
      }),
    });

    const rawFallbackResult = await response.json();
    if (!isCreateNodeResponse(rawFallbackResult)) {
      throw new Error(message);
    }
    if (!response.ok) {
      throw new Error(rawFallbackResult.error || message);
    }

    const nodeId = rawFallbackResult.data?.id;
    const nodeReference = nodeId ? formatNodeForChat({ id: nodeId, title }) : 'None';
    const resultMessage = nodeId
      ? `Link ingestion failed, so RA-H saved a fallback node ${nodeReference}. Reason: ${message}`
      : `Link ingestion failed, so RA-H saved a fallback node. Reason: ${message}`;

    return buildStructuredSummary({
      task,
      action: `${toolName} (fallback)`,
      resultMessage,
      nodeReference,
    });
  }
}

async function handleNoteQuickAdd(rawInput: string, task: string, userDescription?: string): Promise<string> {
  const content = rawInput.trim();
  if (!content) {
    throw new Error('Input is required to create a note');
  }

  const capturedAt = new Date().toISOString();
  const title = deriveNoteTitle(content);
  const nodePayload: Record<string, unknown> = {
    title,
    source: content,
    metadata: {
      type: 'note',
      state: 'not_processed',
      captured_method: 'quick_add_note',
      captured_by: 'human',
      source_metadata: {
        capture_origin: 'quick_add',
        capture_path: 'quick_add_note',
        explicit_capture: true,
        input_type: 'note',
        captured_at: capturedAt,
        refined_at: capturedAt,
      },
    },
  };

  // If user provided a description, use it instead of auto-generating
  if (userDescription && userDescription.trim()) {
    nodePayload.description = userDescription.trim();
  }

  const response = await fetch(`${getInternalApiBaseUrl()}/api/nodes`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(nodePayload),
  });

  const rawResult = await response.json();

  if (!isCreateNodeResponse(rawResult)) {
    throw new Error('Unexpected response from node creation');
  }

  if (!response.ok) {
    throw new Error(rawResult?.error || 'Failed to create note');
  }

  const nodeId = rawResult?.data?.id;
  const nodeReference = nodeId ? formatNodeForChat({ id: nodeId, title }) : 'None';
  const resultMessage = nodeId ? `Created note ${nodeReference}.` : 'Created note.';

  return buildStructuredSummary({
    task,
    action: 'createNode',
    resultMessage,
    nodeReference,
  });
}

async function handleChatTranscriptQuickAdd(rawInput: string, task: string): Promise<string> {
  const transcript = rawInput.trim();
  if (!transcript) {
    throw new Error('Input is required to import a chat transcript');
  }

  const capturedAt = new Date().toISOString();
  const summaryResult = await summarizeTranscript(transcript);
  const baseSummary = summaryResult.summary?.trim() || 'Captured chat transcript. Review the raw transcript for full detail.';

  const intentLine = summaryResult.intent?.trim();
  const progressLine = summaryResult.progress?.trim();
  const stickingPoints = summaryResult.stickingPoints || [];

  const highlightSection = (summaryResult.highlights?.length ?? 0) > 0
    ? ['Highlights:', ...summaryResult.highlights!.map((item) => `- ${item}`)].join('\n')
    : null;

  const followUpSection = (summaryResult.openQuestions?.length ?? 0) > 0
    ? ['Open Questions:', ...summaryResult.openQuestions!.map((item) => `- ${item}`)].join('\n')
    : null;

  const stickingSection = stickingPoints.length > 0
    ? ['Where things felt stuck:', ...stickingPoints.map((item) => `- ${item}`)].join('\n')
    : null;

  const title = deriveChatTitle(transcript, summaryResult.subject);
  const wordCount = transcript.split(/\s+/).filter(Boolean).length;
  const compactSummary = baseSummary.replace(/\s+/g, ' ').trim();
  const whyDetail = intentLine
    ? `It belongs in the graph because it preserves context around ${intentLine.toLowerCase()}.`
    : 'It belongs in the graph because it preserves context from this conversation.';
  const statusDetail = 'It has not been reviewed yet.';
  const nodeDescription = `${compactSummary} ${whyDetail} ${statusDetail}`.slice(0, 500);

  const metadata = {
    type: 'chat',
    state: 'not_processed',
    captured_method: 'quick_add_chat',
    captured_by: 'human',
    source_metadata: {
      summary_subject: summaryResult.subject,
      summary_intent: summaryResult.intent,
      summary_progress: summaryResult.progress,
      highlights: summaryResult.highlights ?? [],
      open_questions: summaryResult.openQuestions ?? [],
      participants: summaryResult.participants ?? [],
      sticking_points: summaryResult.stickingPoints ?? [],
      transcript_length_chars: transcript.length,
      transcript_length_words: wordCount,
      transcript_truncated_for_summary: summaryResult.truncated ?? false,
      capture_origin: 'quick_add',
      capture_path: 'quick_add_chat',
      explicit_capture: true,
      input_type: 'chat',
      captured_at: capturedAt,
      summary_generated_at: capturedAt,
    },
  };

  const response = await fetch(`${getInternalApiBaseUrl()}/api/nodes`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      title,
      description: nodeDescription,
      source: transcript,
      metadata,
    }),
  });

  const rawResult = await response.json();

  if (!isCreateNodeResponse(rawResult)) {
    throw new Error('Unexpected response from node creation');
  }

  if (!response.ok) {
    throw new Error(rawResult?.error || 'Failed to create chat transcript node');
  }

  const nodeId = rawResult?.data?.id;
  const nodeReference = nodeId ? formatNodeForChat({ id: nodeId, title }) : 'None';
  const resultMessage = nodeId ? `Created chat transcript ${nodeReference}.` : 'Created chat transcript.';

  return buildStructuredSummary({
    task,
    action: 'chatTranscriptImport',
    resultMessage,
    nodeReference,
  });
}

export async function enqueueQuickAdd({ rawInput, mode, description }: QuickAddInput): Promise<QuickAddResult> {
  const inputType = detectInputType(rawInput, mode);
  const task = buildTaskPrompt(inputType, rawInput);
  const id = `qa_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;

  const result: QuickAddResult = {
    id,
    task,
    inputType,
    status: 'queued',
  };

  // Run async - fire and forget
  setImmediate(async () => {
    try {
      let summary: string;
      if (inputType === 'note') {
        summary = await handleNoteQuickAdd(rawInput, task, description);
      } else if (inputType === 'chat') {
        summary = await handleChatTranscriptQuickAdd(rawInput, task);
      } else {
        summary = await handleExtractionQuickAdd(inputType as ExtractionQuickAddType, rawInput, task);
      }

      console.log(`[QuickAdd] Completed: ${task}`);
      // Broadcast completion so ThreePanelLayout can remove the pending placeholder
      eventBroadcaster.broadcast({
        type: 'QUICK_ADD_COMPLETED',
        data: { quickAddId: id, source: 'quick-add' }
      });
      // Also broadcast NODE_CREATED to refresh the feed
      eventBroadcaster.broadcast({
        type: 'NODE_CREATED',
        data: { node: { title: task }, source: 'quick-add' }
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : 'unknown error';
      console.error(`[QuickAdd] Failed: ${task} - ${message}`);
      eventBroadcaster.broadcast({
        type: 'QUICK_ADD_FAILED',
        data: { quickAddId: id, error: message, source: 'quick-add' }
      });
    }
  });

  return result;
}
