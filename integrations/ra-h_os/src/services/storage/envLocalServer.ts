import { promises as fs } from 'fs';
import path from 'path';

const OPENAI_KEY_PREFIXES = ['sk-', 'sk-proj-'];
const OPENAI_KEY_PLACEHOLDER = 'your-openai-api-key-here';

export function getEnvLocalPath(): string {
  return path.join(process.cwd(), '.env.local');
}

export function isValidOpenAiKey(key: string | null | undefined): boolean {
  if (!key) return false;
  const trimmed = key.trim();
  if (!trimmed || trimmed === OPENAI_KEY_PLACEHOLDER) return false;
  return OPENAI_KEY_PREFIXES.some((prefix) => trimmed.startsWith(prefix)) && trimmed.length > 20;
}

export function maskOpenAiKey(key: string | null | undefined): string | null {
  if (!key) return null;
  const trimmed = key.trim();
  if (trimmed.length <= 8) return '••••';
  return `${'•'.repeat(Math.max(8, trimmed.length - 4))}${trimmed.slice(-4)}`;
}

async function readEnvLocalFile(): Promise<string> {
  const envPath = getEnvLocalPath();
  try {
    return await fs.readFile(envPath, 'utf8');
  } catch (error: any) {
    if (error?.code === 'ENOENT') {
      return '';
    }
    throw error;
  }
}

export async function readStoredOpenAiKey(): Promise<string | null> {
  const contents = await readEnvLocalFile();
  const lines = contents.split(/\r?\n/);
  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    if (!trimmed.startsWith('OPENAI_API_KEY=')) continue;
    const rawValue = trimmed.slice('OPENAI_API_KEY='.length).trim();
    const unquoted =
      (rawValue.startsWith('"') && rawValue.endsWith('"')) ||
      (rawValue.startsWith("'") && rawValue.endsWith("'"))
        ? rawValue.slice(1, -1)
        : rawValue;
    return unquoted || null;
  }
  return null;
}

export async function writeOpenAiKeyToEnvLocal(key: string | null): Promise<void> {
  const envPath = getEnvLocalPath();
  const existing = await readEnvLocalFile();
  const lines = existing ? existing.split(/\r?\n/) : [];

  const nextLines: string[] = [];
  let handled = false;

  for (const line of lines) {
    if (/^\s*OPENAI_API_KEY\s*=/.test(line)) {
      if (!handled && key) {
        nextLines.push(`OPENAI_API_KEY=${key}`);
      }
      handled = true;
      continue;
    }
    nextLines.push(line);
  }

  if (!handled && key) {
    if (nextLines.length > 0 && nextLines[nextLines.length - 1]?.trim() !== '') {
      nextLines.push('');
    }
    nextLines.push(`OPENAI_API_KEY=${key}`);
  }

  const normalized = nextLines.join('\n').replace(/\n{3,}/g, '\n\n');
  const finalContents = normalized.length > 0 ? `${normalized}\n` : '';
  await fs.writeFile(envPath, finalContents, 'utf8');
}

