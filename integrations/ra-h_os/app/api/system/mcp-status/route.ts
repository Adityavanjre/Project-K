import { NextResponse } from 'next/server';
import fs from 'fs';
import os from 'os';
import path from 'path';

export const runtime = 'nodejs';

const STATUS_PATH = path.join(
  os.homedir(),
  'Library',
  'Application Support',
  'RA-H',
  'config',
  'mcp-status.json'
);

export async function GET() {
  try {
    if (!fs.existsSync(STATUS_PATH)) {
      return NextResponse.json({
        enabled: false,
        port: null,
        url: null,
        last_updated: null,
        target_base_url: null
      });
    }

    const raw = fs.readFileSync(STATUS_PATH, 'utf-8');
    const parsed = JSON.parse(raw);
    return NextResponse.json(parsed);
  } catch (error) {
    console.error('Failed to read MCP status file:', error);
    return NextResponse.json(
      {
        enabled: false,
        port: null,
        url: null,
        last_updated: null,
        target_base_url: null,
        error: 'Unable to read MCP status'
      },
      { status: 500 }
    );
  }
}
