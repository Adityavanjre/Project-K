import { NextRequest, NextResponse } from 'next/server';
import { nodeService } from '@/services/database';
import { getSQLiteClient } from '@/services/database/sqlite-client';

export const runtime = 'nodejs';

export async function GET(request: NextRequest) {
  try {
    const integrity = getSQLiteClient().getIntegrityReport();
    const searchParams = request.nextUrl.searchParams;
    const query = searchParams.get('q');
    const limit = parseInt(searchParams.get('limit') || '10');
    
    if (!query || query.trim() === '') {
      return NextResponse.json({
        success: false,
        error: 'Missing required parameter: q (search query)'
      }, { status: 400 });
    }

    if (query.length < 2) {
      return NextResponse.json({
        success: false,
        error: 'Search query must be at least 2 characters long'
      }, { status: 400 });
    }

    const nodes = await nodeService.searchNodes(query.trim(), Math.min(limit, 50));
    
    // Return minimal data for edge creation UI
    const results = nodes.map(node => ({
      id: node.id,
      title: node.title,
    }));
    
    return NextResponse.json({
      success: true,
      data: results,
      count: results.length,
      query: query.trim(),
      degraded: integrity.state !== 'healthy',
      integrityState: integrity.state,
      integritySummary: integrity.state !== 'healthy' ? integrity.summary : undefined,
    });
  } catch (error) {
    console.error('Error searching nodes:', error);
    
    return NextResponse.json({
      success: false,
      error: error instanceof Error ? error.message : 'Failed to search nodes'
    }, { status: 500 });
  }
}
