/**
 * Main health check endpoint
 * Returns overall system health status for quick verification
 */

import { NextResponse } from 'next/server';
import { checkDatabaseHealth } from '@/services/database';
import { hasPreferredOpenAiKey } from '@/services/storage/openaiKeyServer';

export const runtime = 'nodejs';

export async function GET() {
  try {
    const dbHealth = await checkDatabaseHealth();

    const response = {
      status: dbHealth.connected ? 'ok' : 'degraded',
      database: dbHealth.connected ? 'connected' : 'disconnected',
      vectorSearch: dbHealth.vectorExtension ? 'enabled' : 'disabled',
      aiFeatures: hasPreferredOpenAiKey() ? 'enabled' : 'disabled (no API key)',
      timestamp: new Date().toISOString(),
    };

    return NextResponse.json(response, {
      status: dbHealth.connected ? 200 : 503,
    });
  } catch (error) {
    return NextResponse.json(
      {
        status: 'error',
        database: 'error',
        error: error instanceof Error ? error.message : 'Unknown error',
        timestamp: new Date().toISOString(),
      },
      { status: 500 }
    );
  }
}
