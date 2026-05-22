import { Scenario } from '../types';

export const scenario: Scenario = {
  id: 'paper-extract',
  name: 'Paper extract (optional)',
  description: 'Extract and ingest a PDF (requires network).',
  tools: ['paperExtract'],
  enabled: false,
  notes: 'Enable when network is available; can be slow.',
  input: {
    message: 'Add this paper: https://arxiv.org/pdf/1706.03762.pdf',
  },
  expect: {
    toolsCalledSoft: ['paperExtract'],
  },
};
