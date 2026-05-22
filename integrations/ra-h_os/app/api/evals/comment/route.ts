import { NextRequest } from 'next/server';
import { upsertEvalComment } from '@/services/evals/evalsStore';

export async function POST(request: NextRequest) {
  const evalsEnabled = process.env.RAH_EVALS_LOG === '1' || process.env.RAH_EVALS_LOG === 'true';
  if (process.env.NODE_ENV === 'production' || !evalsEnabled) {
    return new Response('Not Found', { status: 404 });
  }

  const body = await request.json();
  const traceId = typeof body?.traceId === 'string' ? body.traceId : null;
  const scenarioId = typeof body?.scenarioId === 'string' ? body.scenarioId : null;
  const comment = typeof body?.comment === 'string' ? body.comment : null;

  if (!traceId || comment === null) {
    return new Response(JSON.stringify({ error: 'Invalid payload' }), { status: 400 });
  }

  upsertEvalComment(traceId, scenarioId, comment);
  return new Response(JSON.stringify({ ok: true }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  });
}
