import { NextRequest, NextResponse } from 'next/server';
import { nodeService } from '@/services/database';
import { Node, NodeFilters } from '@/types/database';
import { autoEmbedQueue } from '@/services/embedding/autoEmbedQueue';
import { generateDescription } from '@/services/database/descriptionService';
import { coerceDescriptionForStorage } from '@/services/database/quality';
import { applyRequestSupabaseAuth, getCurrentSupabaseToken } from '@/services/auth/internalAuth';
import { normalizeNodeLink } from '@/utils/nodeLink';
import { buildCanonicalNodeMetadata } from '@/services/nodes/metadata';

export const runtime = 'nodejs';

export async function GET(request: NextRequest) {
  const cleanupAuth = applyRequestSupabaseAuth(request);
  try {
    const searchParams = request.nextUrl.searchParams;
    
    const filters: NodeFilters = {
      search: searchParams.get('search') || undefined,
      limit: searchParams.get('limit') ? parseInt(searchParams.get('limit')!) : 100,
      offset: searchParams.get('offset') ? parseInt(searchParams.get('offset')!) : 0
    };

    // Handle sortBy parameter (sortBy=edges|updated|created)
    const sortByParam = searchParams.get('sortBy');
    if (sortByParam === 'edges' || sortByParam === 'updated' || sortByParam === 'created' || sortByParam === 'event_date') {
      filters.sortBy = sortByParam;
    }

    // Also support sort=created_at|updated_at with order=asc|desc (used by feed)
    const sortParam = searchParams.get('sort');
    if (sortParam === 'created_at') {
      filters.sortBy = 'created';
    } else if (sortParam === 'updated_at') {
      filters.sortBy = 'updated';
    }

    const nodes = await nodeService.getNodes(filters);
    const total = await nodeService.countNodes(filters);

    return NextResponse.json({
      success: true,
      data: nodes,
      count: nodes.length,
      total
    });
  } catch (error) {
    console.error('Error fetching nodes:', error);
    
    return NextResponse.json({
      success: false,
      error: error instanceof Error ? error.message : 'Failed to fetch nodes'
    }, { status: 500 });
  } finally {
    cleanupAuth();
  }
}

// Weak-pattern regex for post-creation quality monitoring
const WEAK_PATTERNS = /\b(discusses|explores|examines|talks about|is about|delves into|This is a)\b/i;

function sanitizeTitle(title: string): string {
  let clean = title.trim();
  // Strip "Title: " prefix (extraction artifact)
  if (clean.startsWith('Title: ')) clean = clean.slice(7);
  // Strip trailing " / X" (Twitter artifact)
  if (clean.endsWith(' / X')) clean = clean.slice(0, -4);
  // Collapse whitespace
  clean = clean.replace(/\s+/g, ' ');
  return clean.slice(0, 160);
}

export async function POST(request: NextRequest) {
  const cleanupAuth = applyRequestSupabaseAuth(request);
  try {
    const body = await request.json();

    // Validate required fields
    if (!body.title) {
      return NextResponse.json({
        success: false,
        error: 'Missing required field: title is required'
      }, { status: 400 });
    }

    // Sanitize title (strip extraction artifacts)
    body.title = sanitizeTitle(body.title);

    const rawSource = typeof body.source === 'string' ? body.source.trim() : null;
    const rawLink = typeof body.link === 'string' ? body.link : null;
    const normalizedLink = normalizeNodeLink(rawLink);
    if (rawLink && !normalizedLink) {
      return NextResponse.json({
        success: false,
        error: 'Invalid link. Use a full URL like https://example.com'
      }, { status: 400 });
    }
    const eventDate = typeof body.event_date === 'string' ? body.event_date : null;

    // Use provided description if present, otherwise auto-generate
    const isUserSuppliedDescription = typeof body.description === 'string' && body.description.trim().length > 0;
    let nodeDescription: string | undefined = isUserSuppliedDescription
      ? body.description.trim().slice(0, 500)
      : undefined;

    if (!nodeDescription) {
      try {
        nodeDescription = await generateDescription({
          title: body.title,
          source: rawSource?.slice(0, 2000) || undefined,
          link: normalizedLink || undefined,
          metadata: body.metadata,
        });
      } catch (error) {
        console.error('Error generating description:', error);
      }
    }

    // Final safety net — never store null/empty description
    if (!nodeDescription || nodeDescription.trim().length === 0) {
      nodeDescription = `${body.title}. Added via Quick Add with no further context yet, so the reason it belongs in the graph is not fully inferred. It has not been reviewed yet.`.slice(0, 500);
    }

    const finalDescription = coerceDescriptionForStorage({
      title: body.title,
      description: nodeDescription
    });

    // Monitor description quality
    if (WEAK_PATTERNS.test(nodeDescription ?? finalDescription)) {
      console.warn(`[DescriptionQuality] Weak description for node "${body.title}": "${finalDescription}"`);
    }

    const sourceToStore = rawSource || [body.title, nodeDescription].filter(Boolean).join('\n\n').trim() || null;
    let chunkStatus: Node['chunk_status'];

    if (sourceToStore && sourceToStore.trim().length > 0) {
      chunkStatus = 'not_chunked';
    }

    const inferredType =
      typeof body.metadata?.type === 'string'
        ? body.metadata.type
        : typeof body.metadata?.source === 'string'
          ? body.metadata.source
          : undefined;

    const node = await nodeService.createNode({
      title: body.title,
      description: finalDescription,
      source: sourceToStore ?? undefined,
      event_date: eventDate ?? undefined,
      link: normalizedLink ?? undefined,
      chunk_status: chunkStatus,
      metadata: buildCanonicalNodeMetadata({
        metadata: body.metadata || {},
        type: inferredType,
        state: body.metadata?.state === 'processed' ? 'processed' : 'not_processed',
      })
    });

    if (chunkStatus === 'not_chunked' && node.id) {
      autoEmbedQueue.enqueue(node.id, {
        reason: 'node_created',
      });
    }

    return NextResponse.json({
      success: true,
      data: node,
      message: `Node created successfully`
    }, { status: 201 });
  } catch (error) {
    console.error('Error creating node:', error);
    
    return NextResponse.json({
      success: false,
      error: error instanceof Error ? error.message : 'Failed to create node'
    }, { status: 500 });
  } finally {
    cleanupAuth();
  }
}
