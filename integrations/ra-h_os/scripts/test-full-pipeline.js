#!/usr/bin/env node
/**
 * Full pipeline test: Extract facts, match, and persist to memory table
 */

const Database = require('better-sqlite3');
const OpenAI = require('openai');
const path = require('path');
const os = require('os');
const crypto = require('crypto');

const dbPath = path.join(os.homedir(), 'Library/Application Support/RA-H/db/rah.sqlite');
const db = new Database(dbPath);

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
const MODEL = process.env.MEMORY_MODEL || 'gpt-4o-mini';

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

function getExistingFacts() {
  const rows = db.prepare(`
    SELECT id, entity_id, content, metadata 
    FROM memory 
    WHERE type='big_memory' AND entity_id LIKE 'fact:%'
  `).all();
  
  return rows.map(r => {
    const meta = safeParse(r.metadata);
    return {
      id: r.id,
      entity_id: r.entity_id,
      text: (r.content || '').trim(),
      meta: meta
    };
  });
}

async function extractFacts(batchJson) {
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

  const result = await chatJSON(MODEL, system, batchJson, 1500);
  return Array.isArray(result?.facts) ? result.facts : [];
}

async function matchFacts(candidates, existing) {
  const system = `Given CANDIDATE facts and EXISTING facts, decide for each candidate whether to:
- REINFORCE one or more existing facts (near-duplicates or same meaning), and/or
- create NEW canonical fact texts when it's genuinely new.

Definitions:
- Similar (reinforce): same meaning with minor wording differences; same named entity with different surface form; specific vs broader phrasing where the core claim aligns.
- New: a distinct fact not covered by any existing entry.

Normalization guidance:
- Prefer simple, canonical phrasing (no quotes unless part of a title).
- Keep <=160 chars; avoid trailing punctuation unless it's part of a title.
- Maintain names/titles/capitalization as they appear; no speculation.

Return STRICT JSON only:
{
  "actions": [
    { "candidate": number, "reinforce": [existing_id, ...], "new": [canonical_text, ...] }
  ]
}

Rules:
- A candidate may reinforce multiple existing items (1→many) if they're all clearly near-duplicates.
- A candidate may also create NEW text(s) if there's a distinct fact not covered by existing items.
- If neither applies (ambiguous/noisy), leave both arrays empty.`;

  const payload = {
    candidates,
    existing_facts: existing.map(e => ({
      id: e.entity_id,
      text: e.text,
      reinforcement_count: e.meta?.reinforcement_count || 0,
      reinforcement_score: e.meta?.reinforcement_score || 0
    }))
  };

  try {
    const res = await chatJSON(MODEL, system, JSON.stringify(payload), 1500);
    if (res && Array.isArray(res.actions)) return { actions: res.actions };
  } catch (e) {
    console.warn('Match LLM failed, using fallback:', e.message);
  }
  
  const actions = candidates.map((c, i) => ({ candidate: i, reinforce: [], new: [c.text] }));
  return { actions };
}

function persistMatches(candidates, existing, matchActions) {
  const nowIso = new Date().toISOString();
  const existingByEntity = new Map(existing.map(e => [e.entity_id, e]));
  
  let reinforced = 0;
  let created = 0;
  
  db.transaction(() => {
    for (const act of (matchActions.actions || [])) {
      const cand = candidates[act.candidate];
      if (!cand || !cand.text) continue;
      
      // REINFORCE existing facts
      for (const target of (act.reinforce || [])) {
        const ex = existingByEntity.get(String(target));
        if (!ex) continue;
        
        const meta = ex.meta || {};
        const scoreInc = cand.explicit ? 5 : 1;
        meta.reinforcement_count = (meta.reinforcement_count || 0) + 1;
        meta.reinforcement_score = (meta.reinforcement_score || 0) + scoreInc;
        meta.last_seen = nowIso;
        meta.first_seen = meta.first_seen || nowIso;
        
        const srcs = new Set(Array.isArray(meta.sources) ? meta.sources : []);
        (cand.sources || []).forEach(s => srcs.add(s));
        meta.sources = Array.from(srcs).slice(0, 20);
        meta.explicit = !!(meta.explicit || cand.explicit);
        meta.user_score = meta.user_score || 0;
        
        db.prepare(`UPDATE memory SET metadata = ? WHERE id = ?`)
          .run(JSON.stringify(meta), ex.id);
        
        reinforced++;
        console.log(`   ↑ REINFORCED fact:${ex.entity_id.substring(5, 13)}... (count: ${meta.reinforcement_count}, score: ${meta.reinforcement_score})`);
      }
      
      // CREATE new facts
      for (const newText of (act.new || [])) {
        const txt = String(newText || cand.text).trim().slice(0, 160);
        if (!txt) continue;
        
        const meta = {
          reinforcement_count: 1,
          reinforcement_score: cand.explicit ? 5 : 1,
          explicit: !!cand.explicit,
          cross_source: false,
          sources: (cand.sources || []).slice(0, 20),
          first_seen: nowIso,
          last_seen: nowIso,
          user_score: 0
        };
        
        const entity = `fact:${crypto.randomUUID()}`;
        db.prepare(`
          INSERT INTO memory(type, entity_id, version, content, metadata, is_current) 
          VALUES('big_memory', ?, 1, ?, ?, 1)
        `).run(entity, txt, JSON.stringify(meta));
        
        created++;
        console.log(`   + NEW fact: "${txt.substring(0, 60)}${txt.length > 60 ? '...' : ''}"`);
      }
    }
  })();
  
  return { reinforced, created };
}

function safeParse(s) {
  try { return s ? JSON.parse(s) : {}; } catch { return {}; }
}

async function runFullPipeline() {
  console.log('═══════════════════════════════════════════════════════');
  console.log('🧪 FULL MEMORY PIPELINE TEST (Last 100 Logs)');
  console.log('═══════════════════════════════════════════════════════\n');
  
  // 1. Fetch logs
  const batch = db.prepare(`
    SELECT id, ts, table_name, action, summary, snapshot_json, chat_helper,
           chat_user_full, chat_assistant_full, node_title, edge_from_title, edge_to_title
    FROM logs_v ORDER BY id DESC LIMIT 100
  `).all().reverse();
  
  console.log(`📊 Fetched ${batch.length} logs (ID ${batch[0].id} → ${batch[batch.length-1].id})\n`);
  
  // 2. Build batch JSON
  const inputJson = [];
  for (const r of batch) {
    if (r.table_name === 'chats') {
      inputJson.push({ 
        id: r.id, type: 'chat', ts: r.ts, 
        helper: r.chat_helper || null, 
        user: r.chat_user_full || '', 
        assistant: r.chat_assistant_full || '' 
      });
    } else if (r.table_name === 'nodes') {
      inputJson.push({ 
        id: r.id, type: 'node', ts: r.ts, 
        title: r.node_title || r.summary || '' 
      });
    } else if (r.table_name === 'edges') {
      inputJson.push({ 
        id: r.id, type: 'edge', ts: r.ts, 
        from_title: r.edge_from_title || '', 
        to_title: r.edge_to_title || '' 
      });
    }
  }
  
  // 3. Get existing facts (before)
  const existingBefore = getExistingFacts();
  console.log(`📋 Existing facts in DB: ${existingBefore.length}\n`);
  
  // 4. Extract candidates
  console.log(`🤖 Extracting facts using ${MODEL}...\n`);
  const candidates = await extractFacts(JSON.stringify(inputJson, null, 2));
  
  console.log(`✅ Extracted ${candidates.length} candidate facts:\n`);
  candidates.forEach((c, i) => {
    console.log(`${i+1}. "${c.text.substring(0, 80)}${c.text.length > 80 ? '...' : ''}"`);
    console.log(`   Explicit: ${c.explicit}, Sources: [${c.sources.slice(0, 3).join(', ')}]`);
  });
  console.log();
  
  // 5. Match against existing
  console.log('🔍 Matching against existing facts...\n');
  const matchActions = await matchFacts(candidates, existingBefore);
  
  console.log(`📝 Match decisions: ${matchActions.actions.length} actions\n`);
  
  // 6. Persist
  console.log('💾 Persisting to database...\n');
  const { reinforced, created } = persistMatches(candidates, existingBefore, matchActions);
  
  // 7. Get existing facts (after)
  const existingAfter = getExistingFacts();
  
  console.log('\n═══════════════════════════════════════════════════════');
  console.log('📊 RESULTS');
  console.log('═══════════════════════════════════════════════════════\n');
  console.log(`Facts before: ${existingBefore.length}`);
  console.log(`Facts after:  ${existingAfter.length}`);
  console.log(`Reinforced:   ${reinforced}`);
  console.log(`Created:      ${created}`);
  console.log();
  
  // 8. Show top facts by score
  const sorted = existingAfter
    .map(f => ({
      text: f.text,
      count: f.meta?.reinforcement_count || 0,
      score: f.meta?.reinforcement_score || 0
    }))
    .sort((a, b) => b.score - a.score)
    .slice(0, 10);
  
  console.log('🏆 Top 10 facts by score:\n');
  sorted.forEach((f, i) => {
    console.log(`${i+1}. [score: ${f.score}, count: ${f.count}]`);
    console.log(`   "${f.text}"`);
    console.log();
  });
  
  db.close();
  console.log('✅ Pipeline complete!\n');
}

runFullPipeline().catch(e => {
  console.error('❌ Pipeline failed:', e.message);
  console.error(e.stack);
  db.close();
  process.exit(1);
});
