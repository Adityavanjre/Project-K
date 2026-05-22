/**
 * Simple ping endpoint for sidecar health checks
 * Returns a basic OK response to verify the server is responding
 */

import { NextResponse } from 'next/server';

export async function GET() {
  return NextResponse.json({ 
    status: 'ok',
    timestamp: new Date().toISOString()
  });
}
