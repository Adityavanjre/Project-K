#!/usr/bin/env bash
set -euo pipefail

# Repair rebuildable FTS corruption by rebuilding a clean SQLite file from the
# readable canonical tables, then swapping the rebuilt file into place.

DB_PATH=${SQLITE_DB_PATH:-}
if [ -z "${DB_PATH}" ] && [ -f ".env.local" ]; then
  DB_PATH=$(grep -E '^SQLITE_DB_PATH=' .env.local | sed 's/^SQLITE_DB_PATH=//' | sed 's/^"\(.*\)"$/\1/') || true
fi
if [ -z "${DB_PATH}" ]; then
  DB_PATH="$HOME/Library/Application Support/RA-H/db/rah.sqlite"
fi

if [ ! -f "$DB_PATH" ]; then
  echo "Error: Resolved DB not found: $DB_PATH" >&2
  exit 1
fi

DB_DIR="$(dirname "$DB_PATH")"
DB_NAME="$(basename "$DB_PATH")"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
case "$(uname -s)" in
  Darwin*) VEC_EXT="dylib" ;;
  MINGW*|MSYS*|CYGWIN*) VEC_EXT="dll" ;;
  *) VEC_EXT="so" ;;
esac
VEC_EXTENSION_PATH="${SQLITE_VEC_EXTENSION_PATH:-$ROOT_DIR/vendor/sqlite-extensions/vec0.$VEC_EXT}"
EMBEDDING_DIMENSIONS="${EMBEDDING_DIMENSIONS:-1536}"
if ! [[ "$EMBEDDING_DIMENSIONS" =~ ^[0-9]+$ ]] || [ "$EMBEDDING_DIMENSIONS" -le 0 ]; then
  echo "Invalid EMBEDDING_DIMENSIONS: $EMBEDDING_DIMENSIONS" >&2
  exit 1
fi
TS=$(date +"%Y%m%d_%H%M%S")
RAW_BACKUP_DIR="$DB_DIR/working/fts_repair_${TS}"
REBUILT_DB="$DB_DIR/${DB_NAME}.rebuilt.${TS}"
QUOTED_DB_PATH=${DB_PATH//\'/\'\'}
HAS_SOURCE_VEC_NODES=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='vec_nodes';")
HAS_SOURCE_VEC_CHUNKS=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='vec_chunks';")

VEC_SQL_HEADER=""
VEC_SQL_BODY=""
if [ -f "$VEC_EXTENSION_PATH" ]; then
  if [ "$HAS_SOURCE_VEC_NODES" -gt 0 ] || [ "$HAS_SOURCE_VEC_CHUNKS" -gt 0 ]; then
    VEC_SQL_HEADER=".load $VEC_EXTENSION_PATH"
    VEC_SQL_BODY="
CREATE VIRTUAL TABLE vec_nodes USING vec0(
  node_id INTEGER PRIMARY KEY,
  embedding FLOAT[$EMBEDDING_DIMENSIONS]
);

CREATE VIRTUAL TABLE vec_chunks USING vec0(
  chunk_id INTEGER PRIMARY KEY,
  embedding FLOAT[$EMBEDDING_DIMENSIONS]
);
"

    if [ "$HAS_SOURCE_VEC_NODES" -gt 0 ]; then
      VEC_SQL_BODY="$VEC_SQL_BODY
INSERT INTO vec_nodes(node_id, embedding)
SELECT node_id, embedding FROM source.vec_nodes;
"
    fi

    if [ "$HAS_SOURCE_VEC_CHUNKS" -gt 0 ]; then
      VEC_SQL_BODY="$VEC_SQL_BODY
INSERT INTO vec_chunks(chunk_id, embedding)
SELECT chunk_id, embedding FROM source.vec_chunks;
"
    fi
  fi
elif [ "$HAS_SOURCE_VEC_NODES" -gt 0 ] || [ "$HAS_SOURCE_VEC_CHUNKS" -gt 0 ]; then
  echo "Warning: sqlite-vec extension not found at $VEC_EXTENSION_PATH; vec tables will not be restored." >&2
fi

mkdir -p "$RAW_BACKUP_DIR"

cp -p "$DB_PATH" "$RAW_BACKUP_DIR/$DB_NAME"
if [ -f "${DB_PATH}-wal" ]; then
  cp -p "${DB_PATH}-wal" "$RAW_BACKUP_DIR/${DB_NAME}-wal"
fi
if [ -f "${DB_PATH}-shm" ]; then
  cp -p "${DB_PATH}-shm" "$RAW_BACKUP_DIR/${DB_NAME}-shm"
fi

echo "Raw backup saved to: $RAW_BACKUP_DIR"

echo "Preflight source probes:"
sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM nodes;" | sed 's/^/  nodes: /'
sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM edges;" | sed 's/^/  edges: /'
sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM chunks;" | sed 's/^/  chunks: /'
sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM nodes_fts;" | sed 's/^/  nodes_fts: /' || true
sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM chunks_fts;" | sed 's/^/  chunks_fts: /' || true

rm -f "$REBUILT_DB" "${REBUILT_DB}-wal" "${REBUILT_DB}-shm"

sqlite3 "$REBUILT_DB" <<SQL
$VEC_SQL_HEADER
PRAGMA journal_mode = DELETE;
PRAGMA synchronous = NORMAL;
PRAGMA foreign_keys = OFF;
ATTACH DATABASE '$QUOTED_DB_PATH' AS source;

CREATE TABLE schema_version (
  version INTEGER PRIMARY KEY,
  applied_at TEXT DEFAULT CURRENT_TIMESTAMP,
  description TEXT
);

CREATE TABLE agents (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  key TEXT UNIQUE NOT NULL,
  display_name TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'executor',
  system_prompt TEXT NOT NULL,
  available_tools TEXT NOT NULL,
  model TEXT NOT NULL,
  description TEXT,
  enabled INTEGER DEFAULT 1,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  memory TEXT,
  prompts TEXT
);

CREATE TABLE nodes (
  id INTEGER PRIMARY KEY,
  title TEXT,
  description TEXT,
  source TEXT,
  link TEXT,
  event_date TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
  metadata TEXT,
  embedding BLOB,
  embedding_updated_at TEXT,
  embedding_text TEXT,
  chunk_status TEXT DEFAULT 'not_chunked'
);

CREATE TABLE edges (
  id INTEGER PRIMARY KEY,
  from_node_id INTEGER NOT NULL,
  to_node_id INTEGER NOT NULL,
  source TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  context TEXT,
  explanation TEXT,
  FOREIGN KEY (from_node_id) REFERENCES nodes(id) ON DELETE CASCADE,
  FOREIGN KEY (to_node_id) REFERENCES nodes(id) ON DELETE CASCADE
);

CREATE TABLE chunks (
  id INTEGER PRIMARY KEY,
  node_id INTEGER NOT NULL,
  chunk_idx INTEGER,
  text TEXT NOT NULL,
  embedding_type TEXT DEFAULT 'text-embedding-3-small',
  metadata TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (node_id) REFERENCES nodes(id) ON DELETE CASCADE
);

CREATE TABLE chats (
  id INTEGER PRIMARY KEY,
  chat_type TEXT,
  helper_name TEXT,
  agent_type TEXT DEFAULT 'orchestrator',
  delegation_id INTEGER,
  user_message TEXT,
  assistant_message TEXT,
  thread_id TEXT,
  focused_node_id INTEGER,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  metadata TEXT,
  FOREIGN KEY (focused_node_id) REFERENCES nodes(id) ON DELETE SET NULL
);

CREATE TABLE logs (
  id INTEGER PRIMARY KEY,
  ts TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  table_name TEXT NOT NULL,
  action TEXT NOT NULL,
  row_id INTEGER NOT NULL,
  summary TEXT,
  snapshot_json TEXT,
  enriched_summary TEXT
);

CREATE TABLE voice_usage (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  chat_id INTEGER,
  session_id TEXT,
  helper_name TEXT,
  request_id TEXT,
  message_id TEXT,
  voice TEXT,
  model TEXT,
  chars INTEGER,
  cost_usd REAL,
  duration_ms INTEGER,
  text_preview TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE SET NULL
);

CREATE TABLE dimension_migration_snapshots (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  migrated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  dimension_count INTEGER NOT NULL,
  assignment_count INTEGER NOT NULL,
  payload TEXT
);

INSERT INTO schema_version SELECT version, applied_at, description FROM source.schema_version;
INSERT INTO agents SELECT id, key, display_name, role, system_prompt, available_tools, model, description, enabled, created_at, updated_at, memory, prompts FROM source.agents;
INSERT INTO nodes SELECT id, title, description, source, link, event_date, created_at, updated_at, metadata, embedding, embedding_updated_at, embedding_text, chunk_status FROM source.nodes;
INSERT INTO edges SELECT id, from_node_id, to_node_id, source, created_at, context, explanation FROM source.edges;
INSERT INTO chunks SELECT id, node_id, chunk_idx, text, embedding_type, metadata, created_at FROM source.chunks;
INSERT INTO chats SELECT id, chat_type, helper_name, agent_type, delegation_id, user_message, assistant_message, thread_id, focused_node_id, created_at, metadata FROM source.chats;
INSERT INTO logs SELECT id, ts, table_name, action, row_id, summary, snapshot_json, enriched_summary FROM source.logs;
INSERT INTO voice_usage SELECT id, chat_id, session_id, helper_name, request_id, message_id, voice, model, chars, cost_usd, duration_ms, text_preview, created_at FROM source.voice_usage;
INSERT INTO dimension_migration_snapshots SELECT id, migrated_at, dimension_count, assignment_count, payload FROM source.dimension_migration_snapshots;

CREATE INDEX idx_edges_from ON edges(from_node_id);
CREATE INDEX idx_edges_to ON edges(to_node_id);
CREATE INDEX idx_nodes_updated_at ON nodes(updated_at DESC);
CREATE INDEX idx_chunks_node_id ON chunks(node_id);
CREATE INDEX idx_chunks_by_node ON chunks(node_id);
CREATE INDEX idx_chunks_by_node_idx ON chunks(node_id, chunk_idx);
CREATE INDEX idx_chats_thread ON chats(thread_id);
CREATE INDEX idx_chats_created_at ON chats(created_at DESC);
CREATE INDEX idx_logs_ts ON logs(ts);
CREATE INDEX idx_logs_table_ts ON logs(table_name, ts);
CREATE INDEX idx_logs_table_row ON logs(table_name, row_id);
CREATE INDEX idx_voice_usage_session ON voice_usage(session_id, created_at);
CREATE INDEX idx_voice_usage_chat ON voice_usage(chat_id);

CREATE VIEW nodes_v AS
SELECT n.id,
       n.title,
       n.description,
       n.source,
       n.link,
       n.event_date,
       n.metadata,
       n.created_at,
       n.updated_at
FROM nodes n;

CREATE VIEW logs_v AS
SELECT
  m.id,
  m.ts,
  m.table_name,
  m.action,
  m.row_id,
  m.summary,
  m.enriched_summary,
  m.snapshot_json,
  CASE WHEN m.table_name='nodes' THEN n.title END AS node_title,
  CASE WHEN m.table_name='edges' THEN nf.title END AS edge_from_title,
  CASE WHEN m.table_name='edges' THEN nt.title END AS edge_to_title,
  CASE WHEN m.table_name='chats' THEN c.helper_name END AS chat_helper,
  CASE WHEN m.table_name='chats' THEN substr(c.user_message,1,120) END AS chat_user_preview,
  CASE WHEN m.table_name='chats' THEN substr(c.assistant_message,1,120) END AS chat_assistant_preview,
  CASE WHEN m.table_name='chats' THEN c.user_message END AS chat_user_full,
  CASE WHEN m.table_name='chats' THEN c.assistant_message END AS chat_assistant_full
FROM logs m
LEFT JOIN nodes n ON (m.table_name='nodes' AND m.row_id = n.id)
LEFT JOIN edges e ON (m.table_name='edges' AND m.row_id = e.id)
LEFT JOIN nodes nf ON e.from_node_id = nf.id
LEFT JOIN nodes nt ON e.to_node_id = nt.id
LEFT JOIN chats c ON (m.table_name='chats' AND m.row_id = c.id);

CREATE VIRTUAL TABLE nodes_fts USING fts5(
  title,
  source,
  description,
  content='nodes',
  content_rowid='id'
);

CREATE VIRTUAL TABLE chunks_fts USING fts5(
  text,
  content='chunks',
  content_rowid='id'
);

$VEC_SQL_BODY

INSERT INTO nodes_fts(nodes_fts) VALUES('rebuild');
INSERT INTO chunks_fts(chunks_fts) VALUES('rebuild');

CREATE TRIGGER nodes_fts_ai AFTER INSERT ON nodes BEGIN
  INSERT INTO nodes_fts(rowid, title, source, description)
  VALUES (new.id, new.title, new.source, new.description);
END;

CREATE TRIGGER nodes_fts_ad AFTER DELETE ON nodes BEGIN
  INSERT INTO nodes_fts(nodes_fts, rowid, title, source, description)
  VALUES('delete', old.id, old.title, old.source, old.description);
END;

CREATE TRIGGER nodes_fts_au AFTER UPDATE OF title, source, description ON nodes BEGIN
  INSERT INTO nodes_fts(nodes_fts, rowid, title, source, description)
  VALUES('delete', old.id, old.title, old.source, old.description);
  INSERT INTO nodes_fts(rowid, title, source, description)
  VALUES (new.id, new.title, new.source, new.description);
END;

CREATE TRIGGER chunks_fts_ai AFTER INSERT ON chunks BEGIN
  INSERT INTO chunks_fts(rowid, text)
  VALUES (new.id, new.text);
END;

CREATE TRIGGER chunks_fts_ad AFTER DELETE ON chunks BEGIN
  INSERT INTO chunks_fts(chunks_fts, rowid, text)
  VALUES('delete', old.id, old.text);
END;

CREATE TRIGGER chunks_fts_au AFTER UPDATE OF text ON chunks BEGIN
  INSERT INTO chunks_fts(chunks_fts, rowid, text)
  VALUES('delete', old.id, old.text);
  INSERT INTO chunks_fts(rowid, text)
  VALUES (new.id, new.text);
END;

CREATE TRIGGER trg_nodes_ai AFTER INSERT ON nodes BEGIN
  INSERT INTO logs(table_name, action, row_id, summary, snapshot_json)
  VALUES('nodes', 'insert', NEW.id,
         printf('node created: %s', COALESCE(NEW.title,'')),
         json_object('id', NEW.id, 'title', NEW.title, 'link', NEW.link));
END;

CREATE TRIGGER trg_nodes_au AFTER UPDATE ON nodes BEGIN
  INSERT INTO logs(table_name, action, row_id, summary, snapshot_json)
  VALUES('nodes', 'update', NEW.id,
         printf('node updated: %s', COALESCE(NEW.title,'')),
         json_object('id', NEW.id, 'title', NEW.title, 'link', NEW.link));
END;

CREATE TRIGGER trg_edges_ai AFTER INSERT ON edges BEGIN
  INSERT INTO logs(table_name, action, row_id, summary, snapshot_json)
  VALUES('edges', 'insert', NEW.id,
         printf('edge %d→%d (%s)', NEW.from_node_id, NEW.to_node_id, COALESCE(NEW.source,'')),
         json_object(
           'id', NEW.id,
           'from', NEW.from_node_id,
           'to', NEW.to_node_id,
           'source', NEW.source,
           'from_title', substr((SELECT title FROM nodes WHERE id = NEW.from_node_id), 1, 120),
           'to_title', substr((SELECT title FROM nodes WHERE id = NEW.to_node_id), 1, 120)
         ));
END;

CREATE TRIGGER trg_edges_au AFTER UPDATE ON edges BEGIN
  INSERT INTO logs(table_name, action, row_id, summary, snapshot_json)
  VALUES('edges', 'update', NEW.id,
         printf('edge updated %d→%d', NEW.from_node_id, NEW.to_node_id),
         json_object(
           'id', NEW.id,
           'from', NEW.from_node_id,
           'to', NEW.to_node_id,
           'source', NEW.source,
           'from_title', substr((SELECT title FROM nodes WHERE id = NEW.from_node_id), 1, 120),
           'to_title', substr((SELECT title FROM nodes WHERE id = NEW.to_node_id), 1, 120)
         ));
END;

CREATE TRIGGER trg_edges_update_nodes_on_insert
AFTER INSERT ON edges
BEGIN
  UPDATE nodes SET updated_at = strftime('%Y-%m-%dT%H:%M:%f', 'now') || 'Z' WHERE id = NEW.from_node_id;
  UPDATE nodes SET updated_at = strftime('%Y-%m-%dT%H:%M:%f', 'now') || 'Z' WHERE id = NEW.to_node_id;
END;

CREATE TRIGGER trg_chats_ai AFTER INSERT ON chats BEGIN
  INSERT INTO logs(table_name, action, row_id, summary, snapshot_json)
  VALUES('chats', 'insert', NEW.id,
         printf('chat: %s (%s)', COALESCE(NEW.helper_name,''), COALESCE(NEW.thread_id,'')),
         json_object(
           'id', NEW.id,
           'helper', NEW.helper_name,
           'thread', NEW.thread_id,
           'user_preview', substr(COALESCE(NEW.user_message,''), 1, 120),
           'assistant_preview', substr(COALESCE(NEW.assistant_message,''), 1, 120)
         ));
END;

CREATE TRIGGER trg_logs_prune AFTER INSERT ON logs BEGIN
  DELETE FROM logs WHERE id < NEW.id - 10000;
END;

DETACH DATABASE source;
PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;
PRAGMA optimize;
SQL

echo "Rebuilt DB written to: $REBUILT_DB"

echo "Post-rebuild probes:"
sqlite3 "$REBUILT_DB" "PRAGMA quick_check;" | sed 's/^/  quick_check: /'
sqlite3 "$REBUILT_DB" "PRAGMA integrity_check;" | sed 's/^/  integrity_check: /'
sqlite3 "$REBUILT_DB" "SELECT COUNT(*) FROM nodes_fts;" | sed 's/^/  nodes_fts: /'
sqlite3 "$REBUILT_DB" "SELECT COUNT(*) FROM chunks_fts;" | sed 's/^/  chunks_fts: /'
if [ "$HAS_SOURCE_VEC_NODES" -gt 0 ] && [ -f "$VEC_EXTENSION_PATH" ]; then
  sqlite3 "$REBUILT_DB" ".load $VEC_EXTENSION_PATH" "SELECT COUNT(*) FROM vec_nodes;" | sed 's/^/  vec_nodes: /'
fi
if [ "$HAS_SOURCE_VEC_CHUNKS" -gt 0 ] && [ -f "$VEC_EXTENSION_PATH" ]; then
  sqlite3 "$REBUILT_DB" ".load $VEC_EXTENSION_PATH" "SELECT COUNT(*) FROM vec_chunks;" | sed 's/^/  vec_chunks: /'
fi

mv "$DB_PATH" "${DB_PATH}.corrupt.${TS}"
if [ -f "${DB_PATH}-wal" ]; then
  mv "${DB_PATH}-wal" "${DB_PATH}-wal.corrupt.${TS}"
fi
if [ -f "${DB_PATH}-shm" ]; then
  mv "${DB_PATH}-shm" "${DB_PATH}-shm.corrupt.${TS}"
fi
mv "$REBUILT_DB" "$DB_PATH"
rm -f "${DB_PATH}-wal" "${DB_PATH}-shm"
rm -f "${REBUILT_DB}-wal" "${REBUILT_DB}-shm"

echo "Swapped rebuilt DB into place: $DB_PATH"
echo "Original live files preserved with suffix .corrupt.${TS}"
