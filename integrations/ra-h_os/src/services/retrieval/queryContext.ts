import { chunkService } from '@/services/database/chunks';
import { edgeService } from '@/services/database/edges';
import { nodeService } from '@/services/database/nodes';
import { countHighSignalQueryTermMatches, scoreNodeSearchMatch } from '@/services/database/searchRanking';
import type { Node } from '@/types/database';

export type RetrievedContextNodeKind = 'focused' | 'query_match' | 'context_hint' | 'neighbor';

export interface RetrievedContextNode {
  id: number;
  title: string;
  description: string | null;
  link: string | null;
  updated_at: string;
  kind: RetrievedContextNodeKind;
  reason: string;
  seed_node_id?: number;
  search_rank?: number;
}

export interface RetrievedContextChunk {
  id: number;
  node_id: number;
  node_title: string;
  preview: string;
  similarity: number;
}

export interface QueryContextResult {
  query: string;
  shouldRetrieve: boolean;
  mode: 'skip' | 'focused' | 'query';
  reason: string;
  focused_node_id: number | null;
  nodes: RetrievedContextNode[];
  chunks: RetrievedContextChunk[];
}

export interface RetrieveQueryContextInput {
  query: string;
  focused_node_id?: number | null;
  limit?: number;
}

const LOW_SIGNAL_PATTERNS = [
  /^(yes|yeah|yep|no|nope|nah|ok|okay|cool|great|nice|thanks|thank you|sure|sounds good|go ahead|do it)[.!]?$/i,
  /^(hi|hello|hey)[.!]?$/i,
  /^(test|testing)[.!]?$/i,
];

const FOCUSED_SOURCE_PATTERN = /\b(this|focused|current)\s+(node|source|transcript|paper|article|video|document|note)\b|\b(inside|within|in)\s+(this|focused|current)\s+(node|source|transcript|paper|article|video|document|note)\b/i;
const SOURCE_DETAIL_PATTERN = /\b(quote|quotes|exact|specific|where|search|find|what did|what does|say|inside|within|transcript|paper|article|source|document|video)\b/i;
const USER_RECALL_PATTERN = /\b(what were (they|those)|what was (it|that)|what did i|what was my|what were my|do you remember|remind me)\b/i;
const FIRST_PERSON_PATTERN = /\b(i|my|me)\b/i;
const FIRST_PERSON_SHARE_PATTERN = /\b(i|my|me)\b.*\b(shared|mentioned|talked about|spoke about|said|posted)\b|\b(shared|mentioned|talked about|spoke about|said|posted)\b.*\b(i|my|me)\b/i;
const LOOKUP_PATTERN = /\b(find|look|search|show|get|pull)\b/i;
const EXPLICIT_HISTORY_QUERY_PATTERN = /\b(what have i said about|what did i say about)\b/i;
const DIRECT_NODE_TYPE_PATTERN = /\b(node|podcast|article|paper|video|note|idea|project|person|reflection|post|thread)\b/i;
const NOTE_HINT_PATTERN = /\b(idea|ideas|insight|insights|note|notes|thought|thoughts|reflection|reflections|realisation|realization|observation|observations|writing)\b/i;
const RECENT_REFERENCE_PATTERN = /\b(recent|recently|today|this morning|earlier|just)\b/i;
const NOTE_TERMS = new Set([
  'idea',
  'insight',
  'note',
  'node',
  'thought',
  'reflection',
  'realisation',
  'realization',
  'observation',
  'writing',
]);
const HIGH_SIGNAL_STOP_WORDS = new Set([
  'a', 'about', 'added', 'already', 'an', 'and', 'are', 'as', 'at', 'be', 'created',
  'db', 'did', 'do', 'does', 'earlier', 'find', 'for', 'from', 'get', 'had',
  'have', 'i', 'if', 'in', 'into', 'is', 'it', 'just', 'look', 'me', 'my',
  'being', 'said',
  'going', 'having',
  'node', 'of', 'on', 'pull', 'recent', 'recently', 'search', 'shared', 'show', 'some',
  'that', 'the', 'they', 'this', 'those', 'to', 'today', 'user', 'versus', 'was', 'were',
  'what', 'with', 'doing',
]);

function normalizeWhitespace(value: string): string {
  return value.replace(/\s+/g, ' ').trim();
}

function collapseCompactHyphenatedTerms(value: string): string {
  return value.replace(/\b([a-z0-9]{1,3})-([a-z0-9]{1,3})(?:-([a-z0-9]{1,3}))?\b/gi, (_match, a, b, c) => {
    return `${a}${b}${c ?? ''}`;
  });
}

function truncateText(value: string | null | undefined, maxLength = 180): string {
  const text = normalizeWhitespace(value || '');
  if (!text) return '';
  if (text.length <= maxLength) return text;
  return `${text.slice(0, maxLength - 1)}…`;
}

function queryTermCount(query: string): number {
  return normalizeWhitespace(query)
    .split(' ')
    .map(term => term.trim())
    .filter(Boolean)
    .length;
}

function singularizeTerm(term: string): string {
  if (term.endsWith('ies') && term.length > 4) {
    return `${term.slice(0, -3)}y`;
  }
  if (term.endsWith('s') && term.length > 4 && !term.endsWith('ss') && !term.endsWith('us')) {
    return term.slice(0, -1);
  }
  return term;
}

function extractRecallPhraseVariants(query: string): string[] {
  const normalized = collapseCompactHyphenatedTerms(normalizeWhitespace(query))
    .toLowerCase()
    .replace(/[^a-z0-9\s]+/g, ' ');
  const variants: string[] = [];
  const tokens = normalized.split(/\s+/).filter(Boolean);

  const pushVariant = (value: string) => {
    const compact = normalizeWhitespace(value);
    if (!compact || variants.includes(compact)) return;
    variants.push(compact);
  };

  if (/\ball\s+in\b/.test(normalized)) {
    pushVariant('all in');
  }

  if (/\bbackup(?:\s+plan)?\b/.test(normalized)) {
    pushVariant('backup plan');
    pushVariant('backup');
  }

  for (let index = 0; index < tokens.length - 1; index += 1) {
    const first = singularizeTerm(tokens[index]);
    const second = singularizeTerm(tokens[index + 1]);
    if (!first || !second) continue;

    const firstAllowed = first.length >= 4 && !HIGH_SIGNAL_STOP_WORDS.has(first);
    const secondAllowed = second.length >= 4 && !HIGH_SIGNAL_STOP_WORDS.has(second);
    if (firstAllowed && secondAllowed) {
      pushVariant(`${first} ${second}`);
    }
  }

  return variants.slice(0, 6);
}

function extractHighSignalTerms(query: string): string[] {
  const rawTerms = collapseCompactHyphenatedTerms(normalizeWhitespace(query))
    .toLowerCase()
    .replace(/[^a-z0-9\s]+/g, ' ')
    .split(/\s+/)
    .map(term => singularizeTerm(term.trim()))
    .filter(Boolean);

  const seen = new Set<string>();
  const result: string[] = [];

  for (const term of rawTerms) {
    if (term.length < 3) continue;
    if (HIGH_SIGNAL_STOP_WORDS.has(term)) continue;
    if (seen.has(term)) continue;
    seen.add(term);
    result.push(term);
  }

  return result;
}

function isLikelyUserNoteRecallQuery(query: string): boolean {
  const normalized = normalizeWhitespace(query);
  if (!normalized) return false;

  const explicitRecall = USER_RECALL_PATTERN.test(normalized);
  const firstPersonRecall = FIRST_PERSON_PATTERN.test(normalized) && /\bwhat\b/i.test(normalized);
  const explicitLookup = LOOKUP_PATTERN.test(normalized) && (FIRST_PERSON_PATTERN.test(normalized) || /\b(created|saved|wrote|added)\b/i.test(normalized));
  const firstPersonShareRecall = FIRST_PERSON_SHARE_PATTERN.test(normalized);
  const noteHint = NOTE_HINT_PATTERN.test(normalized);
  const recentHint = RECENT_REFERENCE_PATTERN.test(normalized);

  return (explicitRecall || firstPersonRecall || explicitLookup || firstPersonShareRecall) && (noteHint || recentHint);
}

function isDirectNodeRetrievalQuery(query: string): boolean {
  const normalized = normalizeWhitespace(query);
  if (!normalized) return false;

  const explicitHistoryQuery = EXPLICIT_HISTORY_QUERY_PATTERN.test(normalized);
  const explicitLookup = LOOKUP_PATTERN.test(normalized)
    && (FIRST_PERSON_PATTERN.test(normalized) || DIRECT_NODE_TYPE_PATTERN.test(normalized) || RECENT_REFERENCE_PATTERN.test(normalized));

  return explicitHistoryQuery
    || explicitLookup
    || FIRST_PERSON_SHARE_PATTERN.test(normalized)
    || isLikelyUserNoteRecallQuery(normalized);
}

function buildRecallSearchVariants(query: string): string[] {
  const terms = extractHighSignalTerms(query);
  if (terms.length === 0) return [];

  const topicalTerms = terms.filter(term => !NOTE_TERMS.has(term));
  const noteTerms = terms.filter(term => NOTE_TERMS.has(term));
  const phraseVariants = extractRecallPhraseVariants(query);

  const variants: string[] = [];
  const pushVariant = (value: string) => {
    const normalized = normalizeWhitespace(value);
    if (!normalized || variants.includes(normalized)) return;
    variants.push(normalized);
  };

  phraseVariants.forEach(pushVariant);

  if (phraseVariants.includes('all in') && topicalTerms.includes('backup')) {
    pushVariant('all in backup');
  }

  if (topicalTerms.length > 0 && noteTerms.length > 0) {
    pushVariant(`${topicalTerms.join(' ')} ${noteTerms[0]}`);
    pushVariant(`${topicalTerms[topicalTerms.length - 1]} ${noteTerms[0]}`);
  }
  if (topicalTerms.length >= 2) {
    pushVariant(topicalTerms.slice(0, 2).join(' '));
    pushVariant(topicalTerms.slice(-2).join(' '));
  }
  if (topicalTerms.length > 0) {
    pushVariant(topicalTerms.join(' '));
    const lastTopicalTerm = topicalTerms[topicalTerms.length - 1];
    if (lastTopicalTerm.length >= 6) {
      pushVariant(lastTopicalTerm);
    }
  }
  if (terms.length > 1) {
    pushVariant(terms.join(' '));
  }

  return variants.slice(0, 6);
}

function normalizeRecallText(value: string | null | undefined): string {
  return collapseCompactHyphenatedTerms(normalizeWhitespace(value || ''))
    .toLowerCase()
    .replace(/[^a-z0-9\s]+/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function scoreRecallMatch(node: Node, query: string): number {
  const normalizedTitle = normalizeRecallText(node.title);
  const normalizedDescription = normalizeRecallText(node.description);
  const normalizedSource = normalizeRecallText(node.source);
  const combined = `${normalizedTitle} ${normalizedDescription} ${normalizedSource}`.trim();
  const terms = extractHighSignalTerms(query);
  const phraseVariants = extractRecallPhraseVariants(query);

  let score = 0;

  if (isLikelyUserAuthoredNote(node)) score += 800;
  if (!node.link) score += 150;

  for (const phrase of phraseVariants) {
    const normalizedPhrase = normalizeRecallText(phrase);
    if (!normalizedPhrase) continue;

    if (normalizedTitle === normalizedPhrase) score += 2500;
    if (normalizedTitle.includes(normalizedPhrase)) score += 1400;
    if (normalizedDescription.includes(normalizedPhrase)) score += 700;
    if (normalizedSource.includes(normalizedPhrase)) score += 900;
  }

  const titleTermMatches = terms.filter(term => normalizedTitle.includes(term)).length;
  const totalTermMatches = terms.filter(term => combined.includes(term)).length;

  score += titleTermMatches * 250;
  score += totalTermMatches * 120;

  if (terms.length > 0 && titleTermMatches === terms.length) score += 1200;
  if (terms.length > 0 && totalTermMatches === terms.length) score += 700;

  if (node.updated_at) {
    score += new Date(node.updated_at).getTime() / 1e13;
  }

  return score;
}

function hasStrongRecallMatch(nodes: Node[], query: string): boolean {
  return nodes.some(node => scoreRecallMatch(node, query) >= 1800);
}

function isLikelyUserAuthoredNote(node: Node): boolean {
  return !node.link && node.metadata?.captured_by === 'human';
}

function buildDirectSearchVariants(query: string): string[] {
  const variants = [normalizeWhitespace(query), ...buildRecallSearchVariants(query)];
  return variants.filter((value, index) => value && variants.indexOf(value) === index).slice(0, 6);
}

async function findDirectQueryMatches(query: string, limit: number): Promise<Node[]> {
  const variants = buildDirectSearchVariants(query);
  const matches: Node[] = [];
  const seen = new Set<number>();

  for (const variant of variants) {
    const rows = await nodeService.searchNodes(variant, Math.max(limit, 8));

    for (const node of rows) {
      if (seen.has(node.id)) continue;
      seen.add(node.id);
      matches.push(node);
    }
  }

  return matches;
}

function rankDirectQueryMatches(nodes: Node[], query: string, directNodeRetrieval: boolean): Node[] {
  return [...nodes].sort((a, b) => {
    const scoreDiff = directNodeRetrieval
      ? scoreRecallMatch(b, query) - scoreRecallMatch(a, query)
      : scoreNodeSearchMatch(b, query) - scoreNodeSearchMatch(a, query);
    if (scoreDiff !== 0) return scoreDiff;
    return (b.updated_at || '').localeCompare(a.updated_at || '');
  });
}

export function isFocusedSourceRequest(query: string): boolean {
  return FOCUSED_SOURCE_PATTERN.test(query);
}

export function shouldRetrieveForQuery(query: string): boolean {
  const trimmed = normalizeWhitespace(query);
  if (!trimmed) return false;
  if (LOW_SIGNAL_PATTERNS.some(pattern => pattern.test(trimmed))) return false;

  if (isFocusedSourceRequest(trimmed)) return true;
  if (SOURCE_DETAIL_PATTERN.test(trimmed)) return true;

  return trimmed.length >= 12 || queryTermCount(trimmed) >= 3;
}

function addNodeWithReason(
  target: Map<number, RetrievedContextNode>,
  node: Node | null | undefined,
  input: { kind: RetrievedContextNodeKind; reason: string; seedNodeId?: number; searchRank?: number },
) {
  if (!node) return;

  const existing = target.get(node.id);
  if (existing) {
    if (input.kind === 'focused' && existing.kind !== 'focused') {
      existing.kind = 'focused';
    }
    existing.reason = existing.reason.includes(input.reason)
      ? existing.reason
      : `${existing.reason} ${input.reason}`.trim();
    if (input.seedNodeId && !existing.seed_node_id) {
      existing.seed_node_id = input.seedNodeId;
    }
    if (typeof input.searchRank === 'number') {
      existing.search_rank = typeof existing.search_rank === 'number'
        ? Math.min(existing.search_rank, input.searchRank)
        : input.searchRank;
    }
    return;
  }

  target.set(node.id, {
    id: node.id,
    title: node.title,
    description: node.description ?? null,
    link: node.link ?? null,
    updated_at: node.updated_at,
    kind: input.kind,
    reason: input.reason,
    seed_node_id: input.seedNodeId,
    search_rank: input.searchRank,
  });
}

function rankRetrievedNodes(nodes: RetrievedContextNode[]): RetrievedContextNode[] {
  const kindWeight: Record<RetrievedContextNodeKind, number> = {
    focused: 4,
    query_match: 3,
    context_hint: 2,
    neighbor: 1,
  };

  return [...nodes].sort((a, b) => {
    const kindDiff = kindWeight[b.kind] - kindWeight[a.kind];
    if (kindDiff !== 0) return kindDiff;
    const rankA = typeof a.search_rank === 'number' ? a.search_rank : Number.POSITIVE_INFINITY;
    const rankB = typeof b.search_rank === 'number' ? b.search_rank : Number.POSITIVE_INFINITY;
    if (rankA !== rankB) return rankA - rankB;
    return (b.updated_at || '').localeCompare(a.updated_at || '');
  });
}

export async function retrieveQueryContext(input: RetrieveQueryContextInput): Promise<QueryContextResult> {
  const query = normalizeWhitespace(input.query || '');
  const focusedNodeId = input.focused_node_id ?? null;
  const limit = Math.min(Math.max(input.limit ?? 6, 1), 12);
  const shouldRetrieve = shouldRetrieveForQuery(query);

  if (!shouldRetrieve) {
    return {
      query,
      shouldRetrieve: false,
      mode: 'skip',
      reason: 'Query is too lightweight or conversational to justify retrieval.',
      focused_node_id: focusedNodeId,
      nodes: [],
      chunks: [],
    };
  }

  const focusedRequest = isFocusedSourceRequest(query);
  const nodesById = new Map<number, RetrievedContextNode>();

  let focusedNode: Node | null = null;
  if (focusedNodeId) {
    focusedNode = await nodeService.getNodeById(focusedNodeId);
    const focusedOverlap = focusedNode ? countHighSignalQueryTermMatches(focusedNode, query) : 0;
    if (focusedNode && (focusedRequest || focusedOverlap >= 2)) {
      addNodeWithReason(nodesById, focusedNode, {
        kind: 'focused',
        reason: focusedRequest
          ? 'Focused node is the primary source for this request.'
          : 'Focused node strongly overlaps the user query and should be considered first.',
      });
    }
  }

  const searchLimit = Math.max(limit * 2, 8);
  const directNodeRetrieval = isDirectNodeRetrievalQuery(query);
  const directQueryMatches = rankDirectQueryMatches(
    await findDirectQueryMatches(query, searchLimit),
    query,
    directNodeRetrieval,
  );
  const strongRecallMatch = directNodeRetrieval && hasStrongRecallMatch(directQueryMatches, query);

  directQueryMatches.forEach((node, index) => {
    addNodeWithReason(nodesById, node, {
      kind: 'query_match',
      reason: directNodeRetrieval
        ? 'Matched the query through direct graph search for a specific existing node.'
        : 'Matched the query through direct graph search.',
      searchRank: index,
    });
  });

  if (!strongRecallMatch) {
    const rankedSeedNodes = rankRetrievedNodes(Array.from(nodesById.values())).slice(0, Math.max(3, limit));
    for (const seed of rankedSeedNodes.slice(0, 3)) {
      const connections = await edgeService.getNodeConnections(seed.id);
      connections.slice(0, 2).forEach((connection) => {
        addNodeWithReason(nodesById, connection.connected_node, {
          kind: 'neighbor',
          reason: `Connected to [NODE:${seed.id}:"${seed.title}"] via graph edges.`,
          seedNodeId: seed.id,
        });
      });
    }
  }

  const finalNodes = rankRetrievedNodes(Array.from(nodesById.values())).slice(0, limit);
  const chunkScopeNodeIds = focusedRequest && focusedNodeId
    ? [focusedNodeId]
    : SOURCE_DETAIL_PATTERN.test(query)
      ? finalNodes.slice(0, 3).map((node) => node.id)
      : [];

  const chunks = chunkScopeNodeIds.length > 0
    ? await chunkService.textSearchFallback(query, Math.min(4, limit), chunkScopeNodeIds)
    : [];

  return {
    query,
    shouldRetrieve: true,
    mode: focusedRequest ? 'focused' : 'query',
    reason: focusedRequest
      ? 'Focused-source request: use the focused node first, then broaden only if needed.'
      : directNodeRetrieval
        ? 'Direct node retrieval query: search the graph directly first and broaden only if needed.'
        : 'Substantive query: search the graph directly, then pull additional supporting context if helpful.',
    focused_node_id: focusedNodeId,
    nodes: finalNodes,
    chunks: chunks.map((chunk) => {
      const owner = finalNodes.find((node) => node.id === chunk.node_id) || directQueryMatches.find((node) => node.id === chunk.node_id);
      return {
        id: chunk.id,
        node_id: chunk.node_id,
        node_title: owner?.title || `Node ${chunk.node_id}`,
        preview: truncateText(chunk.text, 220),
        similarity: chunk.similarity,
      };
    }),
  };
}
