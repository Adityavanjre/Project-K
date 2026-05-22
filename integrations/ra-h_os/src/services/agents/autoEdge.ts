/**
 * Potential edge suggestion helper.
 *
 * This module no longer writes edges automatically. It only identifies
 * obvious connection candidates so an agent or UI can propose them first.
 */

import { nodeService } from '@/services/database';
import { Node } from '@/types/database';

export interface PotentialEdgeSuggestion {
  from_node_id: number;
  to_node_id: number;
  to_node_title: string;
  explanation: string;
  candidate_text: string;
}

function cleanEntityCandidate(candidate: string): string {
  let cleaned = candidate.trim();

  const prefixPatterns = [
    /^by\s+/i,
    /^author:\s*/i,
    /^written by\s+/i,
    /^from\s+/i,
    /^via\s+/i,
    /^featuring\s+/i,
    /^with\s+/i,
    /^hosted by\s+/i,
  ];

  for (const pattern of prefixPatterns) {
    cleaned = cleaned.replace(pattern, '');
  }

  return cleaned.trim();
}

function isGenericPhrase(phrase: string): boolean {
  const normalized = phrase.toLowerCase();
  const genericTerms = [
    'the author', 'the article', 'the book', 'the podcast',
    'this article', 'this book', 'this podcast', 'this paper',
    'new research', 'recent study', 'key points', 'main ideas',
    'artificial intelligence', 'machine learning', 'deep learning',
    'first section', 'last section', 'next chapter',
    'united states', 'new york', 'san francisco', 'silicon valley'
  ];

  return genericTerms.some(term => normalized === term || normalized.startsWith(`${term} `));
}

function extractCandidateEntities(text: string): string[] {
  if (!text || typeof text !== 'string') return [];

  const candidates: Set<string> = new Set();

  const byPattern = /\b[Bb]y\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+){0,2})\b/g;
  let match;
  while ((match = byPattern.exec(text)) !== null) {
    const name = match[1].trim();
    if (name.length >= 4 && !isGenericPhrase(name)) {
      candidates.add(name);
    }
  }

  const properNamePattern = /\b([A-Z][a-z]+(?:\s+[A-Z][a-z]+){1,3})\b/g;
  while ((match = properNamePattern.exec(text)) !== null) {
    const cleaned = cleanEntityCandidate(match[1].trim());
    if (cleaned.length >= 4 && !isGenericPhrase(cleaned)) {
      candidates.add(cleaned);
    }
  }

  const quotedPattern = /["']([^"']{3,60})["']/g;
  while ((match = quotedPattern.exec(text)) !== null) {
    const title = match[1].trim();
    if (title.length >= 3 && !isGenericPhrase(title)) {
      candidates.add(title);
    }
  }

  const orgPattern = /\b(OpenAI|DeepMind|Anthropic|Google|Microsoft|Meta|Apple|Amazon|Y Combinator|YC|Stripe|Coinbase|Fly\.io|Vercel|Cloudflare)\b/gi;
  while ((match = orgPattern.exec(text)) !== null) {
    candidates.add(match[1]);
  }

  return Array.from(candidates);
}

async function findMatchingEntityNodes(candidates: string[]): Promise<Map<string, Node>> {
  const matches = new Map<string, Node>();
  if (candidates.length === 0) return matches;

  const allNodes = await nodeService.getNodes({ limit: 10000 });

  for (const candidate of candidates) {
    const normalizedCandidate = candidate.toLowerCase().trim();
    const matchingNode = allNodes.find((node) => {
      const normalizedTitle = (node.title || '').toLowerCase().trim();
      return normalizedTitle === normalizedCandidate && node.title.length < 80;
    });

    if (matchingNode) {
      matches.set(candidate, matchingNode);
    }
  }

  return matches;
}

export async function suggestPotentialEdgesForNode(nodeId: number): Promise<PotentialEdgeSuggestion[]> {
  const node = await nodeService.getNodeById(nodeId);
  if (!node) {
    console.warn(`[autoEdge] Node ${nodeId} not found, skipping suggestion lookup`);
    return [];
  }

  const description = node.description || '';
  if (!description || description.length < 10) {
    return [];
  }

  const candidates = extractCandidateEntities(description);
  if (candidates.length === 0) {
    return [];
  }

  const matches = await findMatchingEntityNodes(candidates);
  const suggestions: PotentialEdgeSuggestion[] = [];

  for (const [candidateText, entityNode] of matches) {
    if (entityNode.id === nodeId) continue;
    suggestions.push({
      from_node_id: nodeId,
      to_node_id: entityNode.id,
      to_node_title: entityNode.title,
      explanation: `Explicitly mentioned in description: "${candidateText}"`,
      candidate_text: candidateText,
    });
  }

  return suggestions;
}
