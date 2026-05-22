import { NextRequest, NextResponse } from 'next/server';
import { enqueueQuickAdd, QuickAddMode } from '@/services/agents/quickAdd';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { input, mode, description } = body as { input?: unknown; mode?: unknown; description?: unknown };

    if (typeof input !== 'string' || input.trim().length === 0) {
      return NextResponse.json(
        { success: false, error: 'Input is required' },
        { status: 400 }
      );
    }

    const normalizedMode: QuickAddMode | undefined =
      mode === 'link' || mode === 'text' ? mode : undefined;

    const normalizedDescription: string | undefined =
      typeof description === 'string' && description.trim() ? description.trim() : undefined;

    const result = await enqueueQuickAdd({
      rawInput: input.trim(),
      mode: normalizedMode,
      description: normalizedDescription,
    });

    return NextResponse.json({ success: true, result });
  } catch (error) {
    console.error('[Quick Add API] Error:', error);
    const message = error instanceof Error ? error.message : 'Unknown error';
    return NextResponse.json(
      { success: false, error: message },
      { status: 500 }
    );
  }
}
