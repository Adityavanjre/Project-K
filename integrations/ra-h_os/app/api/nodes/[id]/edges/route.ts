import { NextRequest, NextResponse } from 'next/server';
import { edgeService } from '@/services/database';

export const runtime = 'nodejs';

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const nodeId = parseInt(id, 10);
    
    if (isNaN(nodeId)) {
      return NextResponse.json({
        success: false,
        error: 'Invalid node ID'
      }, { status: 400 });
    }
    
    const connections = await edgeService.getNodeConnections(nodeId);
    console.log('[api/nodes/[id]/edges] node', nodeId, 'returned connections:', connections.length);
    
    return NextResponse.json({
      success: true,
      data: connections,
      count: connections.length
    });
  } catch (error) {
    console.error('Error fetching node edges:', error);
    
    return NextResponse.json({
      success: false,
      error: error instanceof Error ? error.message : 'Failed to fetch node edges'
    }, { status: 500 });
  }
}
