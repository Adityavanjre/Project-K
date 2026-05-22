import { NextRequest, NextResponse } from 'next/server';
import { applyRequestSupabaseAuth } from '@/services/auth/internalAuth';
import { retrieveQueryContext } from '@/services/retrieval/queryContext';

export const runtime = 'nodejs';

export async function POST(request: NextRequest) {
  const cleanupAuth = applyRequestSupabaseAuth(request);

  try {
    const body = await request.json();
    const query = typeof body.query === 'string' ? body.query : '';

    if (!query.trim()) {
      return NextResponse.json({
        success: false,
        error: 'Missing required field: query',
      }, { status: 400 });
    }

    const result = await retrieveQueryContext({
      query,
      focused_node_id: typeof body.focused_node_id === 'number' ? body.focused_node_id : null,
      limit: typeof body.limit === 'number' ? body.limit : undefined,
    });

    return NextResponse.json({
      success: true,
      data: result,
    });
  } catch (error) {
    return NextResponse.json({
      success: false,
      error: error instanceof Error ? error.message : 'Failed to retrieve query context',
    }, { status: 500 });
  } finally {
    cleanupAuth();
  }
}
