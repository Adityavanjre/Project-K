#!/usr/bin/env node
/**
 * Standalone test script to verify memory extraction on last 100 logs
 */

const Database = require('better-sqlite3');
const OpenAI = require('openai');
const path = require('path');
const os = require('os');

const dbPath = path.join(os.homedir(), 'Library/Application Support/RA-H/db/rah.sqlite');
const db = new Database(dbPath);

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

async function chatJSON(model, system, user, maxTokens = 1500) {
  const payload = {
    model,
    messages: [
      { role: 'system', content: system },
      { role: 'user', content: user }
    ]
  };
  
  if (model.includes('gpt-5')) {
    payload.max_completion_tokens = maxTokens;
    payload.response_format = { type: 'json_object' };
  } else {
    payload.temperature = 0.3;
    payload.max_tokens = maxTokens;
  }
  
  const completion = await openai.chat.completions.create(payload);
  const text = completion.choices[0]?.message?.content || '{}';
  
  try {
    return JSON.parse(text);
  } catch {
    const m = text.match(/\{[\s\S]*\}/);
    if (m) {
      try { return JSON.parse(m[0]); } catch {}
    }
    throw new Error('LLM did not return valid JSON');
  }
}

async function testExtraction() {
  console.log('📊 Testing memory extraction on last 100 logs\n');
  
  // Get last 100 logs
  const batch = db.prepare(`
    SELECT id, ts, table_name, action, summary, snapshot_json, chat_helper,
           chat_user_full, chat_assistant_full, node_title, edge_from_title, edge_to_title
    FROM logs_v ORDER BY id DESC LIMIT 100
  `).all().reverse();
  
  console.log(`✅ Fetched ${batch.length} logs (ID ${batch[0].id} → ${batch[batch.length-1].id})\n`);
  
  // Build input JSON
  const inputJson = [];
  for (const r of batch) {
    if (r.table_name === 'chats') {
      inputJson.push({ 
        id: r.id, 
        type: 'chat', 
        ts: r.ts, 
        helper: r.chat_helper || null, 
        user: r.chat_user_full || '', 
        assistant: r.chat_assistant_full || '' 
      });
    } else if (r.table_name === 'nodes') {
      inputJson.push({ 
        id: r.id, 
        type: 'node', 
        ts: r.ts, 
        title: r.node_title || r.summary || '' 
      });
    } else if (r.table_name === 'edges') {
      inputJson.push({ 
        id: r.id, 
        type: 'edge', 
        ts: r.ts, 
        from_title: r.edge_from_title || '', 
        to_title: r.edge_to_title || '' 
      });
    }
  }
  
  console.log('📝 Sample entries:');
  console.log('First:', JSON.stringify(inputJson[0], null, 2));
  console.log('Last:', JSON.stringify(inputJson[inputJson.length-1], null, 2));
  console.log();
  
  // Look for Paige mentions
  const paigeLogs = inputJson.filter(e => 
    e.type === 'chat' && (e.user.toLowerCase().includes('paige') || e.assistant.toLowerCase().includes('paige'))
  );
  console.log(`🔍 Found ${paigeLogs.length} entries mentioning "paige":`);
  paigeLogs.forEach(log => {
    console.log(`   ID ${log.id}: "${log.user.substring(0, 60)}..."`);
  });
  console.log();
  
  // Extract facts
  const MODEL = process.env.MEMORY_MODEL || 'gpt-4o-mini';
  console.log(`🤖 Using model: ${MODEL}\n`);
  
  const system = `You are given a JSON array of the last 10–100 activity logs. Each entry has id and fields: for chats {id,type:'chat',ts,helper,user,assistant}, for nodes {id,type:'node',ts,title}, for edges {id,type:'edge',ts,from_title,to_title}.
Extract ANY potentially important, durable facts the user explicitly stated or clearly implied — facts that help refine their research/thinking/learning process over time.
Keep each fact atomic and canonical (<=160 chars). Do not invent or generalize beyond evidence.

Acceptable, generic fact types include: identity/role, relationships, goals/projects, interests/domains, learning styles, preferences, beliefs/world model, workflows/tools, constraints/availability, and assets/channels (e.g., podcast/newsletter titles).

Return STRICT JSON only:
{ "facts": [ { "text": string, "explicit": boolean, "sources": [log_id, ...] } ] }

Rules:
- text is a single atomic fact (<=160 chars), canonical phrasing.
- explicit = true only for clear first-person/possessive or labeled statements (e.g., "my…", "I…", "partner named…").
- sources: include 1–3 representative log ids (from the provided id fields) for each fact.`;

  try {
    console.log('⏳ Calling LLM...\n');
    const result = await chatJSON(MODEL, system, JSON.stringify(inputJson, null, 2), 1500);
    
    console.log('════════════════════════════════════════');
    console.log('📋 EXTRACTION RESULT');
    console.log('════════════════════════════════════════\n');
    
    if (!result || !result.facts || result.facts.length === 0) {
      console.log('❌ NO FACTS EXTRACTED\n');
      console.log('Raw response:', JSON.stringify(result, null, 2));
      return;
    }
    
    console.log(`✅ Extracted ${result.facts.length} facts:\n`);
    
    result.facts.forEach((f, i) => {
      console.log(`${i+1}. "${f.text}"`);
      console.log(`   Explicit: ${f.explicit}`);
      console.log(`   Sources: [${f.sources.join(', ')}]`);
      console.log();
    });
    
    // Check for Paige facts
    const paigeFacts = result.facts.filter(f => 
      f.text.toLowerCase().includes('paige')
    );
    
    if (paigeFacts.length > 0) {
      console.log(`🎯 Found ${paigeFacts.length} fact(s) about Paige!`);
    } else {
      console.log(`⚠️  No facts extracted about Paige (despite ${paigeLogs.length} mentions in logs)`);
    }
    
  } catch (e) {
    console.error('❌ ERROR:', e.message);
    console.error(e.stack);
  } finally {
    db.close();
  }
}

testExtraction().catch(console.error);
