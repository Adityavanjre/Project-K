#!/usr/bin/env node
/*
 Dev utility: Inspect memory claims ledger and write a Markdown report.
 Usage: node scripts/dev/inspect-memory-ledger.js [--out docs/development/reports/memory-ledger.md] [--versions 5]
 Optionally set RAH_DB_PATH to override the default DB path.
*/

const fs = require('fs');
const path = require('path');
const os = require('os');
const { execFileSync } = require('child_process');

const args = process.argv.slice(2);
const outIdx = args.indexOf('--out');
const outPath = outIdx >= 0 ? args[outIdx + 1] : 'docs/development/reports/memory-ledger.md';
const verIdx = args.indexOf('--versions');
const maxVersions = verIdx >= 0 ? parseInt(args[verIdx + 1], 10) : 5;

const defaultDbPath = path.join(os.homedir(), 'Library', 'Application Support', 'RA-H', 'db', 'rah.sqlite');
const dbPath = process.env.RAH_DB_PATH || defaultDbPath;

function q(dbPath, sql, params = []) {
  const paramList = params.map(p => typeof p === 'number' ? String(p) : `'${String(p).replace(/'/g, "''")}'`).join(',');
  const wrapped = params.length ? sql.replace(/\?/g, () => params.shift()) : sql;
  try {
    const out = execFileSync('sqlite3', ['-json', dbPath, wrapped], { encoding: 'utf8' });
    return JSON.parse(out || '[]');
  } catch (e) {
    console.error('sqlite3 query failed:', e.message);
    process.exit(1);
  }
}

function loadCategoryRows(dbPath, category, limit) {
  const sql = `SELECT id, version, is_current, content, metadata, created_at
               FROM memory
               WHERE type='big_memory' AND entity_id='${category}'
               ORDER BY version DESC
               LIMIT ${limit}`;
  return q(dbPath, sql);
}

function parseMeta(m) {
  try { return m ? JSON.parse(m) : {}; } catch { return {}; }
}

function renderTable(rowsLatest, rowsPrev) {
  // rowsLatest: {claim, count, first_seen, last_seen}
  // Map previous counts for delta
  const prevMap = new Map(rowsPrev.map(r => [r.claim, r.count]));
  const header = `| claim | count | Δ | first_seen | last_seen |\n|---|---:|---:|---|---|`;
  const lines = rowsLatest.map(r => {
    const prev = prevMap.get(r.claim) || 0;
    const delta = r.count - prev;
    return `| ${r.claim} | ${r.count} | ${delta >= 0 ? '+'+delta : delta} | ${r.first_seen} | ${r.last_seen} |`;
  });
  return [header, ...lines].join('\n');
}

function main() {
  const categories = ['world_model','interests','goals','styles','connections'];
  let md = `# Memory Ledger Report\n\n- DB: \`${dbPath}\`\n- Generated: ${new Date().toISOString()}\n- Versions shown per category: ${maxVersions}\n\n`;

  for (const cat of categories) {
    const rows = loadCategoryRows(dbPath, cat, maxVersions);
    if (!rows || rows.length === 0) {
      md += `## ${cat}\n(No rows)\n\n`;
      continue;
    }
    const current = rows[0];
    const prev = rows[1] || null;
    const curMeta = parseMeta(current.metadata);
    const prevMeta = parseMeta(prev && prev.metadata);
    const curClaims = curMeta.claims || {};
    const prevClaims = prevMeta.claims || {};
    const toArr = (obj) => Object.entries(obj).map(([k, v]) => ({ claim: k, count: Number(v.count || 0), first_seen: v.first_seen || '', last_seen: v.last_seen || '' }));
    const curArr = toArr(curClaims).sort((a,b) => b.count - a.count || (a.last_seen > b.last_seen ? -1 : 1)).slice(0, 50);
    const prevArr = toArr(prevClaims).sort((a,b) => b.count - a.count).slice(0, 50);

    md += `## ${cat}\n\n`;
    md += `- current version: ${current.version} (created ${current.created_at})\n`;
    if (prev) md += `- previous version: ${prev.version} (created ${prev.created_at})\n`;
    md += `- current paragraph (first 200 chars):\n\n> ${String(current.content || '').slice(0,200)}\n\n`;
    md += `### Top Claims (current vs previous Δ)\n\n`;
    md += renderTable(curArr, prevArr) + '\n\n';
  }

  // Ensure folder exists
  const outAbs = path.resolve(outPath);
  fs.mkdirSync(path.dirname(outAbs), { recursive: true });
  fs.writeFileSync(outAbs, md, 'utf8');

  console.log(`Wrote report: ${outAbs}`);
}

main();
