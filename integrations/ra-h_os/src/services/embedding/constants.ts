export const AUTO_EMBED_MIN_CHARS = 200;

export function hasSufficientContent(text?: string | null): boolean {
  if (typeof text !== 'string') {
    return false;
  }
  return text.trim().length >= AUTO_EMBED_MIN_CHARS;
}
