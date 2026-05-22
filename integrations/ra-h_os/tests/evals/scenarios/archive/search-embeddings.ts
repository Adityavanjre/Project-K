import { Scenario } from '../types';

export const scenario: Scenario = {
  id: 'search-embeddings',
  name: 'Embedding search triggers retrieval',
  description: 'Semantic search over stored knowledge.',
  tools: ['searchContentEmbeddings', 'queryNodes'],
  input: {
    message: 'Find my notes about deep learning architectures.',
  },
  expect: {
    toolsCalledSoft: ['searchContentEmbeddings'],
    responseContainsSoft: ['found', 'node'],
  },
};
