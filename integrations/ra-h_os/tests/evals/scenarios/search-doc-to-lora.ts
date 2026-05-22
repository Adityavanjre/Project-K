import { Scenario } from '../types';

export const scenario: Scenario = {
  id: 'search-doc-to-lora',
  name: 'Search Doc-to-LoRA',
  description: 'Free-text graph search should find the Doc-to-LoRA node by title without speculative context constraints or unnecessary web search.',
  categories: ['search'],
  tools: ['queryNodes'],
  input: {
    message: 'Find the recent Doc-to-LoRA stuff in my graph. Just return the matching graph node or nodes.',
  },
  expect: {
    toolsCalledSoft: ['queryNodes'],
    toolsNotCalled: ['webSearch'],
    responseContains: ['Doc-to-LoRA: Learning to Instantly Internalize Contexts'],
    maxLatencyMs: 15000,
    maxTotalTokens: 8000,
    maxEstimatedCostUsd: 0.08,
  },
  notes: 'Regression for the failure where free-text search was over-constrained by guessed organization hints and missed the existing Doc-to-LoRA node.',
};
