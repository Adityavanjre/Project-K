import fs from 'fs';
import path from 'path';

const PLACEHOLDER = 'your-openai-api-key-here';

function parseOpenAiKeyFromEnvFile(contents: string): string | undefined {
  for (const line of contents.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    if (!trimmed.startsWith('OPENAI_API_KEY=')) continue;
    const raw = trimmed.slice('OPENAI_API_KEY='.length).trim();
    const value =
      (raw.startsWith('"') && raw.endsWith('"')) ||
      (raw.startsWith("'") && raw.endsWith("'"))
        ? raw.slice(1, -1)
        : raw;
    if (!value || value === PLACEHOLDER) return undefined;
    return value;
  }
  return undefined;
}

export function getPreferredOpenAiKey(): string | undefined {
  const envPath = path.join(process.cwd(), '.env.local');
  try {
    const fileKey = parseOpenAiKeyFromEnvFile(fs.readFileSync(envPath, 'utf8'));
    if (fileKey) return fileKey;
  } catch {
    // Ignore missing/unreadable .env.local and treat that as "not configured" for local mode.
  }
  return undefined;
}

export function hasPreferredOpenAiKey(): boolean {
  const key = getPreferredOpenAiKey();
  return Boolean(key && key.startsWith('sk-') && key.length > 20);
}
