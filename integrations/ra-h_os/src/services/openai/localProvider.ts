import { createOpenAI } from '@ai-sdk/openai';
import { getPreferredOpenAiKey } from '@/services/storage/openaiKeyServer';

export function createLocalOpenAIProvider() {
  const apiKey = getPreferredOpenAiKey();
  if (!apiKey) {
    throw new Error('OpenAI API key not configured. Add your key in Settings or .env.local.');
  }

  return createOpenAI({ apiKey });
}
