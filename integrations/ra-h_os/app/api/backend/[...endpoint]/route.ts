import { NextRequest, NextResponse } from 'next/server';
import { isSubscriptionBackendEnabled } from '@/config/runtime';

const BACKEND_BASE_URL = (process.env.BACKEND_SERVICE_URL || process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:3001').replace(/\/$/, '');

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

async function proxyRequest(
  request: NextRequest,
  context: { params: Promise<{ endpoint?: string[] }> }
) {
  if (!isSubscriptionBackendEnabled()) {
    return NextResponse.json({ error: 'Subscription backend disabled' }, { status: 404 });
  }

  if (!BACKEND_BASE_URL) {
    return NextResponse.json({ error: 'Backend URL is not configured' }, { status: 500 });
  }

  const { endpoint: pathSegments = [] } = await context.params;
  const targetPath = pathSegments.join('/');
  const search = request.nextUrl.search || '';
  const targetUrl = `${BACKEND_BASE_URL}${targetPath ? `/${targetPath}` : ''}${search}`;

  const outgoingHeaders = new Headers();
  const authHeader = request.headers.get('authorization');
  const contentType = request.headers.get('content-type');
  const clientInfo = request.headers.get('x-client-info');

  if (authHeader) {
    outgoingHeaders.set('authorization', authHeader);
  }
  if (contentType) {
    outgoingHeaders.set('content-type', contentType);
  }
  if (clientInfo) {
    outgoingHeaders.set('x-client-info', clientInfo);
  }
  outgoingHeaders.set('accept', request.headers.get('accept') || 'application/json');

  const bodyAllowed = !['GET', 'HEAD', 'OPTIONS'].includes(request.method.toUpperCase());
  const body = bodyAllowed ? await request.text() : undefined;

  try {
    const backendResponse = await fetch(targetUrl, {
      method: request.method,
      headers: outgoingHeaders,
      body,
    });

    const responseHeaders = new Headers();
    backendResponse.headers.forEach((value, key) => {
      const lowerKey = key.toLowerCase();
      if (['content-length', 'transfer-encoding', 'connection'].includes(lowerKey)) {
        return;
      }
      responseHeaders.set(key, value);
    });
    responseHeaders.set('cache-control', 'no-store');

    if (request.method.toUpperCase() === 'HEAD') {
      return new NextResponse(null, {
        status: backendResponse.status,
        headers: responseHeaders,
      });
    }

    const text = await backendResponse.text();
    return new NextResponse(text, {
      status: backendResponse.status,
      headers: responseHeaders,
    });
  } catch (error) {
    console.error('[backend-proxy] Failed to reach backend:', error);
    return NextResponse.json(
      { error: 'Failed to contact backend service' },
      { status: 502 }
    );
  }
}

export function GET(request: NextRequest, context: { params: Promise<{ endpoint?: string[] }> }) {
  return proxyRequest(request, context);
}

export function POST(request: NextRequest, context: { params: Promise<{ endpoint?: string[] }> }) {
  return proxyRequest(request, context);
}

export function PUT(request: NextRequest, context: { params: Promise<{ endpoint?: string[] }> }) {
  return proxyRequest(request, context);
}

export function PATCH(request: NextRequest, context: { params: Promise<{ endpoint?: string[] }> }) {
  return proxyRequest(request, context);
}

export function DELETE(request: NextRequest, context: { params: Promise<{ endpoint?: string[] }> }) {
  return proxyRequest(request, context);
}

export function OPTIONS(request: NextRequest, context: { params: Promise<{ endpoint?: string[] }> }) {
  return proxyRequest(request, context);
}
