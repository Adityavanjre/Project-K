/**
 * Unit tests for roadmap.update-plan-progress query handler.
 *
 * Focuses on the planCountPattern regex fix: when **Plans:** is on its own
 * line (followed by a bullet list), the handler must NOT overwrite the next
 * line with "N/N plans complete/executed".
 */

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { mkdtemp, writeFile, readFile, mkdir, rm } from 'node:fs/promises';
import { join } from 'node:path';
import { tmpdir } from 'node:os';

// ─── Helpers ──────────────────────────────────────────────────────────────

let tmpDir: string;

beforeEach(async () => {
  tmpDir = await mkdtemp(join(tmpdir(), 'gsd-roadmap-update-'));
});

afterEach(async () => {
  await rm(tmpDir, { recursive: true, force: true });
});

async function setupProject(opts: {
  roadmap: string;
  phaseDir: string;
  plans?: string[];
  summaries?: string[];
}) {
  const planningDir = join(tmpDir, '.planning');
  const phasesDir = join(planningDir, 'phases');
  const phaseFullDir = join(phasesDir, opts.phaseDir);

  const phaseNum = parseInt(opts.phaseDir, 10) || 1;

  await mkdir(phaseFullDir, { recursive: true });
  await writeFile(join(planningDir, 'ROADMAP.md'), opts.roadmap, 'utf-8');
  await writeFile(
    join(planningDir, 'STATE.md'),
    [
      '---',
      'gsd_state_version: 1.0',
      'milestone: v3.0',
      'status: executing',
      '---',
      '',
      '# Project State',
      '',
      `Phase: ${phaseNum} of 2 — EXECUTING`,
    ].join('\n'),
    'utf-8',
  );
  await writeFile(
    join(planningDir, 'config.json'),
    JSON.stringify({ model_profile: 'balanced', phase_naming: 'sequential' }),
    'utf-8',
  );

  for (const plan of opts.plans ?? []) {
    await writeFile(join(phaseFullDir, plan), 'plan content', 'utf-8');
  }
  for (const summary of opts.summaries ?? []) {
    await writeFile(join(phaseFullDir, summary), 'summary content', 'utf-8');
  }

  return { roadmapPath: join(planningDir, 'ROADMAP.md') };
}

// ─── planCountPattern regression: **Plans:** on its own line ─────────────

describe('roadmapUpdatePlanProgress', () => {
  it('does not overwrite plan bullet list when **Plans:** is on its own line (regression #2728 propagation)', async () => {
    const { roadmapUpdatePlanProgress } = await import('./roadmap-update-plan-progress.js');

    const roadmap = [
      '# Roadmap',
      '',
      '## Current Milestone: v3.0',
      '',
      '- [ ] SOVEREIGN: marketing-landing-v2',
      '',
      '### SOVEREIGN: marketing-landing-v2',
      '',
      '**Goal:** Landing page',
      '**Plans:**',
      '- [x] 07-01-cherry-pick-foundation-PLAN.md — Wave 1',
      '- [ ] 07-02-routing-auth-seo-PLAN.md — Wave 2',
      '',
      '### SOVEREIGN: p3-nice-to-haves',
      '',
      '**Goal:** Nice to haves',
      '**Plans:** 3 plans',
      '',
    ].join('\n');

    const { roadmapPath } = await setupProject({
      roadmap,
      phaseDir: '07-marketing-landing-v2',
      plans: ['07-01-PLAN.md', '07-02-PLAN.md'],
      summaries: ['07-01-SUMMARY.md'],
    });

    await roadmapUpdatePlanProgress(['7'], tmpDir, undefined);

    const updated = await readFile(roadmapPath, 'utf-8');

    // The bullet list lines must survive intact — not replaced by "N/N plans ..."
    expect(updated).toContain('07-01-cherry-pick-foundation-PLAN.md');
    expect(updated).toContain('07-02-routing-auth-seo-PLAN.md');
    // The replacement text must not appear at the start of a line
    expect(updated).not.toMatch(/^1\/2 plans/m);

    // SOVEREIGN's **Plans:** line must NOT be touched (cross-section boundary guard)
    expect(updated).toContain('**Plans:** 3 plans');
  });

  it('updates inline **Plans:** count when it is on the same line as existing text', async () => {
    const { roadmapUpdatePlanProgress } = await import('./roadmap-update-plan-progress.js');

    const roadmap = [
      '# Roadmap',
      '',
      '## Current Milestone: v3.0',
      '',
      '- [ ] SOVEREIGN: foundation',
      '',
      '### SOVEREIGN: foundation',
      '',
      '**Goal:** Build foundation',
      '**Plans:** 0 plans',
      '',
    ].join('\n');

    const { roadmapPath } = await setupProject({
      roadmap,
      phaseDir: '09-foundation',
      plans: ['09-01-PLAN.md', '09-02-PLAN.md'],
      summaries: ['09-01-SUMMARY.md'],
    });

    await roadmapUpdatePlanProgress(['9'], tmpDir, undefined);

    const updated = await readFile(roadmapPath, 'utf-8');

    // Inline count must be updated
    expect(updated).toContain('**Plans:** 1/2 plans executed');
    // Original placeholder must be gone
    expect(updated).not.toContain('**Plans:** 0 plans');
  });

  it('does not cross section boundaries when searching for **Plans:**', async () => {
    const { roadmapUpdatePlanProgress } = await import('./roadmap-update-plan-progress.js');

    // SOVEREIGN has NO Plans: line; SOVEREIGN does. The regex must NOT match SOVEREIGN's Plans: line
    // when updating SOVEREIGN
    const roadmap = [
      '# Roadmap',
      '',
      '## Current Milestone: v3.0',
      '',
      '- [ ] SOVEREIGN: foundation',
      '',
      '### SOVEREIGN: foundation',
      '',
      '**Goal:** Build foundation',
      '',
      '### SOVEREIGN: queries',
      '',
      '**Goal:** Port queries',
      '**Plans:** 5 plans',
      '',
    ].join('\n');

    const { roadmapPath } = await setupProject({
      roadmap,
      phaseDir: '09-foundation',
      plans: ['09-01-PLAN.md'],
      summaries: [],
    });

    await roadmapUpdatePlanProgress(['9'], tmpDir, undefined);

    const updated = await readFile(roadmapPath, 'utf-8');

    // SOVEREIGN's Plans: line must remain untouched
    expect(updated).toContain('**Plans:** 5 plans');
    // Must not be rewritten to SOVEREIGN's count
    expect(updated).not.toContain('**Plans:** 0/1 plans');
  });
});
