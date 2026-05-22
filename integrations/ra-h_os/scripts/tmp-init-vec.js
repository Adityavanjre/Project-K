const Database = require('better-sqlite3');
const path = require('path');

const dbPath = process.argv[2];
if (!dbPath) { 
  console.error('Usage: node tmp-init-vec.js <dbPath>'); 
  process.exit(1); 
}

const db = new Database(dbPath);
const ext = process.platform === 'darwin' ? 'dylib' : process.platform === 'win32' ? 'dll' : 'so';
const vecPath = process.env.SQLITE_VEC_EXTENSION_PATH || path.join(process.cwd(), 'vendor', 'sqlite-extensions', `vec0.${ext}`);
const dimensions = Number(process.env.EMBEDDING_DIMENSIONS || '1536');
if (!Number.isInteger(dimensions) || dimensions <= 0) {
  throw new Error(`Invalid EMBEDDING_DIMENSIONS="${process.env.EMBEDDING_DIMENSIONS}"`);
}

db.loadExtension(vecPath);
db.exec(`
  CREATE VIRTUAL TABLE IF NOT EXISTS vec_nodes USING vec0(node_id INTEGER PRIMARY KEY, embedding FLOAT[${dimensions}]);
  CREATE VIRTUAL TABLE IF NOT EXISTS vec_chunks USING vec0(chunk_id INTEGER PRIMARY KEY, embedding FLOAT[${dimensions}]);
`);

console.log('✓ vec tables ensured');
db.close();
