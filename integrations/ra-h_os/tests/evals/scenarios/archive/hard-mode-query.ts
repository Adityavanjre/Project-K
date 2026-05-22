import { Scenario } from '../types';

export const scenario: Scenario = {
  id: 'hard-mode-query',
  name: 'Hard mode retrieval query',
  description: 'Run a baseline retrieval query in hard mode.',
  tools: ['queryNodes', 'searchContentEmbeddings'],
  input: {
    message: 'What have I captured about plaintext productivity and tools?',
    mode: 'hard',
  },
  expect: {
    toolsCalledSoft: ['queryNodes'],
    responseContainsSoft: ['plaintext', 'productivity'],
  },
};
