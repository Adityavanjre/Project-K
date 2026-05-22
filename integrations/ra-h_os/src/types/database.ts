export type NodeMetadataState = 'processed' | 'not_processed';
export type NodeCapturedBy = 'human' | 'agent';

export interface CanonicalNodeMetadata {
  type?: string;
  state?: NodeMetadataState;
  captured_method?: string;
  captured_by?: NodeCapturedBy;
  source_metadata?: Record<string, unknown>;
  [key: string]: unknown;
}

// New Node-based type system replacing rigid Item categorization
export interface Node {
  id: number;
  title: string;
  description?: string;
  source?: string;            // Canonical embeddable content
  notes?: string;             // Deprecated legacy field - do not write
  link?: string;
  event_date?: string | null; // When the thing actually happened (ISO 8601)
  embedding?: Buffer;         // Node-level embedding (BLOB data)
  chunk?: string;             // Deprecated legacy field - do not write
  metadata?: CanonicalNodeMetadata | null; // Flexible metadata storage with canonical contract
  created_at: string;
  updated_at: string;
  edge_count?: number;       // Derived count of edges, included in some queries

  // Optional embedding fields
  embedding_updated_at?: string;
  embedding_text?: string;
  chunk_status?: 'not_chunked' | 'chunking' | 'chunked' | 'error' | null;
}

export interface Chunk {
  id: number;
  node_id: number;           // Updated from item_id to node_id
  chunk_idx?: number;
  text: string;
  embedding?: number[];
  embedding_type: string;
  metadata?: any;            // Updated from extras to metadata
  created_at: string;
}

export interface Edge {
  id: number;
  from_node_id: number;
  to_node_id: number;
  context?: any;
  source: EdgeSource;
  created_at: string;
}

export type EdgeSource = 'user' | 'ai_similarity' | 'helper_name';

export type EdgeContextType =
  | 'created_by'   // Content → Creator (book by author, podcast by host)
  | 'part_of'      // Part → Whole (episode of podcast, person discussed in book)
  | 'source_of'    // Derivative → Source (insight from article)
  | 'related_to';  // Default — anything else or when unsure

export type EdgeCreatedVia = 'ui' | 'agent' | 'mcp' | 'workflow' | 'quicklink' | 'quick_capture_auto';

export interface EdgeContext {
  // SYSTEM-INFERRED (AI classifies from explanation + nodes)
  type: EdgeContextType;
  confidence: number;   // 0-1
  inferred_at: string;  // ISO timestamp

  // PROVIDED AT CREATION / EDIT
  explanation: string;

  // SYSTEM-MANAGED
  created_via: EdgeCreatedVia;
}

// New NodeFilters interface replacing rigid ItemFilters
export interface NodeFilters {
  search?: string;           // Text search in title/content
  searchMode?: 'standard' | 'hybrid'; // standard = FTS/LIKE, hybrid = add node-vector retrieval
  chunkStatus?: 'not_chunked' | 'chunking' | 'chunked' | 'error';
  limit?: number;
  offset?: number;
  sortBy?: 'updated' | 'edges' | 'created' | 'event_date';  // Sort by updated_at, edge count, created_at, or event_date
  createdAfter?: string;     // ISO date (YYYY-MM-DD) — nodes created on or after
  createdBefore?: string;    // ISO date (YYYY-MM-DD) — nodes created before
  eventAfter?: string;       // ISO date (YYYY-MM-DD) — nodes with event_date on or after
  eventBefore?: string;      // ISO date (YYYY-MM-DD) — nodes with event_date before
}

export interface ChunkData {
  node_id: number;           // Updated from item_id
  chunk_idx?: number;
  text: string;
  embedding?: number[];
  embedding_type: string;
  metadata?: any;            // Updated from extras
}

export interface EdgeData {
  from_node_id: number;
  to_node_id: number;
  explanation: string;
  created_via: EdgeCreatedVia;
  source: EdgeSource;
  skip_inference?: boolean; // reserved for bulk imports / migrations
}

export interface ChatData {
  user_message?: string;
  assistant_message?: string;
  thread_id: string;
  focused_node_id?: number;  // Updated from focused_item_id
  metadata?: any;
  embedding?: number[];      // Renamed from content_embedding
}

// New NodeConnection interface
export interface NodeConnection {
  id: number;
  connected_node: Node;      // Updated from connected_item
  edge: Edge;
}

export interface DatabaseError {
  message: string;
  code?: string;
  details?: any;
}

export interface Dimension {
  name: string;
  description?: string | null;
  icon?: string | null;
  is_priority: boolean;
  updated_at: string;
}
