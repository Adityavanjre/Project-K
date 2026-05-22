import { Scenario } from '../types';

export const scenario: Scenario = {
  id: 'hub-traversal',
  name: 'Hub traversal',
  description: 'Traverse from core hubs and connected nodes to synthesize what the user should focus on next.',
  tools: ['queryEdge'],
  suites: ['traversal', 'internal'],
  input: {
    message: 'Traverse from my hub nodes "Building RA-H — Personal Knowledge Graph" and "Nature of Intelligence & Consciousness" and tell me what I should focus on next and why.',
  },
  expect: {
    toolsCalledSoft: ['queryEdge'],
    responseContainsSoft: ['focus', 'why'],
    maxLatencyMs: 45000,
    maxTotalTokens: 16000,
    maxEstimatedCostUsd: 0.18,
  },
};
