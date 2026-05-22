'use client';

import { useMemo, useState } from 'react';
import type { EvalTrace } from '@/services/evals/evalsStore';

type Props = {
  traces: EvalTrace[];
  scenarioList: Array<{
    id: string;
    name: string;
    description?: string;
    categories?: string[];
    tools?: string[];
    enabled?: boolean;
    notes?: string;
  }>;
  ingestionGoldenDataset?: {
    id: string;
    name: string;
    status: string;
    created_at: string;
    purpose: string;
    notes: string[];
    shared_assertions: Record<string, unknown>;
    cases: Array<{
      id: string;
      surface: string;
      kind: string;
      fixture: string;
      input_description: string;
      priority: string;
      link_expected: boolean;
      auto_edge_expected: string;
      known_risk?: string;
      subcases?: string[];
    }>;
  };
};

type TraceView = {
  trace: EvalTrace;
  id: string;
  source: 'live' | 'scenario';
  sourceLabel: string;
  scenario: string;
  categories: string[];
  model: string;
  latency: number | null;
  totalTokens: number | null;
  cost: number | null;
  cacheHit: boolean | null;
  cacheTokensLabel: string;
  toolCount: number;
  toolsUsed: string[];
  status: 'success' | 'fail' | 'n/a';
  userPreview: string;
  timestamp: string;
  mode: string;
  workflow: string;
  activityType: 'adding' | 'interacting' | 'memory' | 'scenario' | 'other';
  domain: 'ingestion' | 'interaction' | 'other';
  domainLabel: string;
  activityLabel: string;
  activityReason: string;
  issues: string[];
  needsReview: boolean;
  evidenceSummary: string;
};

function formatPreview(text: string | null, max = 110) {
  if (!text) return '';
  const compact = text.replace(/\s+/g, ' ').trim();
  return compact.length > max ? `${compact.slice(0, max)}...` : compact;
}

function statusLabel(success: number | null): 'success' | 'fail' | 'n/a' {
  if (success === null) return 'n/a';
  return success ? 'success' : 'fail';
}

function badgeStyle(kind: 'success' | 'fail' | 'neutral' | 'warning' | 'accent') {
  const base = {
    display: 'inline-block',
    padding: '3px 9px',
    borderRadius: 999,
    fontSize: 12,
    fontWeight: 700,
    letterSpacing: '0.01em',
  };

  if (kind === 'success') return { ...base, background: '#dff7e5', color: '#0f6a2d' };
  if (kind === 'fail') return { ...base, background: '#fee2e2', color: '#b42318' };
  if (kind === 'warning') return { ...base, background: '#fff4d6', color: '#8a5a00' };
  if (kind === 'accent') return { ...base, background: '#dbeafe', color: '#1d4ed8' };
  return { ...base, background: '#eef2f7', color: '#4b5563' };
}

function panelStyle() {
  return {
    border: '1px solid #d7dde5',
    borderRadius: 18,
    background: 'linear-gradient(180deg, #ffffff 0%, #f9fbfd 100%)',
    boxShadow: '0 10px 30px rgba(15, 23, 42, 0.06)',
  } as const;
}

function prettyJson(value: string | null) {
  if (!value) return '';
  try {
    return JSON.stringify(JSON.parse(value), null, 2);
  } catch {
    return value;
  }
}

function parseJsonArray(value: string | null): string[] {
  if (!value) return [];
  try {
    const parsed = JSON.parse(value);
    return Array.isArray(parsed) ? parsed.filter((item): item is string => typeof item === 'string') : [];
  } catch {
    return [];
  }
}

function parseObject(value: string | null): Record<string, unknown> | null {
  if (!value) return null;
  try {
    const parsed = JSON.parse(value);
    return parsed && typeof parsed === 'object' ? parsed as Record<string, unknown> : null;
  } catch {
    return null;
  }
}

function formatMoney(value: number | null) {
  if (value == null) return 'n/a';
  return `$${value.toFixed(4)}`;
}

function formatLatency(value: number | null) {
  if (value == null) return 'n/a';
  if (value < 1000) return `${value} ms`;
  return `${(value / 1000).toFixed(1)} s`;
}

function average(values: Array<number | null>) {
  const usable = values.filter((value): value is number => typeof value === 'number');
  if (usable.length === 0) return null;
  return usable.reduce((sum, value) => sum + value, 0) / usable.length;
}

function classifyActivity(trace: EvalTrace, categories: string[], toolsUsed: string[]) {
  const toolSet = new Set(toolsUsed);
  const userText = (trace.chat.user_message || '').toLowerCase();

  if (
    toolSet.has('createNode') ||
    toolSet.has('createEdge') ||
    toolSet.has('updateNode') ||
    toolSet.has('websiteExtract') ||
    toolSet.has('youtubeExtract') ||
    toolSet.has('paperExtract') ||
    categories.includes('ingestion')
  ) {
    return {
      type: 'adding' as const,
      domain: 'ingestion' as const,
      domainLabel: 'Ingestion',
      label: 'Adding Stuff',
      reason: 'Creates or ingests graph content',
    };
  }

  if (
    userText.includes('remember') ||
    userText.includes('main project') ||
    userText.includes('preferred name') ||
    categories.includes('tools') && trace.chat.scenario_id?.startsWith('context-capsule-')
  ) {
    return {
      type: 'memory' as const,
      domain: 'interaction' as const,
      domainLabel: 'Interaction',
      label: 'Memory & Profile',
      reason: 'Cross-session identity, preferences, or memory retrieval',
    };
  }

  if (
    toolSet.has('queryNodes') ||
    toolSet.has('searchContentEmbeddings') ||
    toolSet.has('queryEdge') ||
    toolSet.has('readSkill') ||
    toolSet.has('rah_read_skill') ||
    categories.includes('search') ||
    categories.includes('skills') ||
    categories.includes('database')
  ) {
    return {
      type: trace.chat.scenario_id ? 'scenario' as const : 'interacting' as const,
      domain: 'interaction' as const,
      domainLabel: 'Interaction',
      label: trace.chat.scenario_id ? 'Scenario Eval' : 'Interacting With Stuff',
      reason: trace.chat.scenario_id ? 'Synthetic scenario coverage' : 'Looks up, traverses, or reasons over existing graph content',
    };
  }

  if (trace.chat.scenario_id) {
    return {
      type: 'scenario' as const,
      domain: 'other' as const,
      domainLabel: 'Other',
      label: 'Scenario Eval',
      reason: 'Synthetic test scenario',
    };
  }

  return {
    type: 'other' as const,
    domain: 'other' as const,
    domainLabel: 'Other',
    label: 'General Chat',
    reason: 'Conversation is logged, but not strongly classified yet',
  };
}

function findIssues(trace: EvalTrace, toolsUsed: string[]) {
  const issues: string[] = [];
  const firstToolArgs = parseObject(trace.toolCalls[0]?.args_json ?? null);
  const firstToolResult = parseObject(trace.toolCalls[0]?.result_json ?? null);
  const firstResultData =
    firstToolResult && typeof firstToolResult.data === 'object' && firstToolResult.data
      ? firstToolResult.data as Record<string, unknown>
      : null;

  if (trace.chat.success === 0) issues.push('Trace failed');
  if ((trace.chat.latency_ms ?? 0) >= 15000) issues.push('Slow trace');
  if ((trace.chat.estimated_cost_usd ?? 0) >= 0.005) issues.push('Higher-cost trace');
  if (trace.toolCalls.some((call) => call.success === 0 || call.error)) issues.push('Tool error');
  if (trace.chat.scenario_id && trace.chat.success !== 1) issues.push('Scenario regression');
  if (
    trace.toolCalls[0]?.tool_name === 'queryNodes' &&
    Array.isArray(firstResultData?.nodes) &&
    (firstResultData.nodes as unknown[]).length === 0
  ) {
    issues.push('Zero-result first search');
  }
  if (toolsUsed.length === 0 && (trace.chat.total_tokens ?? 0) > 7000) issues.push('Large prompt with no tool use');

  return issues;
}

function summarySentence(view: TraceView) {
  if (view.activityType === 'adding') {
    return `${view.activityLabel}: this run appears to create or ingest graph content.`;
  }
  if (view.activityType === 'memory') {
    return `${view.activityLabel}: this run is mostly about durable user or agent context.`;
  }
  if (view.activityType === 'interacting') {
    return `${view.activityLabel}: this run looks up or reasons over existing graph content.`;
  }
  if (view.activityType === 'scenario') {
    return `${view.activityLabel}: this is automated coverage for a named workflow.`;
  }
  return `${view.activityLabel}: trace is visible, but the product-level action is not strongly tagged yet.`;
}

export default function EvalsClient({ traces, scenarioList, ingestionGoldenDataset }: Props) {
  const [openTraceId, setOpenTraceId] = useState<string | null>(traces[0]?.chat.trace_id || null);
  const [modeFilter, setModeFilter] = useState<'ingestion' | 'interaction'>('interaction');
  const [comments, setComments] = useState<Record<string, string>>(() => {
    const initial: Record<string, string> = {};
    traces.forEach((trace) => {
      if (trace.comment) initial[trace.chat.trace_id] = trace.comment;
    });
    return initial;
  });
  const [sourceFilter, setSourceFilter] = useState<string>('all');
  const [scenarioFilter, setScenarioFilter] = useState<string>('all');
  const [categoryFilter, setCategoryFilter] = useState<string>('all');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [reviewFilter, setReviewFilter] = useState<string>('all');
  const [searchFilter, setSearchFilter] = useState<string>('');

  const scenarioCategoryMap = useMemo(
    () => new Map(scenarioList.map((scenario) => [scenario.id, scenario.categories || []])),
    [scenarioList]
  );

  const availableCategories = useMemo(() => {
    const values = new Set<string>();
    scenarioList.forEach((scenario) => (scenario.categories || []).forEach((category) => values.add(category)));
    return Array.from(values).sort();
  }, [scenarioList]);

  const views = useMemo<TraceView[]>(() => {
    return traces.map((trace) => {
      const { chat, toolCalls } = trace;
      const source = chat.scenario_id ? 'scenario' : 'live';
      const toolsUsed = parseJsonArray(chat.tools_used_json);
      const fallbackTools = toolCalls.map((call) => call.tool_name);
      const mergedTools = Array.from(new Set([...toolsUsed, ...fallbackTools]));
      const categories = chat.scenario_id ? (scenarioCategoryMap.get(chat.scenario_id) || []) : [];
      const activity = classifyActivity(trace, categories, mergedTools);
      const issues = findIssues(trace, mergedTools);
      const status = statusLabel(chat.success);
      const needsReview = status === 'fail' || issues.length > 0 || !(comments[chat.trace_id] || trace.comment || '').trim();

      return {
        trace,
        id: chat.trace_id,
        source,
        sourceLabel: source === 'live' ? 'Live App Run' : 'Scenario Eval',
        scenario: chat.scenario_id || '—',
        categories,
        model: chat.model || 'n/a',
        latency: chat.latency_ms ?? null,
        totalTokens: chat.total_tokens ?? null,
        cost: chat.estimated_cost_usd ?? null,
        cacheHit: chat.cache_hit == null ? null : Boolean(chat.cache_hit),
        cacheTokensLabel: `${chat.cache_read_tokens ?? 0}/${chat.cache_write_tokens ?? 0}`,
        toolCount: chat.tool_calls_count ?? toolCalls.length,
        toolsUsed: mergedTools,
        status,
        userPreview: formatPreview(chat.user_message),
        timestamp: chat.ts,
        mode: chat.mode || 'n/a',
        workflow: chat.workflow_key || '—',
        activityType: activity.type,
        domain: activity.domain,
        domainLabel: activity.domainLabel,
        activityLabel: activity.label,
        activityReason: activity.reason,
        issues,
        needsReview,
        evidenceSummary: summarySentence({
          trace,
          id: chat.trace_id,
          source,
          sourceLabel: '',
          scenario: chat.scenario_id || '—',
          categories,
          model: chat.model || 'n/a',
          latency: chat.latency_ms ?? null,
          totalTokens: chat.total_tokens ?? null,
          cost: chat.estimated_cost_usd ?? null,
          cacheHit: chat.cache_hit == null ? null : Boolean(chat.cache_hit),
          cacheTokensLabel: '',
          toolCount: chat.tool_calls_count ?? toolCalls.length,
          toolsUsed: mergedTools,
          status,
          userPreview: formatPreview(chat.user_message),
          timestamp: chat.ts,
          mode: chat.mode || 'n/a',
          workflow: chat.workflow_key || '—',
          activityType: activity.type,
          domain: activity.domain,
          domainLabel: activity.domainLabel,
          activityLabel: activity.label,
          activityReason: activity.reason,
          issues,
          needsReview,
          evidenceSummary: '',
        }),
      };
    });
  }, [traces, scenarioCategoryMap, comments]);

  const domainViews = useMemo(() => {
    return views.filter((view) => view.domain === modeFilter);
  }, [views, modeFilter]);

  const filteredViews = useMemo(() => {
    return views.filter((view) => {
      if (sourceFilter !== 'all' && view.source !== sourceFilter) return false;
      if (scenarioFilter !== 'all' && view.scenario !== scenarioFilter) return false;
      if (categoryFilter !== 'all' && !view.categories.includes(categoryFilter)) return false;
      if (statusFilter !== 'all' && view.status !== statusFilter) return false;
      if (reviewFilter === 'needs-review' && !view.needsReview) return false;
      if (reviewFilter === 'reviewed' && view.needsReview) return false;
      if (searchFilter.trim()) {
        const needle = searchFilter.toLowerCase();
        if (
          !view.userPreview.toLowerCase().includes(needle) &&
          !view.toolsUsed.join(' ').toLowerCase().includes(needle) &&
          !view.activityLabel.toLowerCase().includes(needle) &&
          !view.domainLabel.toLowerCase().includes(needle)
        ) {
          return false;
        }
      }
      return true;
    });
  }, [views, sourceFilter, scenarioFilter, categoryFilter, statusFilter, reviewFilter, searchFilter]);

  const filteredScenarioList = useMemo(() => {
    if (categoryFilter === 'all') return scenarioList;
    return scenarioList.filter((scenario) => (scenario.categories || []).includes(categoryFilter));
  }, [scenarioList, categoryFilter]);

  const inferredScenarioList = useMemo(() => {
    return filteredScenarioList.filter((scenario) => {
      const categories = scenario.categories || [];
      const tools = scenario.tools || [];
      if (modeFilter === 'ingestion') {
        return categories.includes('ingestion') || tools.some((tool) => ['createNode', 'createEdge', 'updateNode', 'websiteExtract', 'youtubeExtract', 'paperExtract'].includes(tool));
      }
      return categories.some((category) => ['search', 'skills', 'tools', 'database'].includes(category)) || tools.some((tool) => ['queryNodes', 'searchContentEmbeddings', 'queryEdge', 'readSkill', 'rah_read_skill'].includes(tool));
    });
  }, [filteredScenarioList, modeFilter]);

  const goldenDatasetCards = useMemo(() => {
    if (modeFilter === 'ingestion' && ingestionGoldenDataset) {
      return ingestionGoldenDataset.cases.map((item) => ({
        id: item.id,
        name: item.id,
        title: item.id,
        description: item.input_description,
        enabled: true,
        source: item.surface,
        kind: item.kind,
        fixture: item.fixture,
        priority: item.priority,
        hasExample: false,
        exampleTrace: null as TraceView | null,
        note: item.known_risk || null,
      }));
    }

    return inferredScenarioList.map((scenario) => {
      const scenarioExample = views.find((view) => view.scenario === scenario.id);
      return {
        id: scenario.id,
        name: scenario.name,
        title: scenario.name,
        description: scenario.description || 'No description',
        enabled: scenario.enabled !== false,
        source: 'scenario',
        kind: (scenario.categories || []).join(', ') || 'interaction',
        fixture: scenario.id,
        priority: 'n/a',
        hasExample: Boolean(scenarioExample),
        exampleTrace: scenarioExample || null,
        note: scenario.notes || null,
      };
    });
  }, [modeFilter, ingestionGoldenDataset, inferredScenarioList, views]);

  const recentDomainExample = useMemo(() => {
    return domainViews[0] || null;
  }, [domainViews]);

  const recentScenarioExample = useMemo(() => {
    const match = views.find((view) => view.source === 'scenario' && view.domain === modeFilter);
    return match || null;
  }, [views, modeFilter]);

  const overview = useMemo(() => {
    const live = views.filter((view) => view.source === 'live');
    const scenarios = views.filter((view) => view.source === 'scenario');
    const needsReview = views.filter((view) => view.needsReview);
    const adding = views.filter((view) => view.activityType === 'adding');
    const interacting = views.filter((view) => view.activityType === 'interacting' || view.activityType === 'memory');
    const successfulScenarios = scenarios.filter((view) => view.status === 'success');
    return {
      total: views.length,
      liveCount: live.length,
      scenarioCount: scenarios.length,
      needsReviewCount: needsReview.length,
      addingCount: adding.length,
      interactingCount: interacting.length,
      avgLatency: average(views.map((view) => view.latency)),
      avgCost: average(views.map((view) => view.cost)),
      avgTokens: average(views.map((view) => view.totalTokens)),
      scenarioPassRate: scenarios.length > 0 ? (successfulScenarios.length / scenarios.length) * 100 : null,
    };
  }, [views]);

  const reviewQueue = useMemo(
    () => views.filter((view) => view.needsReview).slice(0, 6),
    [views]
  );

  const activityBreakdown = useMemo(() => {
    const defs: Array<{ key: TraceView['activityType']; label: string }> = [
      { key: 'adding', label: 'Adding Stuff' },
      { key: 'interacting', label: 'Interacting With Stuff' },
      { key: 'memory', label: 'Memory & Profile' },
      { key: 'scenario', label: 'Scenario Evals' },
      { key: 'other', label: 'Unclear / Untagged' },
    ];

    return defs.map((def) => ({
      ...def,
      count: views.filter((view) => view.activityType === def.key).length,
    }));
  }, [views]);

  const visibleCoverage = useMemo(() => {
    const hasAdding = views.some((view) => view.activityType === 'adding');
    return {
      good: [
        'Internal agent chat runs are visible end to end.',
        'Tool calls, results, timing, tokens, cost, and system prompts are all inspectable.',
        'Scenario runs are visible beside real app usage.',
      ],
      gaps: [
        hasAdding
          ? 'Graph writes through the internal agent are partially visible as “Adding Stuff”.'
          : 'The current sample has little visible “Adding Stuff” activity in this trace store.',
        'Quick Add, MCP ingestion, and other entry surfaces are not explicitly tagged yet.',
        'This page can infer workflows from tool calls, but it cannot yet prove the exact UI surface the user used.',
      ],
    };
  }, [views]);

  return (
    <div style={{ display: 'grid', gap: 20 }}>
      <section style={{ ...panelStyle(), padding: 18 }}>
        <div style={{ display: 'flex', gap: 12, flexWrap: 'wrap', alignItems: 'center', marginBottom: 14 }}>
          {(['interaction', 'ingestion'] as const).map((mode) => (
            <button
              key={mode}
              onClick={() => setModeFilter(mode)}
              style={{
                border: modeFilter === mode ? '1px solid #2563eb' : '1px solid #d7dde5',
                background: modeFilter === mode ? '#eff6ff' : '#fff',
                color: '#0f172a',
                borderRadius: 999,
                padding: '10px 16px',
                fontSize: 14,
                fontWeight: 800,
                cursor: 'pointer',
              }}
            >
              {mode === 'interaction' ? 'interaction' : 'ingestion'}
            </button>
          ))}
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: 12 }}>
          {[
            { label: 'Mode', value: modeFilter, meta: `${modeFilter === 'interaction' ? overview.interactingCount : overview.addingCount} visible traces` },
            { label: 'Golden Scenarios', value: String(goldenDatasetCards.length), meta: `Scenarios matching ${modeFilter}` },
            { label: 'Recent Example', value: recentDomainExample ? recentDomainExample.sourceLabel : 'none', meta: recentDomainExample ? recentDomainExample.userPreview : 'No matching trace yet' },
            { label: 'Needs Review', value: String(domainViews.filter((view) => view.needsReview).length), meta: `Within ${modeFilter}` },
          ].map((card) => (
            <div key={card.label} style={{ padding: 12, borderRadius: 14, background: '#f8fafc', border: '1px solid #e2e8f0' }}>
              <div style={{ color: '#64748b', fontSize: 12, marginBottom: 6 }}>{card.label}</div>
              <div style={{ color: '#0f172a', fontSize: 22, fontWeight: 800 }}>{card.value}</div>
              <div style={{ color: '#475569', fontSize: 12, marginTop: 4 }}>{card.meta}</div>
            </div>
          ))}
        </div>
      </section>

      <section style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20 }}>
        <div style={{ ...panelStyle(), padding: 18 }}>
          <div style={{ marginBottom: 14 }}>
            <h3 style={{ margin: 0, fontSize: 18, color: '#0f172a' }}>Golden Dataset</h3>
            <div style={{ color: '#64748b', fontSize: 13, marginTop: 4 }}>
              You and me defining the expected action, trace, and output for {modeFilter}
            </div>
          </div>
          <div style={{ display: 'grid', gap: 10 }}>
            {goldenDatasetCards.length === 0 ? (
              <div style={{ padding: 12, borderRadius: 12, background: '#fff8e8', color: '#8a5a00', fontSize: 14 }}>
                No scenario set is clearly tagged for {modeFilter} yet.
              </div>
            ) : (
              goldenDatasetCards.map((scenario) => {
                const scenarioExample = scenario.exampleTrace;
                const isOpen = scenarioExample ? openTraceId === scenarioExample.id : false;
                return (
                  <div key={scenario.id} style={{ borderRadius: 14, border: '1px solid #dbe3ec', background: '#fff' }}>
                    <button
                      onClick={() => scenarioExample && setOpenTraceId(isOpen ? null : scenarioExample.id)}
                      style={{
                        width: '100%',
                        textAlign: 'left',
                        background: 'transparent',
                        border: 0,
                        padding: 12,
                        cursor: scenarioExample ? 'pointer' : 'default',
                      }}
                    >
                      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center', marginBottom: 6 }}>
                        <span style={badgeStyle('accent')}>{scenario.id}</span>
                        <span style={badgeStyle(scenario.enabled === false ? 'warning' : 'success')}>
                          {scenario.enabled === false ? 'disabled' : 'golden'}
                        </span>
                        <span style={badgeStyle('neutral')}>{scenario.source}</span>
                        <span style={badgeStyle('neutral')}>{scenario.kind}</span>
                        {scenarioExample ? <span style={badgeStyle('neutral')}>has example</span> : null}
                      </div>
                      <div style={{ fontWeight: 800, color: '#0f172a', marginBottom: 4 }}>{scenario.title}</div>
                      <div style={{ color: '#475569', fontSize: 13 }}>{scenario.description || 'No description'}</div>
                      {scenario.note ? (
                        <div style={{ color: '#8a5a00', fontSize: 12, marginTop: 6 }}>{scenario.note}</div>
                      ) : null}
                    </button>

                    {scenarioExample && isOpen ? (
                      <div style={{ borderTop: '1px solid #e2e8f0', padding: 12, background: '#f8fafc' }}>
                        <div style={{ color: '#64748b', fontSize: 12, marginBottom: 6 }}>Most recent example</div>
                        <div style={{ fontWeight: 700, color: '#0f172a', marginBottom: 6 }}>{scenarioExample.userPreview || 'No user message logged'}</div>
                        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 8 }}>
                          <span style={badgeStyle(scenarioExample.status === 'success' ? 'success' : scenarioExample.status === 'fail' ? 'fail' : 'neutral')}>
                            {scenarioExample.status}
                          </span>
                          <span style={badgeStyle('neutral')}>{formatLatency(scenarioExample.latency)}</span>
                          <span style={badgeStyle('neutral')}>{formatMoney(scenarioExample.cost)}</span>
                        </div>
                        <div style={{ color: '#475569', fontSize: 13, marginBottom: 8 }}>{scenarioExample.evidenceSummary}</div>
                        <div style={{ color: '#64748b', fontSize: 12 }}>{new Date(scenarioExample.timestamp).toLocaleString()}</div>
                      </div>
                    ) : !scenarioExample && modeFilter === 'ingestion' ? (
                      <div style={{ borderTop: '1px solid #e2e8f0', padding: 12, background: '#f8fafc', color: '#64748b', fontSize: 13 }}>
                        No matching trace is wired to this frozen ingestion case yet. The dataset is loaded, but surface-level trace attribution still needs instrumentation.
                      </div>
                    ) : null}
                  </div>
                );
              })
            )}
          </div>
        </div>

        <div style={{ ...panelStyle(), padding: 18 }}>
          <div style={{ marginBottom: 14 }}>
            <h3 style={{ margin: 0, fontSize: 18, color: '#0f172a' }}>Most Recent Example</h3>
            <div style={{ color: '#64748b', fontSize: 13, marginTop: 4 }}>
              Latest {modeFilter} trace, expandable in place
            </div>
          </div>
          {recentDomainExample ? (
            <div style={{ borderRadius: 14, border: '1px solid #dbe3ec', background: '#fff' }}>
              <button
                onClick={() => setOpenTraceId(openTraceId === recentDomainExample.id ? null : recentDomainExample.id)}
                style={{ width: '100%', textAlign: 'left', background: 'transparent', border: 0, padding: 12, cursor: 'pointer' }}
              >
                <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center', marginBottom: 6 }}>
                  <span style={badgeStyle(recentDomainExample.source === 'live' ? 'success' : 'accent')}>{recentDomainExample.sourceLabel}</span>
                  <span style={badgeStyle(recentDomainExample.status === 'success' ? 'success' : recentDomainExample.status === 'fail' ? 'fail' : 'neutral')}>{recentDomainExample.status}</span>
                  {recentScenarioExample ? <span style={badgeStyle('neutral')}>golden example available</span> : null}
                </div>
                <div style={{ fontWeight: 800, color: '#0f172a', marginBottom: 6 }}>{recentDomainExample.userPreview || 'No user message logged'}</div>
                <div style={{ color: '#475569', fontSize: 13 }}>{recentDomainExample.activityReason}</div>
              </button>

              {openTraceId === recentDomainExample.id ? (
                <div style={{ borderTop: '1px solid #e2e8f0', padding: 12, background: '#f8fafc' }}>
                  <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 8 }}>
                    <span style={badgeStyle('neutral')}>Tokens: {recentDomainExample.totalTokens ?? 'n/a'}</span>
                    <span style={badgeStyle('neutral')}>Latency: {formatLatency(recentDomainExample.latency)}</span>
                    <span style={badgeStyle('neutral')}>Cost: {formatMoney(recentDomainExample.cost)}</span>
                  </div>
                  <div style={{ color: '#334155', fontSize: 14, marginBottom: 8 }}>{recentDomainExample.evidenceSummary}</div>
                  <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                    {recentDomainExample.toolsUsed.map((tool) => (
                      <span key={tool} style={badgeStyle('neutral')}>{tool}</span>
                    ))}
                  </div>
                </div>
              ) : null}
            </div>
          ) : (
            <div style={{ padding: 12, borderRadius: 12, background: '#fff8e8', color: '#8a5a00', fontSize: 14 }}>
              No recent {modeFilter} example found in the loaded traces.
            </div>
          )}
          <div style={{ marginTop: 14, padding: 12, borderRadius: 12, background: '#fff8e8', color: '#8a5a00', fontSize: 14 }}>
            {visibleCoverage.gaps.join(' ')}
          </div>
        </div>
      </section>

      <section style={{ ...panelStyle(), padding: 18 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', gap: 16, flexWrap: 'wrap', marginBottom: 12 }}>
          <div>
            <h3 style={{ margin: 0, fontSize: 18, color: '#0f172a' }}>Everything</h3>
            <div style={{ color: '#64748b', fontSize: 13, marginTop: 4 }}>
              Full trace list stays here as a separate section
            </div>
          </div>
          <div style={{ color: '#475569', fontSize: 13 }}>
            Showing {filteredViews.length} of {views.length} visible traces
          </div>
        </div>

        <div style={{ display: 'flex', gap: 12, alignItems: 'center', flexWrap: 'wrap', marginBottom: 16 }}>
          <label style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
            <span>Source</span>
            <select value={sourceFilter} onChange={(event) => setSourceFilter(event.target.value)} style={{ padding: '6px 8px', borderRadius: 8, border: '1px solid #d7dde5' }}>
              <option value="all">All</option>
              <option value="live">Live app runs</option>
              <option value="scenario">Scenario evals</option>
            </select>
          </label>
          <label style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
            <span>Category</span>
            <select value={categoryFilter} onChange={(event) => setCategoryFilter(event.target.value)} style={{ padding: '6px 8px', borderRadius: 8, border: '1px solid #d7dde5' }}>
              <option value="all">All</option>
              {availableCategories.map((category) => (
                <option key={category} value={category}>{category}</option>
              ))}
            </select>
          </label>
          <label style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
            <span>Status</span>
            <select value={statusFilter} onChange={(event) => setStatusFilter(event.target.value)} style={{ padding: '6px 8px', borderRadius: 8, border: '1px solid #d7dde5' }}>
              <option value="all">All</option>
              <option value="success">Success</option>
              <option value="fail">Fail</option>
              <option value="n/a">N/A</option>
            </select>
          </label>
          <label style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
            <span>Review</span>
            <select value={reviewFilter} onChange={(event) => setReviewFilter(event.target.value)} style={{ padding: '6px 8px', borderRadius: 8, border: '1px solid #d7dde5' }}>
              <option value="all">All</option>
              <option value="needs-review">Needs review</option>
              <option value="reviewed">Reviewed</option>
            </select>
          </label>
          <label style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
            <span>Scenario</span>
            <select value={scenarioFilter} onChange={(event) => setScenarioFilter(event.target.value)} style={{ padding: '6px 8px', borderRadius: 8, border: '1px solid #d7dde5', maxWidth: 220 }}>
              <option value="all">All</option>
              {Array.from(new Set(views.filter((view) => view.scenario !== '—').map((view) => view.scenario))).map((scenario) => (
                <option key={scenario} value={scenario}>{scenario}</option>
              ))}
            </select>
          </label>
          <label style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
            <span>Search</span>
            <input
              value={searchFilter}
              onChange={(event) => setSearchFilter(event.target.value)}
              placeholder="Message, tool, or activity..."
              style={{ padding: '6px 8px', borderRadius: 8, border: '1px solid #d7dde5', minWidth: 220 }}
            />
          </label>
        </div>

        <div style={{ display: 'grid', gap: 12 }}>
          {filteredViews.map((view) => {
            const isOpen = openTraceId === view.id;
            const note = comments[view.id] || view.trace.comment || '';

            return (
              <div
                key={view.id}
                onClick={() => setOpenTraceId(isOpen ? null : view.id)}
                style={{
                  padding: 16,
                  borderRadius: 16,
                  border: isOpen ? '1px solid #60a5fa' : '1px solid #dbe3ec',
                  background: isOpen ? '#f5faff' : '#fff',
                  cursor: 'pointer',
                }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12, flexWrap: 'wrap', marginBottom: 8 }}>
                  <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center' }}>
                    <span style={badgeStyle(view.source === 'live' ? 'success' : 'accent')}>{view.sourceLabel}</span>
                    <span style={badgeStyle(view.status === 'success' ? 'success' : view.status === 'fail' ? 'fail' : 'neutral')}>
                      {view.status}
                    </span>
                    <span style={badgeStyle(view.domain === 'ingestion' ? 'success' : view.domain === 'interaction' ? 'accent' : 'neutral')}>
                      {view.domainLabel}
                    </span>
                    {view.issues.map((issue) => (
                      <span key={issue} style={badgeStyle('warning')}>{issue}</span>
                    ))}
                  </div>
                  <div style={{ color: '#64748b', fontSize: 12 }}>{new Date(view.timestamp).toLocaleString()}</div>
                </div>

                <div style={{ fontSize: 18, fontWeight: 800, color: '#0f172a', marginBottom: 6 }}>
                  {view.userPreview || 'No user message logged'}
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: 16, alignItems: 'start' }}>
                  <div>
                    <div style={{ color: '#334155', fontSize: 14, marginBottom: 8 }}>{view.evidenceSummary}</div>
                    <div style={{ color: '#64748b', fontSize: 13 }}>
                      {view.activityReason}
                      {view.scenario !== '—' ? ` • Scenario: ${view.scenario}` : ''}
                    </div>
                    {view.toolsUsed.length > 0 ? (
                      <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginTop: 10 }}>
                        {view.toolsUsed.map((tool) => (
                          <span key={tool} style={badgeStyle('neutral')}>{tool}</span>
                        ))}
                      </div>
                    ) : null}
                  </div>

                  <div style={{ display: 'grid', gap: 8, justifyItems: 'start' }}>
                    <div style={{ fontSize: 13, color: '#475569' }}>Latency: <strong style={{ color: '#0f172a' }}>{formatLatency(view.latency)}</strong></div>
                    <div style={{ fontSize: 13, color: '#475569' }}>Tokens: <strong style={{ color: '#0f172a' }}>{view.totalTokens ?? 'n/a'}</strong></div>
                    <div style={{ fontSize: 13, color: '#475569' }}>Cost: <strong style={{ color: '#0f172a' }}>{formatMoney(view.cost)}</strong></div>
                    <div style={{ fontSize: 13, color: '#475569' }}>Tools: <strong style={{ color: '#0f172a' }}>{view.toolCount}</strong></div>
                    <div style={{ fontSize: 13, color: '#475569' }}>Cache: <strong style={{ color: '#0f172a' }}>{view.cacheHit == null ? 'n/a' : view.cacheHit ? 'hit' : 'miss'}</strong></div>
                  </div>
                </div>

                <div style={{ marginTop: 12, display: 'flex', justifyContent: 'space-between', gap: 12, flexWrap: 'wrap', alignItems: 'center' }}>
                  <div style={{ color: '#64748b', fontSize: 13 }}>
                    {note.trim() ? `Note: ${formatPreview(note, 100)}` : 'Open the trace to add a note or review comment.'}
                  </div>
                  <div style={{ color: '#64748b', fontSize: 12, whiteSpace: 'nowrap' }}>
                    {note.trim() ? 'Reviewed' : 'Needs note'}
                  </div>
                </div>

                {isOpen ? (
                  <div
                    onClick={(event) => event.stopPropagation()}
                    style={{ marginTop: 14, borderTop: '1px solid #e2e8f0', paddingTop: 14, display: 'grid', gap: 14 }}
                  >
                    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(160px, 1fr))', gap: 10 }}>
                      {[
                        ['Trace ID', view.trace.chat.trace_id],
                        ['Scenario', view.trace.chat.scenario_id || '—'],
                        ['Model', view.trace.chat.model || 'n/a'],
                        ['Latency', formatLatency(view.trace.chat.latency_ms ?? null)],
                        ['Tokens', view.trace.chat.total_tokens == null ? 'n/a' : String(view.trace.chat.total_tokens)],
                        ['Cost', formatMoney(view.trace.chat.estimated_cost_usd ?? null)],
                      ].map(([label, value]) => (
                        <div key={label} style={{ padding: 10, borderRadius: 12, background: '#f8fafc', border: '1px solid #e2e8f0' }}>
                          <div style={{ color: '#64748b', fontSize: 12, marginBottom: 4 }}>{label}</div>
                          <div style={{ color: '#0f172a', fontWeight: 700, fontSize: 13, wordBreak: 'break-word' }}>{value}</div>
                        </div>
                      ))}
                    </div>

                    <textarea
                      value={note}
                      onChange={(event) => {
                        const nextValue = event.target.value;
                        setComments((prev) => ({ ...prev, [view.id]: nextValue }));
                      }}
                      onBlur={async (event) => {
                        const nextValue = event.target.value;
                        try {
                          await fetch('/api/evals/comment', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({
                              traceId: view.id,
                              scenarioId: view.scenario === '—' ? null : view.scenario,
                              comment: nextValue,
                            }),
                          });
                        } catch {
                          // Keep local state only if persistence fails.
                        }
                      }}
                      rows={3}
                      placeholder="What happened here? Why does it matter? What should change?"
                      style={{
                        width: '100%',
                        resize: 'vertical',
                        fontFamily: 'inherit',
                        fontSize: 13,
                        padding: 10,
                        borderRadius: 10,
                        border: '1px solid #d7dde5',
                        background: '#fff',
                      }}
                    />

                    <details open>
                      <summary style={{ cursor: 'pointer', fontWeight: 800, color: '#0f172a', marginBottom: 10 }}>Trace Steps</summary>
                      <div style={{ display: 'grid', gap: 12 }}>
                        {[
                          {
                            type: 'chat',
                            ts: view.trace.chat.ts,
                            title: 'LLM Chat',
                            spanId: view.trace.chat.span_id,
                            parentSpanId: null,
                            latency: view.trace.chat.latency_ms,
                            success: view.trace.chat.success,
                            content: (
                              <>
                                <div style={{ fontWeight: 700, marginBottom: 6 }}>User</div>
                                <pre style={{ whiteSpace: 'pre-wrap' }}>{view.trace.chat.user_message || 'n/a'}</pre>
                                <div style={{ fontWeight: 700, margin: '12px 0 6px' }}>Assistant</div>
                                <pre style={{ whiteSpace: 'pre-wrap' }}>{view.trace.chat.assistant_message || 'n/a'}</pre>
                              </>
                            ),
                          },
                          ...view.trace.toolCalls.map((tool) => ({
                            type: 'tool',
                            ts: tool.ts,
                            title: `Tool: ${tool.tool_name}`,
                            spanId: tool.span_id,
                            parentSpanId: tool.parent_span_id,
                            latency: tool.latency_ms,
                            success: tool.success,
                            content: (
                              <>
                                <div style={{ fontWeight: 700, marginBottom: 6 }}>Args</div>
                                <pre style={{ whiteSpace: 'pre-wrap' }}>{prettyJson(tool.args_json)}</pre>
                                <div style={{ fontWeight: 700, margin: '12px 0 6px' }}>Result</div>
                                <pre style={{ whiteSpace: 'pre-wrap' }}>{prettyJson(tool.result_json)}</pre>
                              </>
                            ),
                          })),
                        ].sort((a, b) => a.ts.localeCompare(b.ts)).map((step, index) => {
                          const stepStatus = statusLabel(step.success);
                          return (
                            <div key={`${view.id}-${step.type}-${index}`} style={{ padding: 12, borderRadius: 12, border: '1px solid #e2e8f0', background: '#fff' }}>
                              <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center', marginBottom: 8 }}>
                                <div style={{ fontWeight: 800, color: '#0f172a' }}>Step {index + 1}: {step.title}</div>
                                <span style={badgeStyle(stepStatus === 'success' ? 'success' : stepStatus === 'fail' ? 'fail' : 'neutral')}>{stepStatus}</span>
                                <span style={{ color: '#64748b', fontSize: 12 }}>{step.ts}</span>
                              </div>
                              <div style={{ color: '#475569', fontSize: 13, marginBottom: 8 }}>
                                <strong>Latency:</strong> {formatLatency(step.latency ?? null)}
                              </div>
                              <div style={{ fontSize: 13 }}>{step.content}</div>
                            </div>
                          );
                        })}
                      </div>
                    </details>
                  </div>
                ) : null}
              </div>
            );
          })}
        </div>
      </section>
    </div>
  );
}
