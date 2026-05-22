import type { NextRequest } from 'next/server';

export function extractBearerToken(headerValue: string | null | undefined): string | null {
  if (!headerValue) return null;
  const parts = headerValue.split(' ');
  if (parts.length !== 2 || !/^Bearer$/i.test(parts[0] || '')) {
    return null;
  }
  return parts[1] || null;
}

export function getCurrentSupabaseToken(): string | null {
  return null;
}

export function getInternalAuthHeaders(
  headers: Record<string, string> = {}
): Record<string, string> {
  return { ...headers };
}

export function applyRequestSupabaseAuth(_request: NextRequest): () => void {
  return () => {};
}
