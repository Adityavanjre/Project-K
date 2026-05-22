const LOCAL_HOST_PATTERN = /^(localhost|127(?:\.\d{1,3}){3}|0\.0\.0\.0)(:\d+)?(\/.*)?$/i;
const BARE_HOST_PATTERN = /^(?:[a-z0-9-]+\.)+[a-z]{2,}(?::\d+)?(?:\/.*)?$/i;

export function normalizeNodeLink(input?: string | null): string | null {
  if (typeof input !== 'string') return null;

  const trimmed = input.trim();
  if (!trimmed) return null;

  const candidate = /^[a-z][a-z0-9+.-]*:\/\//i.test(trimmed)
    ? trimmed
    : BARE_HOST_PATTERN.test(trimmed) || LOCAL_HOST_PATTERN.test(trimmed)
      ? `https://${trimmed}`
      : null;

  if (!candidate) return null;

  try {
    const parsed = new URL(candidate);
    if (!['http:', 'https:'].includes(parsed.protocol)) {
      return null;
    }
    return parsed.toString();
  } catch {
    return null;
  }
}
