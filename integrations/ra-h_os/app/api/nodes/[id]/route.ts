import { NextRequest, NextResponse } from 'next/server';
import { nodeService } from '@/services/database';
import { autoEmbedQueue } from '@/services/embedding/autoEmbedQueue';
import { hasSufficientContent } from '@/services/embedding/constants';
import { coerceDescriptionForStorage } from '@/services/database/quality';
import { applyRequestSupabaseAuth, getCurrentSupabaseToken } from '@/services/auth/internalAuth';
import { normalizeNodeLink } from '@/utils/nodeLink';
import { mergeNodeMetadata } from '@/services/nodes/metadata';

export const runtime = 'nodejs';

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const cleanupAuth = applyRequestSupabaseAuth(request);
  try {
    const { id } = await params;
    const nodeId = parseInt(id, 10);
    
    if (isNaN(nodeId)) {
      return NextResponse.json({
        success: false,
        error: 'Invalid node ID'
      }, { status: 400 });
    }
    
    const node = await nodeService.getNodeById(nodeId);
    
    if (!node) {
      return NextResponse.json({
        success: false,
        error: 'Node not found'
      }, { status: 404 });
    }
    
    return NextResponse.json({
      success: true,
      node: node
    });
  } catch (error) {
    console.error('Error fetching node:', error);
    
    return NextResponse.json({
      success: false,
      error: error instanceof Error ? error.message : 'Failed to fetch node'
    }, { status: 500 });
  } finally {
    cleanupAuth();
  }
}

export async function PUT(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const cleanupAuth = applyRequestSupabaseAuth(request);
  try {
    const { id } = await params;
    const nodeId = parseInt(id, 10);
    
    if (isNaN(nodeId)) {
      return NextResponse.json({
        success: false,
        error: 'Invalid node ID'
      }, { status: 400 });
    }

    const body = await request.json();

    const existingNode = await nodeService.getNodeById(nodeId);
    if (!existingNode) {
      return NextResponse.json({
        success: false,
        error: 'Node not found'
      }, { status: 404 });
    }

    const updates: Record<string, unknown> = { ...body };
    let shouldQueueEmbed = false;

    if (typeof body.link === 'string') {
      const trimmedLink = body.link.trim();
      const normalizedLink = normalizeNodeLink(trimmedLink);
      if (trimmedLink && !normalizedLink) {
        return NextResponse.json({
          success: false,
          error: 'Invalid link. Use a full URL like https://example.com'
        }, { status: 400 });
      }
      updates.link = normalizedLink ?? null;
    }

    if (typeof body.description === 'string') {
      updates.description = coerceDescriptionForStorage({
        title: typeof updates.title === 'string' ? updates.title : existingNode.title,
        description: body.description
      });
    }

    delete updates.notes;
    delete updates.chunk;

    if (body.metadata !== undefined) {
      updates.metadata = mergeNodeMetadata(existingNode.metadata, body.metadata);
    }

    const incomingSource = typeof body.source === 'string' ? body.source : undefined;
    const existingSource = existingNode.source ?? '';

    if (incomingSource !== undefined) {
      const trimmedIncoming = incomingSource.trim();
      const trimmedExisting = existingSource.trim();

      if (!trimmedIncoming) {
        updates.chunk_status = null;
      } else if (trimmedIncoming !== trimmedExisting) {
        updates.chunk_status = 'not_chunked';
        shouldQueueEmbed = hasSufficientContent(trimmedIncoming);
      } else {
        delete updates.chunk_status;
      }
    }

    const node = await nodeService.updateNode(nodeId, updates);

      if (shouldQueueEmbed) {
        autoEmbedQueue.enqueue(nodeId, {
          reason: 'node_updated',
        });
      }

    return NextResponse.json({
      success: true,
      node: node,
      message: `Node updated successfully`
    });
  } catch (error) {
    console.error('Error updating node:', error);
    return NextResponse.json({
      success: false,
      error: error instanceof Error ? error.message : 'Failed to update node'
    }, { status: 500 });
  } finally {
    cleanupAuth();
  }
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const cleanupAuth = applyRequestSupabaseAuth(request);
  try {
    const { id } = await params;
    const nodeId = parseInt(id, 10);
    
    if (isNaN(nodeId)) {
      return NextResponse.json({
        success: false,
        error: 'Invalid node ID'
      }, { status: 400 });
    }

    await nodeService.deleteNode(nodeId);

    return NextResponse.json({
      success: true,
      message: `Node ${nodeId} deleted successfully`
    });
  } catch (error) {
    console.error('Error deleting node:', error);
    
    return NextResponse.json({
      success: false,
      error: error instanceof Error ? error.message : 'Failed to delete node'
    }, { status: 500 });
  } finally {
    cleanupAuth();
  }
}
