import fs from 'fs';
import path from 'path';
import Database from 'better-sqlite3';
import { randomUUID } from 'crypto';
import { scenarios } from './scenarios';
import { EvalCategory, Scenario } from './types';

type EvalChatRow = {
  trace_id: string;
  scenario_id: string;
  assistant_message: string | null;
  latency_ms: number | null;
  input_tokens: number | null;
  output_tokens: number | null;
  total_tokens: number | null;
  estimated_cost_usd: number | null;
};

type EvalToolCallRow = {
  tool_name: string;
  args_json: string | null;
};

type EvalResult = {
  scenario: string;
  passed: boolean;
  failures: string[];
  warnings: string[];
  latencyMs?: number | null;
  totalTokens?: number | null;
  estimatedCostUsd?: number | null;
  triggerStats?: {
    tp: number;
    fp: number;
    fn: number;
  };
};

const BASE_URL = process.env.RAH_EVALS_BASE_URL || 'http://localhost:3000';
const DATASET_ENV = process.env.RAH_EVALS_DATASET_ID;
const CATEGORY_ENV = (process.env.RAH_EVALS_CATEGORY || process.env.RAH_EVALS_SUITE || 'all').toLowerCase();
const WAIT_TIMEOUT_MS = Number(process.env.RAH_EVALS_TIMEOUT_MS || 60000);
const LOG_DB_PATH = path.join(process.cwd(), 'logs', 'evals.sqlite');
const RAH_DB_PATH = process.env.SQLITE_DB_PATH || path.join(
  process.env.HOME || '~',
  'Library/Application Support/RA-H/db/rah.sqlite'
);

function loadDatasetId() {
  if (DATASET_ENV) return DATASET_ENV;
  const datasetPath = path.join(process.cwd(), 'tests', 'evals', 'dataset.json');
  const raw = fs.readFileSync(datasetPath, 'utf-8');
  const parsed = JSON.parse(raw);
  return parsed.id || 'default';
}

type EvalCategoryFilter = 'all' | EvalCategory;

type FocusedNodeContext = {
  id: number;
  title: string;
  description: string | null;
  link: string | null;
  chunk_status: string | null;
  chunk: string | null;
  metadata: string | null;
};

function getDefaultScenarioCategories(scenario: Scenario): EvalCategory[] {
  if (scenario.id.includes('search') || scenario.id.includes('quote')) {
    return ['search'];
  }
  if (scenario.id.includes('skill')) {
    return ['skills'];
  }
  if (scenario.id.includes('extract') || scenario.id.includes('ingest')) {
    return ['ingestion', 'tools'];
  }
  return ['database', 'tools'];
}

function shouldRunScenario(scenario: Scenario, category: EvalCategoryFilter) {
  if (category === 'all') return true;
  const categories = scenario.categories && scenario.categories.length > 0
    ? scenario.categories
    : getDefaultScenarioCategories(scenario);
  return categories.includes(category);
}

function resolveFocusedNodeId(query: Scenario['input']['focusedNodeQuery']): number | null {
  if (!query) return null;
  if (!fs.existsSync(RAH_DB_PATH)) return null;
  const db = new Database(RAH_DB_PATH, { readonly: true, fileMustExist: true });
  if (query.titleEquals) {
    const row = db.prepare(`
      SELECT id
      FROM nodes
      WHERE title = ?
      ORDER BY datetime(created_at) DESC
      LIMIT 1
    `).get(query.titleEquals) as { id?: number } | undefined;
    return row?.id ?? null;
  }
  if (query.titleContains) {
    const row = db.prepare(`
      SELECT id
      FROM nodes
      WHERE title LIKE ?
      ORDER BY datetime(created_at) DESC
      LIMIT 1
    `).get(`%${query.titleContains}%`) as { id?: number } | undefined;
    return row?.id ?? null;
  }
  return null;
}

function loadFocusedNodeContext(nodeId: number | null): FocusedNodeContext[] {
  if (!nodeId || !fs.existsSync(RAH_DB_PATH)) return [];
  const db = new Database(RAH_DB_PATH, { readonly: true, fileMustExist: true });
  const row = db.prepare(`
    SELECT id, title, description, link, chunk_status, chunk, metadata
    FROM nodes
    WHERE id = ?
    LIMIT 1
  `).get(nodeId) as FocusedNodeContext | undefined;
  return row ? [row] : [];
}

async function drainResponse(response: Response) {
  if (!response.body) return;
  const reader = response.body.getReader();
  const decoder = new TextDecoder();
  while (true) {
    const { value, done } = await reader.read();
    if (done) break;
    decoder.decode(value, { stream: true });
  }
}

function openEvalDb() {
  if (!fs.existsSync(LOG_DB_PATH)) {
    return null;
  }
  return new Database(LOG_DB_PATH, { readonly: true, fileMustExist: true });
}

function getEvalChatRow(db: Database.Database, traceId: string, scenarioId: string) {
  return db.prepare(`
    SELECT trace_id, scenario_id, assistant_message, latency_ms, input_tokens, output_tokens, total_tokens, estimated_cost_usd
    FROM llm_chats
    WHERE trace_id = ? AND scenario_id = ?
    ORDER BY id DESC
    LIMIT 1
  `).get(traceId, scenarioId) as EvalChatRow | undefined;
}

function getEvalToolCalls(db: Database.Database, traceId: string, scenarioId: string) {
  return db.prepare(`
    SELECT tool_name, args_json
    FROM tool_calls
    WHERE trace_id = ? AND scenario_id = ?
  `).all(traceId, scenarioId) as EvalToolCallRow[];
}

async function waitForEvalRow(traceId: string, scenarioId: string, timeoutMs = 10000) {
  const startedAt = Date.now();
  while (Date.now() - startedAt < timeoutMs) {
    const db = openEvalDb();
    if (db) {
      const row = getEvalChatRow(db, traceId, scenarioId);
      if (row) return { row, db };
    }
    await new Promise(resolve => setTimeout(resolve, 200));
  }
  return { row: undefined, db: null };
}

async function ensureServerReady() {
  try {
    const response = await fetch(`${BASE_URL}/api/health/ping`);
    if (!response.ok) {
      throw new Error(`Health check returned HTTP ${response.status}`);
    }
  } catch (error) {
    throw new Error(
      `RA-H dev server is not reachable at ${BASE_URL}. Start it with "npm run dev:evals".` +
      ` ${error instanceof Error ? error.message : String(error)}`
    );
  }
}

async function ensureEvalsEnabled() {
  try {
    const response = await fetch(`${BASE_URL}/evals`, {
      redirect: 'manual',
    });

    if (response.status === 404) {
      throw new Error('The /evals route returned 404');
    }

    if (!response.ok && response.status !== 307 && response.status !== 308) {
      throw new Error(`The /evals route returned HTTP ${response.status}`);
    }
  } catch (error) {
    throw new Error(
      `Eval logging does not appear to be enabled on the dev server. Start the server with "npm run dev:evals" before running "npm run evals".` +
      ` ${error instanceof Error ? error.message : String(error)}`
    );
  }
}

function normalizeContains(text: string) {
  return text.toLowerCase();
}

function normalizeSkillId(value: string) {
  return value
    .trim()
    .toLowerCase()
    .replace(/[\s_]+/g, '-')
    .replace(/[^a-z0-9-]/g, '')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '');
}

function safeJsonParse(value: string | null): Record<string, unknown> | null {
  if (!value) return null;
  try {
    const parsed = JSON.parse(value);
    if (parsed && typeof parsed === 'object') {
      return parsed as Record<string, unknown>;
    }
    return null;
  } catch {
    return null;
  }
}

function getSkillsRead(toolCalls: EvalToolCallRow[]) {
  const names = new Set<string>();
  for (const call of toolCalls) {
    if (call.tool_name !== 'readSkill' && call.tool_name !== 'rah_read_skill') {
      continue;
    }
    const parsed = safeJsonParse(call.args_json);
    const rawName = parsed?.name;
    if (typeof rawName === 'string' && rawName.trim().length > 0) {
      names.add(normalizeSkillId(rawName));
    }
  }
  return names;
}

function checkScenario(
  scenario: Scenario,
  chatRow: EvalChatRow,
  toolCalls: EvalToolCallRow[]
): EvalResult {
  const failures: string[] = [];
  const warnings: string[] = [];
  const expect = scenario.expect || {};
  const toolNames = toolCalls.map(call => call.tool_name);
  const responseText = chatRow.assistant_message || '';
  const skillsRead = getSkillsRead(toolCalls);
  const requiredSkills = new Set((expect.skillsRead || []).map(normalizeSkillId));
  const requiredSkillsSoft = new Set((expect.skillsReadSoft || []).map(normalizeSkillId));
  const forbiddenSkills = new Set((expect.skillsNotRead || []).map(normalizeSkillId));
  const forbiddenSkillsSoft = new Set((expect.skillsNotReadSoft || []).map(normalizeSkillId));
  const triggerStats = { tp: 0, fp: 0, fn: 0 };

  (expect.toolsCalled || []).forEach(tool => {
    if (!toolNames.includes(tool)) {
      failures.push(`Expected tool "${tool}" not called`);
    }
  });

  (expect.toolsCalledSoft || []).forEach(tool => {
    if (!toolNames.includes(tool)) {
      warnings.push(`(soft) Expected tool "${tool}" not called`);
    }
  });

  (expect.toolsNotCalled || []).forEach(tool => {
    if (toolNames.includes(tool)) {
      failures.push(`Tool "${tool}" should not be called`);
    }
  });

  (expect.toolsNotCalledSoft || []).forEach(tool => {
    if (toolNames.includes(tool)) {
      warnings.push(`(soft) Tool "${tool}" should not be called`);
    }
  });

  requiredSkills.forEach(skill => {
    if (!skillsRead.has(skill)) {
      failures.push(`Expected skill "${skill}" not read`);
      triggerStats.fn += 1;
    } else {
      triggerStats.tp += 1;
    }
  });

  requiredSkillsSoft.forEach(skill => {
    if (!skillsRead.has(skill)) {
      warnings.push(`(soft) Expected skill "${skill}" not read`);
    }
  });

  forbiddenSkills.forEach(skill => {
    if (skillsRead.has(skill)) {
      failures.push(`Skill "${skill}" should not be read`);
      triggerStats.fp += 1;
    }
  });

  forbiddenSkillsSoft.forEach(skill => {
    if (skillsRead.has(skill)) {
      warnings.push(`(soft) Skill "${skill}" should not be read`);
    }
  });

  if (requiredSkills.size > 0) {
    skillsRead.forEach(skill => {
      if (!requiredSkills.has(skill)) {
        triggerStats.fp += 1;
      }
    });
  }

  (expect.responseContains || []).forEach(text => {
    if (!normalizeContains(responseText).includes(normalizeContains(text))) {
      failures.push(`Response missing "${text}"`);
    }
  });

  (expect.responseContainsSoft || []).forEach(text => {
    if (!normalizeContains(responseText).includes(normalizeContains(text))) {
      warnings.push(`(soft) Response missing "${text}"`);
    }
  });

  (expect.responseNotContains || []).forEach(text => {
    if (normalizeContains(responseText).includes(normalizeContains(text))) {
      failures.push(`Response should not contain "${text}"`);
    }
  });

  if (typeof expect.maxLatencyMs === 'number' && chatRow.latency_ms !== null) {
    if (chatRow.latency_ms > expect.maxLatencyMs) {
      failures.push(`Latency ${chatRow.latency_ms}ms exceeded ${expect.maxLatencyMs}ms`);
    }
  }

  if (typeof expect.maxTotalTokens === 'number' && chatRow.total_tokens !== null) {
    if (chatRow.total_tokens > expect.maxTotalTokens) {
      failures.push(`Total tokens ${chatRow.total_tokens} exceeded ${expect.maxTotalTokens}`);
    }
  }

  if (typeof expect.maxEstimatedCostUsd === 'number' && chatRow.estimated_cost_usd !== null) {
    if (chatRow.estimated_cost_usd > expect.maxEstimatedCostUsd) {
      failures.push(`Estimated cost ${chatRow.estimated_cost_usd} exceeded ${expect.maxEstimatedCostUsd}`);
    }
  }

  return {
    scenario: scenario.name,
    passed: failures.length === 0,
    failures,
    warnings,
    latencyMs: chatRow.latency_ms,
    totalTokens: chatRow.total_tokens,
    estimatedCostUsd: chatRow.estimated_cost_usd,
    triggerStats: triggerStats.tp || triggerStats.fp || triggerStats.fn ? triggerStats : undefined,
  };
}

async function runScenario(scenario: Scenario, datasetId: string): Promise<EvalResult> {
  const traceId = `eval_${Date.now()}_${randomUUID().slice(0, 8)}`;
  const resolvedFocusedNodeId =
    scenario.input.focusedNodeId ?? resolveFocusedNodeId(scenario.input.focusedNodeQuery);
  const openTabs = loadFocusedNodeContext(resolvedFocusedNodeId ?? null);
  const response = await fetch(`${BASE_URL}/api/rah/chat`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      messages: [{ role: 'user', content: scenario.input.message }],
      openTabs,
      activeTabId: resolvedFocusedNodeId ?? null,
      currentView: 'nodes',
      traceId,
      evals: {
        datasetId,
        scenarioId: scenario.id,
      },
    }),
  });

  if (!response.ok) {
    return {
      scenario: scenario.name,
      passed: false,
      failures: [`HTTP ${response.status} from /api/rah/chat`],
      warnings: [],
    };
  }

  await drainResponse(response);

  const { row, db } = await waitForEvalRow(traceId, scenario.id, WAIT_TIMEOUT_MS);
  if (!row) {
    return {
      scenario: scenario.name,
      passed: false,
      failures: ['Timed out waiting for eval logs'],
      warnings: [],
    };
  }

  const toolCalls = db ? getEvalToolCalls(db, traceId, scenario.id) : [];
  return checkScenario(scenario, row, toolCalls);
}

async function runAll() {
  const category: EvalCategoryFilter = ['database', 'tools', 'skills', 'search', 'ingestion'].includes(CATEGORY_ENV)
    ? (CATEGORY_ENV as EvalCategoryFilter)
    : 'all';
  const datasetId = loadDatasetId();
  await ensureServerReady();
  await ensureEvalsEnabled();
  const runnable = scenarios.filter(s => s.enabled !== false && shouldRunScenario(s, category));
  console.log(`Running ${runnable.length} scenarios (dataset: ${datasetId}, category: ${category})...\n`);

  const results: EvalResult[] = [];
  for (const scenario of runnable) {
    const result = await runScenario(scenario, datasetId);
    results.push(result);
    const icon = result.passed ? '✓' : '✗';
    const parts: string[] = [];
    if (typeof result.latencyMs === 'number') parts.push(`${result.latencyMs}ms`);
    if (typeof result.totalTokens === 'number') parts.push(`${result.totalTokens} tok`);
    if (typeof result.estimatedCostUsd === 'number') parts.push(`$${result.estimatedCostUsd.toFixed(4)}`);
    const details = parts.length > 0 ? ` (${parts.join(', ')})` : '';
    console.log(`${icon} ${result.scenario}${details}`);
    result.failures.forEach(failure => console.log(`  - ${failure}`));
    result.warnings.forEach(warning => console.log(`  - ${warning}`));
  }

  const failed = results.filter(result => !result.passed);
  const warnings = results.filter(result => result.warnings.length > 0);
  const triggerTotals = results.reduce(
    (acc, result) => {
      if (result.triggerStats) {
        acc.tp += result.triggerStats.tp;
        acc.fp += result.triggerStats.fp;
        acc.fn += result.triggerStats.fn;
      }
      return acc;
    },
    { tp: 0, fp: 0, fn: 0 }
  );
  const triggerPrecision = triggerTotals.tp + triggerTotals.fp > 0
    ? triggerTotals.tp / (triggerTotals.tp + triggerTotals.fp)
    : null;
  const triggerRecall = triggerTotals.tp + triggerTotals.fn > 0
    ? triggerTotals.tp / (triggerTotals.tp + triggerTotals.fn)
    : null;
  console.log('\nSummary');
  console.log(`- Passed: ${results.length - failed.length}`);
  console.log(`- Failed: ${failed.length}`);
  console.log(`- With warnings: ${warnings.length}`);
  if (triggerPrecision !== null || triggerRecall !== null) {
    console.log(`- Trigger TP/FP/FN: ${triggerTotals.tp}/${triggerTotals.fp}/${triggerTotals.fn}`);
    console.log(`- Trigger precision: ${triggerPrecision === null ? 'n/a' : triggerPrecision.toFixed(3)}`);
    console.log(`- Trigger recall: ${triggerRecall === null ? 'n/a' : triggerRecall.toFixed(3)}`);
  }

  if (failed.length > 0) {
    process.exit(1);
  }
}

runAll().catch(error => {
  console.error('Eval runner failed:', error);
  process.exit(1);
});
