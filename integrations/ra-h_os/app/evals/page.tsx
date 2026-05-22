import { notFound } from 'next/navigation';
import { loadEvalTraces } from '@/services/evals/evalsStore';
import EvalsClient from './EvalsClient';
import { scenarios } from '../../tests/evals/scenarios';

export const dynamic = 'force-dynamic';

export default function EvalsPage() {
  const evalsEnabled = process.env.RAH_EVALS_LOG === '1' || process.env.RAH_EVALS_LOG === 'true';
  if (process.env.NODE_ENV === 'production' || !evalsEnabled) {
    notFound();
  }

  const traces = loadEvalTraces(25);
  const scenarioList = scenarios.map((scenario) => ({
    id: scenario.id,
    name: scenario.name,
    description: scenario.description,
    tools: scenario.tools,
    enabled: scenario.enabled,
    notes: scenario.notes,
  }));

  return (
    <div style={{ height: '100vh', overflowY: 'auto', background: '#f5f5f5', color: '#111' }}>
      <div style={{ padding: 24, maxWidth: 1200, margin: '0 auto', fontFamily: 'ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, \"Liberation Mono\", \"Courier New\", monospace' }}>
        <div style={{ position: 'sticky', top: 0, background: '#f5f5f5', paddingBottom: 12, marginBottom: 12, zIndex: 1 }}>
          <h1 style={{ fontSize: 24, marginBottom: 6 }}>Eval Traces</h1>
          <div style={{ color: '#444' }}>Trace table on top, full span detail below.</div>
        </div>
        {traces.length === 0 ? (
          <p>No eval traces found. Run evals with RAH_EVALS_LOG=1.</p>
        ) : (
          <EvalsClient traces={traces} scenarioList={scenarioList} />
        )}
      </div>
    </div>
  );
}
