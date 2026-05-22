import { NextRequest, NextResponse } from 'next/server';
import { chunkService } from '@/services/database';

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
    
    const chunks = await chunkService.getChunksByNodeId(nodeId);
    
    return NextResponse.json({
      success: true,
      chunks: chunks
    });
  } catch (error) {
    console.error('Error fetching chunks:', error);
    
    return NextResponse.json({
      success: false,
      error: error instanceof Error ? error.message : 'Failed to fetch chunks'
    }, { status: 500 });
  }
}