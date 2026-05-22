import { Scenario } from '../types';

export const scenario: Scenario = {
  id: 'youtube-extract',
  name: 'YouTube extract (optional)',
  description: 'Extract and ingest a YouTube video (requires network + API keys).',
  tools: ['youtubeExtract'],
  enabled: false,
  notes: 'Enable when network + API keys are configured; can be flaky.',
  input: {
    message: 'Add this video: https://www.youtube.com/watch?v=dQw4w9WgXcQ',
  },
  expect: {
    toolsCalledSoft: ['youtubeExtract'],
  },
};
