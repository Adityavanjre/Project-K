#!/bin/bash
# Simplified import without FTS complications

set -e

echo "Starting simplified SQLite import..."

# Remove old database
rm -f rah_trial.db

# Create basic schema first
sqlite3 rah_trial.db <<'SQL'
-- Basic settings
PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;
PRAGMA cache_size = -200000;
PRAGMA temp_store = MEMORY;
PRAGMA mmap_size = 268435456;

-- Create tables without FTS first
CREATE TABLE nodes (
  id INTEGER PRIMARY KEY,
  title TEXT,
  content TEXT,
  link TEXT,
  created_at TEXT,
  updated_at TEXT
);

CREATE TABLE node_dimensions (
  node_id INTEGER NOT NULL,
  dimension TEXT NOT NULL,
  PRIMARY KEY (node_id, dimension),
  FOREIGN KEY (node_id) REFERENCES nodes(id) ON DELETE CASCADE
) WITHOUT ROWID;

CREATE TABLE chunks (
  id INTEGER PRIMARY KEY,
  node_id INTEGER NOT NULL,
  chunk_idx INTEGER,
  text TEXT,
  created_at TEXT,
  FOREIGN KEY (node_id) REFERENCES nodes(id) ON DELETE CASCADE
);

CREATE TABLE chunk_embeddings (
  chunk_id INTEGER PRIMARY KEY,
  embedding TEXT NOT NULL,
  FOREIGN KEY (chunk_id) REFERENCES chunks(id) ON DELETE CASCADE
);

CREATE TABLE edges (
  id INTEGER PRIMARY KEY,
  from_node_id INTEGER NOT NULL,
  to_node_id INTEGER NOT NULL,
  source TEXT,
  created_at TEXT,
  FOREIGN KEY (from_node_id) REFERENCES nodes(id) ON DELETE CASCADE,
  FOREIGN KEY (to_node_id) REFERENCES nodes(id) ON DELETE CASCADE
);

CREATE TABLE chats (
  id INTEGER PRIMARY KEY,
  chat_type TEXT,
  helper_name TEXT,
  user_message TEXT,
  assistant_message TEXT,
  thread_id TEXT,
  focused_node_id INTEGER,
  created_at TEXT,
  FOREIGN KEY (focused_node_id) REFERENCES nodes(id) ON DELETE SET NULL
);

-- Create indexes
CREATE INDEX idx_dim_by_dimension ON node_dimensions(dimension, node_id);
CREATE INDEX idx_dim_by_node ON node_dimensions(node_id, dimension);
CREATE INDEX idx_chunks_by_node ON chunks(node_id);
CREATE INDEX idx_chunks_by_node_idx ON chunks(node_id, chunk_idx);
CREATE INDEX idx_edges_from ON edges(from_node_id);
CREATE INDEX idx_edges_to ON edges(to_node_id);
CREATE INDEX idx_chats_thread ON chats(thread_id);
SQL

echo "Schema created. Importing data..."

# Import CSVs with proper handling
sqlite3 rah_trial.db <<'SQL'
.mode csv

-- Import nodes
.import --skip 1 tmp/migrate/nodes.csv nodes

-- Import dimensions
.import --skip 1 tmp/migrate/node_dimensions.csv node_dimensions

-- Import chunks
.import --skip 1 tmp/migrate/chunks.csv chunks

-- Import embeddings  
.import --skip 1 tmp/migrate/chunk_embeddings.csv chunk_embeddings

-- Import edges (skip header)
.import --skip 1 tmp/migrate/edges.csv edges

-- Import chats
.import --skip 1 tmp/migrate/chats.csv chats

-- Add FTS after data is loaded
CREATE VIRTUAL TABLE chunks_fts USING fts5(
  text,
  content=chunks,
  content_rowid=id,
  tokenize='porter ascii'
);

CREATE VIRTUAL TABLE nodes_fts USING fts5(
  title,
  content,
  content=nodes,
  content_rowid=id,
  tokenize='porter ascii'
);

-- Populate FTS
INSERT INTO chunks_fts(text) SELECT text FROM chunks;
INSERT INTO nodes_fts(title, content) SELECT title, content FROM nodes;

-- Analyze for optimization
ANALYZE;
SQL

# Verify counts
echo ""
echo "Verifying import..."
sqlite3 rah_trial.db <<'SQL'
.mode list
SELECT 'Nodes: ' || COUNT(*) FROM nodes;
SELECT 'Chunks: ' || COUNT(*) FROM chunks;
SELECT 'Embeddings: ' || COUNT(*) FROM chunk_embeddings;
SELECT 'Dimensions: ' || COUNT(*) FROM node_dimensions;
SELECT 'Edges: ' || COUNT(*) FROM edges;
SELECT 'Chats: ' || COUNT(*) FROM chats;
SELECT 'Database size: ' || ROUND(page_count * page_size / 1024.0 / 1024.0, 2) || ' MB' FROM pragma_page_count(), pragma_page_size();
SQL

echo ""
echo "✅ Import complete!"
