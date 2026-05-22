#!/bin/bash
# Import CSV data into SQLite database

set -e  # Exit on error

echo "Starting SQLite database import..."
echo "================================"

# Remove old database if exists
if [ -f "rah_trial.db" ]; then
    echo "Removing existing rah_trial.db..."
    rm -f rah_trial.db
fi

# Create database with schema
echo "Creating database with optimized schema..."
sqlite3 rah_trial.db < scripts/migrate/sqlite_schema.sql

# Import CSV files
echo ""
echo "Importing data from CSV files..."
echo "--------------------------------"

sqlite3 rah_trial.db <<'EOF'
.mode csv
.headers on

-- Import nodes (handle embedded quotes/newlines)
.print "Importing nodes..."
.separator ","
.import tmp/migrate/nodes.csv nodes_temp
INSERT INTO nodes SELECT * FROM nodes_temp WHERE id != 'id';
DROP TABLE nodes_temp;

-- Import node dimensions
.print "Importing dimensions..."
.import tmp/migrate/node_dimensions.csv node_dimensions

-- Import chunks
.print "Importing chunks..."
.separator ","
.import tmp/migrate/chunks.csv chunks_temp
INSERT INTO chunks SELECT * FROM chunks_temp WHERE id != 'id';
DROP TABLE chunks_temp;

-- Import embeddings
.print "Importing embeddings (this may take a moment)..."
.import tmp/migrate/chunk_embeddings.csv chunk_embeddings

-- Import edges
.print "Importing edges..."
.import tmp/migrate/edges.csv edges

-- Import chats
.print "Importing chats..."
.separator ","
.import tmp/migrate/chats.csv chats_temp
INSERT INTO chats SELECT * FROM chats_temp WHERE id != 'id';
DROP TABLE chats_temp;

-- Populate FTS indexes
.print ""
.print "Building full-text search indexes..."
INSERT INTO chunks_fts(rowid, text) SELECT id, text FROM chunks;
INSERT INTO nodes_fts(rowid, title, content) SELECT id, title, content FROM nodes;

-- Run ANALYZE for query optimization
.print "Analyzing tables for query optimization..."
ANALYZE;

-- Verify imports with counts
.print ""
.print "Import complete! Verifying counts:"
.print "===================================="
SELECT printf('Nodes:                  %d', COUNT(*)) FROM nodes;
SELECT printf('Node dimensions:        %d', COUNT(*)) FROM node_dimensions;
SELECT printf('Unique dimensions:      %d', COUNT(DISTINCT dimension)) FROM node_dimensions;
SELECT printf('Chunks:                 %d', COUNT(*)) FROM chunks;
SELECT printf('Chunks with embeddings: %d', COUNT(*)) FROM chunk_embeddings;
SELECT printf('Edges:                  %d', COUNT(*)) FROM edges;
SELECT printf('Chats:                  %d', COUNT(*)) FROM chats;
SELECT printf('FTS chunks indexed:     %d', COUNT(*)) FROM chunks_fts;
SELECT printf('FTS nodes indexed:      %d', COUNT(*)) FROM nodes_fts;

-- Database statistics
.print ""
.print "Database Statistics:"
.print "===================="
SELECT printf('Database size:          %.2f MB', page_count * page_size / 1024.0 / 1024.0) FROM pragma_page_count(), pragma_page_size();
SELECT printf('Cache size:             %.0f MB', cache_size * -1 / 1000.0) FROM pragma_cache_size();
SELECT printf('Journal mode:           %s', journal_mode) FROM pragma_journal_mode();

-- Sample data verification
.print ""
.print "Sample data (first 3 nodes):"
.print "============================="
.mode column
.width 10 40
SELECT id, substr(title, 1, 40) as title FROM nodes LIMIT 3;

.print ""
.print "Sample dimensions for node 5:"
.print "=============================="
SELECT dimension FROM node_dimensions WHERE node_id = 5 LIMIT 5;

EOF

echo ""
echo "✅ SQLite database created successfully: rah_trial.db"
echo ""
echo "Database is ready for testing!"
echo "Next steps:"
echo "  1. Install sqlite-vec extension for vector search (optional)"
echo "  2. Run performance benchmarks"
echo "  3. Compare with PostgreSQL baseline"
