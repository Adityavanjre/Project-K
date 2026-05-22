#!/usr/bin/env node

/**
 * Test script for memory UPDATE operation
 * 
 * This script:
 * 1. Shows current memory facts
 * 2. Triggers the memory pipeline manually
 * 3. Shows updated facts after processing
 */

const Database = require('better-sqlite3');
const path = require('path');
const os = require('os');

const dbPath = path.join(os.homedir(), 'Library/Application Support/RA-H/db/rah.sqlite');
const db = new Database(dbPath);

console.log('=== MEMORY UPDATE OPERATION TEST ===\n');

// 1. Show current facts
console.log('📊 CURRENT MEMORY FACTS:\n');
const currentFacts = db.prepare(`
  SELECT 
    id,
    entity_id,
    content,
    json_extract(metadata, '$.reinforcement_count') as count,
    json_extract(metadata, '$.reinforcement_score') as score,
    json_extract(metadata, '$.entities') as entities
  FROM memory 
  WHERE type='big_memory' AND entity_id LIKE 'fact:%' AND is_current=1
  ORDER BY json_extract(metadata, '$.reinforcement_score') DESC
`).all();

currentFacts.forEach((fact, i) => {
  console.log(`${i + 1}. [Score: ${fact.score}, Count: ${fact.count}]`);
  console.log(`   "${fact.content}"`);
  if (fact.entities) {
    try {
      const entities = JSON.parse(fact.entities);
      if (entities && entities.length > 0) {
        console.log(`   Entities: ${entities.join(', ')}`);
      }
    } catch {}
  }
  console.log();
});

// 2. Check pipeline state
console.log('\n📈 PIPELINE STATE:\n');
const pipelineState = db.prepare(`
  SELECT last_processed_log_id, last_run_at 
  FROM memory_pipeline_state 
  WHERE id=1
`).get();

const maxLogId = db.prepare('SELECT MAX(id) as max FROM logs').get();

console.log(`Last processed log: ${pipelineState?.last_processed_log_id || 0}`);
console.log(`Max log ID: ${maxLogId?.max || 0}`);
console.log(`Logs pending: ${(maxLogId?.max || 0) - (pipelineState?.last_processed_log_id || 0)}`);
console.log(`Last run: ${pipelineState?.last_run_at || 'never'}\n`);

// 3. Show recent logs that mention key entities
console.log('\n📝 RECENT LOGS (mentioning ra-h, Paige, knowledge management):\n');
const recentLogs = db.prepare(`
  SELECT id, ts, table_name, summary, chat_user_full
  FROM logs_v
  WHERE 
    (chat_user_full LIKE '%ra-h%' OR 
     chat_user_full LIKE '%Paige%' OR 
     chat_user_full LIKE '%knowledge management%' OR
     chat_user_full LIKE '%dogfood%' OR
     chat_user_full LIKE '%beta%' OR
     summary LIKE '%ra-h%' OR
     summary LIKE '%Paige%')
  ORDER BY id DESC 
  LIMIT 15
`).all();

recentLogs.forEach(log => {
  const preview = log.chat_user_full 
    ? log.chat_user_full.substring(0, 100) 
    : log.summary.substring(0, 100);
  console.log(`Log ${log.id} [${log.ts}]: ${preview}${preview.length >= 100 ? '...' : ''}`);
});

console.log('\n✅ To trigger pipeline manually:');
console.log('   1. Start dev server: npm run dev');
console.log('   2. Create 10+ new logs (chat, create nodes, etc.)');
console.log('   3. Pipeline will auto-run and show UPDATE operations in console (if MEMORY_DEBUG=1)');
console.log('\n   Or run this script again after interacting with the app to see updated facts.\n');

db.close();
