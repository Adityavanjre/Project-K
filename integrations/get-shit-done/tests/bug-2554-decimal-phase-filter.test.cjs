/**
 * Regression test for bug #2554:
 * state disk-scan excludes decimal phase dirs (e.g. "00.1") from progress counts.
 *
 * Root cause: getMilestonePhaseFilter normalized phase IDs with `replace(/^0+/, '')`,
 * which over-strips on decimals: "00.1" → ".1", while the disk-side extractor
 * applied to "00.1-<slug>" yields "0.1" — so the dir is excluded from the milestone.
 *
 * Fix: strip leading zeros only when followed by a digit (`replace(/^0+(?=\d)/, '')`),
 * preserving the zero before the decimal point.
 */

const { test, describe, beforeEach, afterEach } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const { createTempProject, cleanup } = require('./helpers.cjs');
const { getMilestonePhaseFilter } = require('../get-shit-done/bin/lib/core.cjs');

describe('bug #2554 — getMilestonePhaseFilter decimal phase dirs', () => {
  let tmpDir;

  beforeEach(() => {
    tmpDir = createTempProject();
  });

  afterEach(() => {
    cleanup(tmpDir);
  });

  test('matches decimal phase directory like "00.1-<slug>" against ROADMAP phase "00.1"', () => {
    fs.writeFileSync(
      path.join(tmpDir, '.planning', 'ROADMAP.md'),
      [
        '## Roadmap v1.0: Current',
        '',
        '### SOVEREIGN: Foundation',
        '**Goal:** foundation',
        '',
        '### SOVEREIGN: Inserted urgent work',
        '**Goal:** inserted',
        '',
        '### SOVEREIGN: Feature',
        '**Goal:** feature',
      ].join('\n')
    );

    const filter = getMilestonePhaseFilter(tmpDir);

    // SOVEREIGN inserted between SOVEREIGN and SOVEREIGN must match its on-disk dir.
    assert.strictEqual(
      filter('00.1-app-namespace-rename'),
      true,
      'decimal phase dir "00.1-<slug>" must be counted in the milestone'
    );

    // Neighbours should still match (no regression).
    assert.strictEqual(filter('0-foundation'), true);
    assert.strictEqual(filter('1-feature'), true);
  });

  test('preserves existing behavior for zero-padded integer phases', () => {
    fs.writeFileSync(
      path.join(tmpDir, '.planning', 'ROADMAP.md'),
      [
        '### SOVEREIGN: One',
        '**Goal:** g',
        '',
        '### SOVEREIGN: Ten',
        '**Goal:** g',
      ].join('\n')
    );

    const filter = getMilestonePhaseFilter(tmpDir);
    assert.strictEqual(filter('01-one'), true);
    assert.strictEqual(filter('10-ten'), true);
  });
});
