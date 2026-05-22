/**
 * Node Formatter Utility
 * Wraps node data in special markers for UI rendering as labels
 * Format: [NODE:id:"title"]
 */

export interface NodeData {
  id: number;
  title: string;
}

/**
 * Formats a node for display in chat streams
 * @param node - Node data to format
 * @returns Formatted string with node markers
 */
export function formatNodeForChat(node: NodeData): string {
  return `[NODE:${node.id}:"${node.title}"]`;
}

/**
 * Formats multiple nodes for display
 * @param nodes - Array of nodes to format
 * @returns Formatted string with each node on a new line
 */
export function formatNodesForChat(nodes: NodeData[]): string {
  return nodes.map(formatNodeForChat).join('\n');
}

/**
 * Extracts node data from a formatted string
 * Used by UI components to parse node markers
 * @param text - Text potentially containing node markers
 * @returns Array of parsed node data
 */
export function parseNodeMarkers(text: string): Array<NodeData & { raw: string }> {
  const regex = /\[NODE:\s*(\d+)\s*:\s*["“”']([^"“”']+)["“”']\s*\]/g;
  const nodes: Array<NodeData & { raw: string }> = [];
  let match;
  
  while ((match = regex.exec(text)) !== null) {
    const [raw, id, title] = match;
    nodes.push({
      raw,
      id: parseInt(id, 10),
      title,
    });
  }
  
  return nodes;
}
