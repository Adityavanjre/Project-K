import { Scenario } from '../types';

export const scenario: Scenario = {
  id: 'website-extract',
  name: 'Website extract (optional)',
  description: 'Extract and ingest a webpage (requires network).',
  tools: ['websiteExtract'],
  enabled: false,
  notes: 'Enable when network is available; can be slow.',
  input: {
    message: 'Add this article: https://sive.rs/plaintext',
  },
  expect: {
    toolsCalledSoft: ['websiteExtract'],
  },
};
