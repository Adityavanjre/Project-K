import { describe, expect, it } from 'vitest';

import { scoreNodeSearchMatch } from '@/services/database/searchRanking';

describe('scoreNodeSearchMatch', () => {
  it('strongly prefers the closest title match for hub-node queries', () => {
    const query = 'building ra-h';

    const hubScore = scoreNodeSearchMatch({
      title: 'Building RA-H — Personal Knowledge Graph',
      description: 'Brad project hub',
      source: '',
      updated_at: '2026-03-23T00:00:00.000Z',
    }, query);

    const broadScore = scoreNodeSearchMatch({
      title: 'the ra-h project',
      description: 'Foundational project document for RA-H',
      source: '',
      updated_at: '2026-03-23T00:00:00.000Z',
    }, query);

    expect(hubScore).toBeGreaterThan(broadScore);
  });
});
