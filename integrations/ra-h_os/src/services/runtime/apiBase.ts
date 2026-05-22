import { RequestContext } from '@/services/context/requestContext';

export function getInternalApiBaseUrl(): string {
  const requestOrigin = (RequestContext.get() as { requestOrigin?: string }).requestOrigin;
  if (requestOrigin) {
    return requestOrigin;
  }

  return process.env.NEXT_PUBLIC_BASE_URL
    || process.env.NEXT_PUBLIC_APP_URL
    || 'http://localhost:3000';
}
