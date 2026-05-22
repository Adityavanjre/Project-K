const WEAK_DESCRIPTION_PATTERNS = /\b(discusses|explores|examines|talks about|is about|delves into)\b/i;
const EXPLICIT_ENTITY_PATTERNS = /\b(article|artifact|book|brief|claim|company|concept|conversation|dataset|decision|document|episode|essay|event|guide|idea|insight|interview|lesson|link|node|note|paper|person|plan|placeholder|podcast|post|presentation|project|question|record|research|resource|skill|source|status|summary|talk|target|test node|thread|tool|transcript|tweet|update|video|website|workflow)\b/i;
const UNCERTAINTY_PATTERNS = /\b(likely|probably|possibly|appears to be|seems to be|unclear|uncertain)\b/i;
const WHY_PATTERNS = /(why added:|added (?:after|as|for|because|to)|follow-?on|queued for|saved for|relevant because|connected to|not inferred|belongs in the graph because|belongs here because|captures .* idea|ties directly into|ties into)/i;
const STATUS_PATTERNS = /(status:|queued|not yet reviewed|in progress|processed|reviewed|saved for later|to review|to read|to watch|to listen|draft|not yet published|unpublished)/i;
const GENERIC_EDGE_PATTERNS = /^(related|related to|connected|connected to|association|associated with)$/i;

export function validateExplicitDescription(description: string): string | null {
  const text = description.trim();
  if (text.length > 500) {
    return 'Description must be 500 characters or less.';
  }
  if (text.length < 24) {
    return 'Description must be explicit and substantial (at least 24 characters).';
  }
  if (WEAK_DESCRIPTION_PATTERNS.test(text)) {
    return 'Description is too vague. State exactly what this is and why it matters.';
  }
  if (!EXPLICIT_ENTITY_PATTERNS.test(text) && !UNCERTAINTY_PATTERNS.test(text)) {
    return 'Description must explicitly identify what this thing is, or state uncertainty explicitly.';
  }
  if (!WHY_PATTERNS.test(text)) {
    return 'Description must clearly indicate why this belongs in the graph. If that reason is unknown, say so naturally instead of inventing it.';
  }
  if (!STATUS_PATTERNS.test(text)) {
    return 'Description must make the workflow status clear. If status is unknown, say naturally that it has not been reviewed yet or is still in progress.';
  }
  return null;
}

interface DescriptionFallbackInput {
  title: string;
  description?: string | null;
}

export function coerceDescriptionForStorage(input: DescriptionFallbackInput): string {
  const candidate = typeof input.description === 'string' ? input.description.trim() : '';
  const clippedCandidate = candidate.slice(0, 500);
  const validationError = clippedCandidate ? validateExplicitDescription(clippedCandidate) : 'missing';

  if (!validationError && clippedCandidate) {
    return clippedCandidate;
  }

  const title = input.title.trim() || 'Untitled node';
  const opening = clippedCandidate || `${title}.`;
  const normalizedOpening = opening.endsWith('.') ? opening : `${opening}.`;
  const fallbackTail = ' It was added to the graph with incomplete context, so the exact reason it belongs here is not yet inferred, and it has not been reviewed yet.';

  return `${normalizedOpening}${fallbackTail}`.replace(/\s+/g, ' ').trim().slice(0, 500);
}

export function validateEdgeExplanation(explanation: string): string | null {
  const text = explanation.trim();
  if (text.length < 8) {
    return 'Edge explanation must be explicit enough to describe the relationship.';
  }
  if (GENERIC_EDGE_PATTERNS.test(text)) {
    return 'Edge explanation is too generic. State the actual relationship or explicitly note uncertainty.';
  }
  return null;
}
