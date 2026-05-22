// API Key helpers
// Single source of truth: .env.local → process.env.OPENAI_API_KEY

/**
 * Check if a valid OpenAI API key is configured in .env.local
 */
export function hasValidOpenAiKey(): boolean {
  const key = process.env.OPENAI_API_KEY;
  if (!key || key === 'your-openai-api-key-here') return false;
  return key.startsWith('sk-') && key.length > 20;
}

/**
 * Get the OpenAI API key from environment
 */
export function getOpenAiKey(): string | undefined {
  const key = process.env.OPENAI_API_KEY;
  if (!key || key === 'your-openai-api-key-here') return undefined;
  return key;
}

/**
 * Check if first run (no API key configured)
 */
export function isFirstRun(): boolean {
  if (typeof window === 'undefined') return false;
  return !localStorage.getItem('ra-h-first-run-complete');
}

export function markFirstRunComplete(): void {
  if (typeof window !== 'undefined') {
    localStorage.setItem('ra-h-first-run-complete', 'true');
  }
}
