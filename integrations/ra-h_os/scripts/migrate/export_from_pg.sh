#!/bin/bash
# Export all PostgreSQL data to CSV files for SQLite migration

set -e  # Exit on error

echo "Starting PostgreSQL data export..."

# Ensure tmp directory exists
mkdir -p tmp/migrate

# Database connection string
DB_URL="postgresql://rah_user:rah_password@localhost:5432/rah_db"

# Export nodes
echo "Exporting nodes..."
psql "$DB_URL" -c "\COPY (SELECT id, title, content, link, created_at, updated_at FROM nodes ORDER BY id) TO STDOUT WITH CSV HEADER" > tmp/migrate/nodes.csv

# Export dimensions (unnest array into rows)
echo "Exporting dimensions (array to rows)..."
psql "$DB_URL" -c "\COPY (SELECT n.id AS node_id, TRIM(unnest(n.dimensions)) AS dimension FROM nodes n WHERE n.dimensions IS NOT NULL AND array_length(n.dimensions, 1) > 0 ORDER BY n.id) TO STDOUT WITH CSV HEADER" > tmp/migrate/node_dimensions.csv

# Export chunks (without embeddings)
echo "Exporting chunks..."
psql "$DB_URL" -c "\COPY (SELECT id, node_id, chunk_idx, text, created_at FROM chunks ORDER BY id) TO STDOUT WITH CSV HEADER" > tmp/migrate/chunks.csv

# Export embeddings as CSV text (handle NULL embeddings)
echo "Exporting embeddings..."
psql "$DB_URL" -c "\COPY (SELECT id AS chunk_id, CASE WHEN embedding IS NOT NULL THEN trim(both '[]' from embedding::text) ELSE NULL END AS embedding_csv FROM chunks WHERE embedding IS NOT NULL ORDER BY id) TO STDOUT WITH CSV HEADER" > tmp/migrate/chunk_embeddings.csv

# Export edges
echo "Exporting edges..."
psql "$DB_URL" -c "\COPY (SELECT id, from_node_id, to_node_id, source, created_at FROM edges ORDER BY id) TO STDOUT WITH CSV HEADER" > tmp/migrate/edges.csv

# Export chats (for completeness)
echo "Exporting chats..."
psql "$DB_URL" -c "\COPY (SELECT id, chat_type, helper_name, user_message, assistant_message, thread_id, focused_node_id, created_at FROM chats ORDER BY id) TO STDOUT WITH CSV HEADER" > tmp/migrate/chats.csv

# Get counts for verification
echo ""
echo "Export complete! Counts:"
echo "------------------------"
echo -n "Nodes: "
psql "$DB_URL" -t -c "SELECT COUNT(*) FROM nodes"
echo -n "Dimensions: "
psql "$DB_URL" -t -c "SELECT COUNT(*) FROM (SELECT unnest(dimensions) FROM nodes WHERE dimensions IS NOT NULL) AS d"
echo -n "Chunks: "
psql "$DB_URL" -t -c "SELECT COUNT(*) FROM chunks"
echo -n "Chunks with embeddings: "
psql "$DB_URL" -t -c "SELECT COUNT(*) FROM chunks WHERE embedding IS NOT NULL"
echo -n "Edges: "
psql "$DB_URL" -t -c "SELECT COUNT(*) FROM edges"
echo -n "Chats: "
psql "$DB_URL" -t -c "SELECT COUNT(*) FROM chats"

echo ""
echo "Files exported to tmp/migrate/"
echo "Next step: Run ./scripts/migrate/import_to_sqlite.sh"
