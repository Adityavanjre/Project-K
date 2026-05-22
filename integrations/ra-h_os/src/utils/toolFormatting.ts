// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function extractToolContext(toolName?: string, args?: any): string | undefined {
  if (!toolName || !args) return undefined;
  try {
    if (toolName === 'webSearch' && args.query) return `Searching for: ${String(args.query)}`;
    if (toolName === 'websiteExtract' && args.url) return `Extracting: ${String(args.url)}`;
    if (toolName === 'youtubeExtract' && args.url) return `Transcribing: ${String(args.url)}`;
    return undefined;
  } catch {
    return undefined;
  }
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function extractSources(toolName?: string, result?: any): Array<{ url?: string; domain?: string }> | undefined {
  if (!result) return undefined;
  try {
    if (toolName === 'webSearch') {
      const items = result?.data?.results || result?.results || [];
      if (!Array.isArray(items)) return undefined;
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      return items.map((r: any) => ({ url: r?.url }));
    }
    // Generic single-URL tools
    const url = result?.data?.url || result?.url;
    if (url) return [{ url }];
    return undefined;
  } catch {
    return undefined;
  }
}
