import { getSQLiteClient } from '@/services/database/sqlite-client';

export interface AutoContextSummary {
  id: number;
  title: string;
  description: string;
  updatedAt: string;
  edgeCount: number;
}

function truncate(value: string | null | undefined, maxChars: number): string {
  const trimmed = (value || '').trim();
  if (trimmed.length <= maxChars) return trimmed;
  return `${trimmed.slice(0, maxChars)}...`;
}

function fetchAutoContextRows(limit: number): AutoContextSummary[] {
  const db = getSQLiteClient();
  const rows = db
    .query<{
      id: number;
      title: string | null;
      description: string | null;
      updated_at: string;
      edge_count: number | null;
    }>(
      `
        SELECT n.id,
               n.title,
               n.description,
               n.updated_at,
               COUNT(DISTINCT e.id) AS edge_count
          FROM nodes n
          LEFT JOIN edges e
            ON (e.from_node_id = n.id OR e.to_node_id = n.id)
         GROUP BY n.id
         ORDER BY edge_count DESC, n.updated_at DESC, n.id ASC
         LIMIT ?
      `,
      [limit]
    )
    .rows;

  return rows.map((row) => ({
    id: row.id,
    title: row.title || 'Untitled node',
    description: row.description || '',
    updatedAt: row.updated_at,
    edgeCount: Number(row.edge_count ?? 0),
  }));
}

export function getHubNodes(limit = 10): AutoContextSummary[] {
  return fetchAutoContextRows(limit);
}

export function buildHubNodesBlock(limit = 10): string | null {
  const summaries = getHubNodes(limit);
  if (summaries.length === 0) {
    return null;
  }

  const lines: string[] = [
    'Global Hub Diagnostics',
    'These are secondary graph diagnostics only. Do not treat them as the primary grounding mechanism.',
    '',
  ];

  summaries.forEach((summary, i) => {
    lines.push(`${i + 1}. [NODE:${summary.id}:"${summary.title}"] (${summary.edgeCount} edges)`);
    if (summary.description) {
      lines.push(`   ${truncate(summary.description, 140)}`);
    }
  });

  return lines.join('\n');
}

export function getAutoContextSummaries(limit = 10): AutoContextSummary[] {
  return getHubNodes(limit);
}

export function buildAutoContextBlock(limit = 10): string | null {
  return buildHubNodesBlock(limit);
}
