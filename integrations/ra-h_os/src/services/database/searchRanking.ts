import type { Node } from '@/types/database';

const SEARCH_STOP_WORDS = new Set([
  'a', 'about', 'added', 'already', 'an', 'and', 'are', 'as', 'at', 'be', 'by',
  'can', 'created', 'do', 'find', 'for', 'from', 'hello', 'i', 'in', 'into', 'is',
  'it', 'just', 'look', 'me', 'my', 'node', 'of', 'on', 'or', 'pull', 'recent',
  'recently', 'saved', 'shared', 'show', 'some', 'stuff', 'term', 'that', 'the', 'this',
  'to', 'versus', 'were', 'what', 'with', 'wrote', 'you', 'doing', 'going', 'having',
]);

function collapseCompactHyphenatedTerms(value: string): string {
  return value.replace(/\b([a-z0-9]{1,3})-([a-z0-9]{1,3})(?:-([a-z0-9]{1,3}))?\b/gi, (_match, a, b, c) => {
    return `${a}${b}${c ?? ''}`;
  });
}

function normalizeSearchText(value: string): string {
  return collapseCompactHyphenatedTerms(value)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
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

export function getHighSignalSearchTerms(query: string): string[] {
  const seen = new Set<string>();
  const terms: string[] = [];

  for (const rawTerm of normalizeSearchText(query).split(' ')) {
    const term = singularizeTerm(rawTerm.trim());
    if (!term || term.length < 3) continue;
    if (SEARCH_STOP_WORDS.has(term)) continue;
    if (seen.has(term)) continue;
    seen.add(term);
    terms.push(term);
  }

  return terms;
}

export function countHighSignalQueryTermMatches(
  node: Pick<Node, 'title' | 'description' | 'source'>,
  query: string,
): number {
  const terms = getHighSignalSearchTerms(query);
  if (terms.length === 0) return 0;

  const haystack = [
    normalizeSearchText(node.title || ''),
    normalizeSearchText(node.description || ''),
    normalizeSearchText(node.source || ''),
  ].join(' ');

  return terms.filter(term => haystack.includes(term)).length;
}

function countOccurrences(text: string, term: string): number {
  if (!text || !term) return 0;
  const matches = text.match(new RegExp(`\\b${term.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}\\b`, 'g'));
  return matches ? matches.length : 0;
}

function orderedTermMatches(text: string, terms: string[]): boolean {
  let position = 0;
  for (const term of terms) {
    const index = text.indexOf(term, position);
    if (index === -1) return false;
    position = index + term.length;
  }
  return terms.length > 0;
}

export function scoreNodeSearchMatch(node: Pick<Node, 'title' | 'description' | 'source' | 'updated_at'>, query: string): number {
  const normalizedQuery = normalizeSearchText(query);
  const normalizedTitle = normalizeSearchText(node.title || '');
  const normalizedDescription = normalizeSearchText(node.description || '');
  const normalizedSource = normalizeSearchText(node.source || '');
  const terms = getHighSignalSearchTerms(query);

  let score = 0;

  if (normalizedTitle === normalizedQuery) score += 2000;
  if (normalizedTitle.startsWith(normalizedQuery)) score += 1200;
  if (normalizedTitle.includes(normalizedQuery)) score += 700;
  if (orderedTermMatches(normalizedTitle, terms)) score += 500;
  if (terms.length > 0 && terms.every(term => normalizedTitle.includes(term))) score += 350;

  if (normalizedDescription.includes(normalizedQuery)) score += 180;
  if (orderedTermMatches(normalizedDescription, terms)) score += 120;
  if (normalizedSource.includes(normalizedQuery)) score += 90;

  const matchedTermCount = countHighSignalQueryTermMatches(node, query);
  score += matchedTermCount * 120;
  if (terms.length > 0 && matchedTermCount === terms.length) score += 300;

  for (const term of terms) {
    score += countOccurrences(normalizedTitle, term) * 40;
    score += countOccurrences(normalizedDescription, term) * 8;
    score += countOccurrences(normalizedSource, term) * 3;
  }

  if (node.updated_at) {
    score += new Date(node.updated_at).getTime() / 1e13;
  }

  return score;
}
