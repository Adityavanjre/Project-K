function ensureString(value: unknown): string {
  return typeof value === 'string' ? value.trim() : '';
}

function ensureNumber(value: unknown): number | undefined {
  return typeof value === 'number' ? value : undefined;
}

function truncateOrDefault(value: string, limit = 180, fallback = ''): string {
  if (!value) return fallback;
  if (value.length <= limit) return value;
  return `${value.slice(0, limit - 1)}…`;
}

export function summarizeToolExecution(toolName: string, args: any, result: any): string {
  const fallback = `${toolName} completed.`;

  if (typeof result === 'string') {
    const trimmed = result.trim();
    return trimmed || fallback;
  }

  if (!result || typeof result !== 'object') {
    return fallback;
  }

  if (result.success === false) {
    const error = ensureString(result.error) || 'unknown error';
    return `${toolName} failed: ${error}`;
  }

  const message = ensureString((result as any).message);
  if (message) {
    return message;
  }

  if (toolName === 'think') {
    const trace = (result as any).data?.trace ?? args ?? {};
    const step = ensureNumber(trace.step ?? args?.step);
    const purpose = ensureString(trace.purpose ?? args?.purpose) || 'planning';
    const thoughts = ensureString(trace.thoughts ?? args?.thoughts);
    const next = ensureString(trace.next_action ?? args?.next_action);

    let summary = `Plan${step ? ` step ${step}` : ''}: ${truncateOrDefault(purpose, 120, purpose)}`;
    if (thoughts) {
      summary += ` — ${truncateOrDefault(thoughts, 160, thoughts)}`;
    }
    if (next) {
      summary += `. Next: ${truncateOrDefault(next, 80, next)}`;
    }
    return summary;
  }

  if (toolName === 'webSearch') {
    const query = ensureString(args?.query) || ensureString(result.data?.query);
    const results = Array.isArray(result.data?.results) ? result.data.results : [];
    if (results.length > 0) {
      const items = results.slice(0, 3).map((entry: any) => {
        const title = ensureString(entry.title) || ensureString(entry.url) || 'Result';
        const url = ensureString(entry.url);
        return url ? `${truncateOrDefault(title, 80, title)} (${url})` : truncateOrDefault(title, 80, title);
      });
      return `Web search${query ? ` for "${truncateOrDefault(query, 60, query)}"` : ''}: ${items.join('; ')}`;
    }
    return `Web search${query ? ` for "${truncateOrDefault(query, 60, query)}"` : ''}: no results.`;
  }

  if (toolName === 'searchContentEmbeddings') {
    const query = ensureString(args?.query) || ensureString(result.data?.query);
    const chunks = Array.isArray(result.data?.chunks) ? result.data.chunks : [];
    if (chunks.length > 0) {
      const top = chunks[0];
      const snippet = ensureString(top.text);
      const nodeId = ensureNumber(top.node_id);
      const preview = truncateOrDefault(snippet, 160, snippet);
      return `Embedding search${query ? ` for "${truncateOrDefault(query, 60, query)}"` : ''} found ${chunks.length} chunk(s). Top${nodeId ? ` [NODE:${nodeId}]` : ''}: ${preview}`;
    }
    return `Embedding search${query ? ` for "${truncateOrDefault(query, 60, query)}"` : ''}: no matches.`;
  }

  if (toolName === 'retrieveQueryContext') {
    const nodes = Array.isArray(result.data?.nodes) ? result.data.nodes : [];
    const chunks = Array.isArray(result.data?.chunks) ? result.data.chunks : [];
    if (nodes.length > 0) {
      const labels = nodes
        .slice(0, 3)
        .map((node: any) => `[NODE:${node.id}:"${ensureString(node.title) || node.id}"]`)
        .join(', ');
      return `Retrieved ${nodes.length} node(s)${chunks.length > 0 ? ` and ${chunks.length} chunk(s)` : ''}: ${labels}`;
    }
    return ensureString(result.data?.reason) || 'No relevant graph context retrieved.';
  }

  if (toolName === 'youtubeExtract') {
    const title = ensureString(result.data?.title) || ensureString(args?.title);
    const formatted = ensureString(result.data?.formatted_display);
    if (formatted) {
      return `YouTube extract created ${formatted}.`;
    }
    if (title) {
      return `YouTube extract processed "${truncateOrDefault(title, 80, title)}".`;
    }
    return 'YouTube extract completed.';
  }

  if (toolName === 'queryNodes') {
    const nodes = Array.isArray(result.data?.nodes) ? result.data.nodes : [];
    if (nodes.length > 0) {
      const labels = nodes
        .slice(0, 3)
        .map((node: any) => ensureString(node.formatted_display) || ensureString(node.title) || `[NODE:${node.id}]`)
        .join(', ');
      return `Found ${nodes.length} node(s): ${labels}`;
    }
  }

  if (toolName === 'queryEdge') {
    const edges = Array.isArray(result.data?.edges) ? result.data.edges : [];
    if (edges.length > 0) {
      const edge = edges[0];
      return `Found ${edges.length} edge(s), e.g., ${edge.from_node_id} → ${edge.to_node_id}.`;
    }
    return 'No edges found.';
  }

  if (result.data?.formatted_display) {
    return ensureString(result.data.formatted_display) || fallback;
  }

  if (result.data?.title) {
    return `Processed "${truncateOrDefault(ensureString(result.data.title), 80, result.data.title)}".`;
  }

  if (result.data?.count !== undefined) {
    const count = result.data.count;
    return `${toolName} returned ${count} item(s).`;
  }

  try {
    const preview = JSON.stringify(result.data ?? result);
    return truncateOrDefault(preview, 200, fallback);
  } catch (error) {
    return fallback;
  }
}
