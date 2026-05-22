import { NextRequest, NextResponse } from 'next/server';
import {
  getEnvLocalPath,
  isValidOpenAiKey,
  maskOpenAiKey,
  readStoredOpenAiKey,
  writeOpenAiKeyToEnvLocal,
} from '@/services/storage/envLocalServer';

export const runtime = 'nodejs';

function buildResponse(key: string | null) {
  const configured = isValidOpenAiKey(key);
  const llmProfile = process.env.LLM_PROFILE || 'openai';
  const embeddingProfile = process.env.EMBEDDING_PROFILE || 'openai';
  const openAiKeyWritable = llmProfile === 'openai' || embeddingProfile === 'openai';
  return {
    configured,
    maskedKey: configured ? maskOpenAiKey(key) : null,
    envPath: getEnvLocalPath(),
    openAiKeyWritable,
    activeProfile: {
      llmProfile,
      llmModel: process.env.LLM_MODEL || (llmProfile === 'openai' ? 'gpt-4o-mini' : null),
      llmBaseUrl: process.env.LLM_BASE_URL || null,
      embeddingProfile,
      embeddingModel: process.env.EMBEDDING_MODEL || (embeddingProfile === 'openai' ? 'text-embedding-3-small' : null),
      embeddingBaseUrl: process.env.EMBEDDING_BASE_URL || process.env.LLM_BASE_URL || null,
      embeddingDimensions: process.env.EMBEDDING_DIMENSIONS || (embeddingProfile === 'openai' ? '1536' : '1024'),
    },
  };
}

export async function GET() {
  try {
    const storedKey = await readStoredOpenAiKey();
    return NextResponse.json(buildResponse(storedKey));
  } catch (error) {
    return NextResponse.json(
      {
        configured: false,
        error: error instanceof Error ? error.message : 'Failed to read .env.local',
      },
      { status: 500 }
    );
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const key = typeof body?.key === 'string' ? body.key.trim() : '';
    const currentState = buildResponse(await readStoredOpenAiKey());

    if (!currentState.openAiKeyWritable) {
      return NextResponse.json(
        {
          error: 'OpenAI key entry is disabled because this install is using a local model profile. Change .env.local and rebuild embeddings to switch providers.',
          ...currentState,
        },
        { status: 409 }
      );
    }

    if (!isValidOpenAiKey(key)) {
      return NextResponse.json(
        { error: 'Invalid OpenAI API key format.' },
        { status: 400 }
      );
    }

    await writeOpenAiKeyToEnvLocal(key);
    process.env.OPENAI_API_KEY = key;

    return NextResponse.json(buildResponse(key));
  } catch (error) {
    return NextResponse.json(
      {
        error: error instanceof Error ? error.message : 'Failed to save OpenAI API key',
      },
      { status: 500 }
    );
  }
}

export async function DELETE() {
  try {
    await writeOpenAiKeyToEnvLocal(null);
    delete process.env.OPENAI_API_KEY;
    return NextResponse.json(buildResponse(null));
  } catch (error) {
    return NextResponse.json(
      {
        error: error instanceof Error ? error.message : 'Failed to remove OpenAI API key',
      },
      { status: 500 }
    );
  }
}
