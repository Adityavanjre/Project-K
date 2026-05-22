import { Scenario } from '../types';

export const scenario: Scenario = {
  id: 'simple-query',
  name: 'Simple query routes to helper',
  description: 'Baseline retrieval query against existing notes.',
  tools: ['queryNodes'],
  input: {
    message: 'What do I know about machine learning?',
  },
  expect: {
    toolsCalledSoft: ['queryNodes'],
    responseContainsSoft: ['node', 'found'],
  },
};
