import { NextRequest, NextResponse } from 'next/server';
import { PaperExtractor } from '@/services/typescript/extractors/paper';

export const runtime = 'nodejs';

// Size limits in bytes
const WARN_SIZE = 10 * 1024 * 1024; // 10MB
const MAX_SIZE = 50 * 1024 * 1024;  // 50MB

export async function POST(request: NextRequest) {
  try {
    const formData = await request.formData();
    const file = formData.get('file');

    // Validate file presence
    if (!file || !(file instanceof File)) {
      return NextResponse.json(
        { success: false, error: 'PDF file is required' },
        { status: 400 }
      );
    }

    // Validate MIME type
    if (file.type !== 'application/pdf') {
      return NextResponse.json(
        { success: false, error: `Invalid file type: ${file.type}. Only PDF files are accepted.` },
        { status: 400 }
      );
    }

    // Check file size
    if (file.size > MAX_SIZE) {
      return NextResponse.json(
        { success: false, error: `File too large (${Math.round(file.size / 1024 / 1024)}MB). Maximum size is 50MB.` },
        { status: 413 }
      );
    }

    const isLargeFile = file.size > WARN_SIZE;

    // Get buffer from file
    const buffer = Buffer.from(await file.arrayBuffer());

    // Extract PDF content using PaperExtractor
    const extractor = new PaperExtractor();
    const extraction = await extractor.extractFromBuffer(buffer, file.name);

    // Derive title from metadata or filename
    const title = extraction.metadata.title || file.name.replace(/\.pdf$/i, '');

    // Create node via internal API call
    // IMPORTANT: Use request.url origin for packaged Tauri app compatibility
    const nodeApiUrl = new URL('/api/nodes', request.url);

    const createResponse = await fetch(nodeApiUrl.toString(), {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        title,
        description: `PDF document imported from ${file.name} — ${extraction.metadata.pages} pages of extracted text. Useful as a searchable local source.`,
        source: extraction.chunk,
        metadata: {
          source: 'pdf_upload',
          original_filename: file.name,
          pages: extraction.metadata.pages,
          text_length: extraction.metadata.text_length,
          extraction_method: extraction.metadata.extraction_method,
          imported_at: new Date().toISOString(),
        },
      }),
    });

    if (!createResponse.ok) {
      const errorData = await createResponse.json().catch(() => ({}));
      throw new Error(errorData.error || `Failed to create node: ${createResponse.status}`);
    }

    const nodeResult = await createResponse.json();

    if (!nodeResult.success || !nodeResult.data?.id) {
      throw new Error(nodeResult.error || 'Failed to create node');
    }

    return NextResponse.json({
      success: true,
      nodeId: nodeResult.data.id,
      title,
      pages: extraction.metadata.pages,
      textLength: extraction.metadata.text_length,
      warning: isLargeFile ? `Large file (${Math.round(file.size / 1024 / 1024)}MB) - processing may take longer` : undefined,
    });

  } catch (error) {
    console.error('[PDF Upload API] Error:', error);
    const message = error instanceof Error ? error.message : 'Failed to process PDF upload';
    return NextResponse.json(
      { success: false, error: message },
      { status: 500 }
    );
  }
}
