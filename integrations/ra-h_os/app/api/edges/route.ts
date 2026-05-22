import { NextRequest, NextResponse } from 'next/server';
import { edgeService } from '@/services/database';
import { validateEdgeExplanation } from '@/services/database/quality';

export const runtime = 'nodejs';

export async function GET() {
  try {
    const edges = await edgeService.getEdges();
    
    return NextResponse.json({
      success: true,
      data: edges,
      count: edges.length
    });
  } catch (error) {
    console.error('Error fetching edges:', error);
    
    return NextResponse.json({
      success: false,
      error: error instanceof Error ? error.message : 'Failed to fetch edges'
    }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    
    // Validate required fields
    if (!body.from_node_id || !body.to_node_id) {
      return NextResponse.json({
        success: false,
        error: 'Missing required fields: from_node_id and to_node_id are required'
      }, { status: 400 });
    }

    // Validate node IDs are numbers
    if (isNaN(parseInt(body.from_node_id)) || isNaN(parseInt(body.to_node_id))) {
      return NextResponse.json({
        success: false,
        error: 'Invalid node IDs: must be valid numbers'
      }, { status: 400 });
    }

    // Set default source if not provided
    if (!body.source) {
      body.source = 'user';
    }

    // Validate source value
    if (!['user', 'ai_similarity', 'helper_name'].includes(body.source)) {
      return NextResponse.json({
        success: false,
        error: 'Invalid source: must be user, ai_similarity, or helper_name'
      }, { status: 400 });
    }

    const fromId = parseInt(body.from_node_id);
    const toId = parseInt(body.to_node_id);
    const explanation = String(body.explanation || '').trim();
    const createdVia = (() => {
      const raw = typeof body.created_via === 'string' ? body.created_via : '';
      if (['ui', 'agent', 'mcp', 'workflow', 'quicklink'].includes(raw)) return raw as any;
      return 'ui' as const;
    })();

    if (!explanation && createdVia !== 'ui' && createdVia !== 'quicklink') {
      return NextResponse.json({
        success: false,
        error: 'Agent-driven edge creation requires an explicit explanation. Propose likely edges first and only create them after the user confirms.'
      }, { status: 400 });
    }

    if ((createdVia === 'agent' || createdVia === 'mcp' || createdVia === 'workflow') && body.confirmed_by_user !== true) {
      return NextResponse.json({
        success: false,
        error: 'Agent-driven edge creation requires explicit user confirmation before writing to the graph.'
      }, { status: 400 });
    }

    if (explanation) {
      const explanationError = validateEdgeExplanation(explanation);
      if (explanationError) {
        return NextResponse.json({
          success: false,
          error: explanationError
        }, { status: 400 });
      }
    }
    const skipInference = Boolean(body.skip_inference);

    // Idempotency: prevent duplicate edges between same pair
    try {
      const exists = await edgeService.edgeExists(fromId, toId);
      if (exists) {
        return NextResponse.json({
          success: true,
          data: { from_node_id: fromId, to_node_id: toId },
          message: `Edge already exists between nodes ${fromId} and ${toId}`
        }, { status: 200 });
      }
    } catch (e) {
      // Non-fatal: continue with creation if existence check fails
      console.warn('edgeExists check failed; proceeding to create:', e);
    }

    const edge = await edgeService.createEdge({
      from_node_id: fromId,
      to_node_id: toId,
      explanation,
      created_via: createdVia,
      source: body.source,
      skip_inference: skipInference
    });

    return NextResponse.json({
      success: true,
      data: edge,
      message: `Edge created successfully between nodes ${edge.from_node_id} and ${edge.to_node_id}`
    }, { status: 201 });
  } catch (error) {
    console.error('Error creating edge:', error);
    
    return NextResponse.json({
      success: false,
      error: error instanceof Error ? error.message : 'Failed to create edge'
    }, { status: 500 });
  }
}
