import { NextRequest, NextResponse } from 'next/server';
import { nodeService } from '@/services/database';
import { eventBroadcaster } from '@/services/events';
import { embedNodeContent } from '@/services/embedding/ingestion';

export const runtime = 'nodejs';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    
    // Validate required fields  
    if (!body.nodeId) {
      return NextResponse.json({
        success: false,
        error: 'Missing required field: nodeId'
      }, { status: 400 });
    }

    // Get the node to validate it exists
    const node = await nodeService.getNodeById(body.nodeId);
    if (!node) {
      return NextResponse.json({
        success: false,
        error: 'Node not found'
      }, { status: 404 });
    }

    const results = await embedNodeContent(body.nodeId);

    if (results.success) {
      console.log('📡 Broadcasting NODE_UPDATED for embedding completion');
      eventBroadcaster.broadcast({
        type: 'NODE_UPDATED',
        data: { nodeId: body.nodeId }
      });
    }

    const statusCode = results.success ? 200 : 500;
    return NextResponse.json(results, { status: statusCode });
    
  } catch (error) {
    console.error('Error in ingestion endpoint:', error);
    
    return NextResponse.json({
      success: false,
      error: error instanceof Error ? error.message : 'Failed to process embedding request'
    }, { status: 500 });
  }
}
