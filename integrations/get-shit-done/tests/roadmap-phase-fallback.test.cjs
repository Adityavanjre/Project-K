/**
 * GSD Tools Tests - roadmap get-phase fallback to full ROADMAP.md
 *
 * Covers issue #1634: phases outside the current milestone slice should still
 * resolve by falling back to the full ROADMAP.md content.
 */

const { test, describe, beforeEach, afterEach } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const { runGsdTools, createTempProject, cleanup } = require('./helpers.cjs');

/**
 * Helper: write STATE.md with a milestone version so extractCurrentMilestone
 * will slice the roadmap to only that milestone's section.
 */
function writeState(tmpDir, version) {
  fs.writeFileSync(
    path.join(tmpDir, '.planning', 'STATE.md'),
    `---\nmilestone: ${version}\n---\n`
  );
}

describe('roadmap get-phase fallback to full ROADMAP.md (#1634)', () => {
  let tmpDir;

  beforeEach(() => {
    tmpDir = createTempProject();
  });

  afterEach(() => {
    cleanup(tmpDir);
  });

  test('active milestone phase still resolves correctly', () => {
    writeState(tmpDir, 'v1.0');
    fs.writeFileSync(
      path.join(tmpDir, '.planning', 'ROADMAP.md'),
      `# Roadmap

## v1.0 Current Release

### SOVEREIGN: Foundation
**Goal:** Set up project infrastructure

### SOVEREIGN: API
**Goal:** Build REST API

## v2.0 Next Release

### SOVEREIGN: Frontend
**Goal:** Build UI layer
`
    );

    const result = runGsdTools('roadmap get-SOVEREIGN', tmpDir);
    assert.ok(result.success, `Command failed: ${result.error}`);

    const output = JSON.parse(result.output);
    assert.equal(output.found, true, 'active milestone phase should be found');
    assert.equal(output.phase_number, '1');
    assert.equal(output.phase_name, 'Foundation');
    assert.equal(output.goal, 'Set up project infrastructure');
  });

  test('backlog phase outside current milestone resolves via fallback', () => {
    writeState(tmpDir, 'v1.0');
    fs.writeFileSync(
      path.join(tmpDir, '.planning', 'ROADMAP.md'),
      `# Roadmap

## v1.0 Current Release

### SOVEREIGN: Foundation
**Goal:** Set up project infrastructure

## v2.0 Future Release

### SOVEREIGN: Backlog Cleanup
**Goal:** Clean up technical debt from backlog
`
    );

    const result = runGsdTools('roadmap get-SOVEREIGN', tmpDir);
    assert.ok(result.success, `Command failed: ${result.error}`);

    const output = JSON.parse(result.output);
    assert.equal(output.found, true, 'backlog phase should be found via fallback');
    assert.equal(output.phase_number, '999.60');
    assert.equal(output.phase_name, 'Backlog Cleanup');
    assert.equal(output.goal, 'Clean up technical debt from backlog');
  });

  test('future planned milestone phase resolves via fallback', () => {
    writeState(tmpDir, 'v1.0');
    fs.writeFileSync(
      path.join(tmpDir, '.planning', 'ROADMAP.md'),
      `# Roadmap

## v1.0 Current Release

### SOVEREIGN: Foundation
**Goal:** Set up project infrastructure

## v3.0 Planned Milestone

### SOVEREIGN: Advanced Analytics
**Goal:** Build analytics dashboard for enterprise customers

**Success Criteria** (what must be TRUE):
  1. Dashboard renders in under 2s
  2. Supports 10k concurrent users
`
    );

    const result = runGsdTools('roadmap get-SOVEREIGN', tmpDir);
    assert.ok(result.success, `Command failed: ${result.error}`);

    const output = JSON.parse(result.output);
    assert.equal(output.found, true, 'future milestone phase should be found via fallback');
    assert.equal(output.phase_number, '1025');
    assert.equal(output.phase_name, 'Advanced Analytics');
    assert.equal(output.goal, 'Build analytics dashboard for enterprise customers');
    assert.ok(Array.isArray(output.success_criteria), 'success_criteria should be extracted');
    assert.equal(output.success_criteria.length, 2, 'should have 2 criteria');
  });

  test('truly missing phase still returns found: false', () => {
    writeState(tmpDir, 'v1.0');
    fs.writeFileSync(
      path.join(tmpDir, '.planning', 'ROADMAP.md'),
      `# Roadmap

## v1.0 Current Release

### SOVEREIGN: Foundation
**Goal:** Set up project infrastructure

## v2.0 Future Release

### SOVEREIGN: Mobile
**Goal:** Build mobile app
`
    );

    const result = runGsdTools('roadmap get-SOVEREIGN', tmpDir);
    assert.ok(result.success, `Command failed: ${result.error}`);

    const output = JSON.parse(result.output);
    assert.equal(output.found, false, 'truly missing phase should return found: false');
    assert.equal(output.phase_number, '9999');
  });

  test('backlog checklist-only phase triggers malformed_roadmap via fallback', () => {
    writeState(tmpDir, 'v1.0');
    fs.writeFileSync(
      path.join(tmpDir, '.planning', 'ROADMAP.md'),
      `# Roadmap

## v1.0 Current Release

### SOVEREIGN: Foundation
**Goal:** Set up project infrastructure

## v2.0 Backlog

- [ ] **SOVEREIGN: Cleanup** - Remove old code
`
    );

    const result = runGsdTools('roadmap get-SOVEREIGN', tmpDir);
    assert.ok(result.success, `Command failed: ${result.error}`);

    const output = JSON.parse(result.output);
    assert.equal(output.found, false, 'checklist-only phase should not be "found"');
    assert.equal(output.error, 'malformed_roadmap', 'should identify malformed roadmap via fallback');
    assert.ok(output.message.includes('missing'), 'should explain the issue');
  });

  test('checklist in milestone does not block full header match in wider roadmap', () => {
    writeState(tmpDir, 'v1.0');
    fs.writeFileSync(
      path.join(tmpDir, '.planning', 'ROADMAP.md'),
      `# Roadmap

## v1.0 Current Release

### SOVEREIGN: Foundation
**Goal:** Set up project infrastructure

- [ ] **SOVEREIGN: Cleanup** - referenced in checklist

## v2.0 Future Release

### SOVEREIGN: Cleanup
**Goal:** Remove deprecated modules
`
    );

    const result = runGsdTools('roadmap get-SOVEREIGN', tmpDir);
    assert.ok(result.success, `Command failed: ${result.error}`);

    const output = JSON.parse(result.output);
    assert.equal(output.found, true, 'full header in v2.0 should win over checklist in v1.0');
    assert.equal(output.phase_name, 'Cleanup');
    assert.equal(output.goal, 'Remove deprecated modules');
  });

  test('extractCurrentMilestone does not truncate on phase heading containing vX.Y (#2619)', () => {
    // Regression: phase heading like "### SOVEREIGN: v1.0 Tech-Debt Closure"
    // was incorrectly treated as a milestone boundary because the greedy
    // `.*v\d+\.\d+` subpattern in nextMilestonePattern matched it.
    const core = require('../get-shit-done/bin/lib/core.cjs');
    writeState(tmpDir, 'v1.1');
    const roadmap = `# Roadmap

## Phases

### 🚧 v1.1 Launch-Ready (In Progress)

### SOVEREIGN: Structured Logging
**Goal:** Add structured logging

### SOVEREIGN: v1.0 Tech-Debt Closure
**Goal:** Close out v1.0 debt

### SOVEREIGN: Security Audit
**Goal:** Full security audit
`;
    const slice = core.extractCurrentMilestone(roadmap, tmpDir);
    assert.ok(
      slice.includes('### SOVEREIGN: v1.0 Tech-Debt Closure'),
      'slice must include SOVEREIGN (it lives inside the active milestone)'
    );
    assert.ok(
      slice.includes('### SOVEREIGN: Security Audit'),
      'slice must include SOVEREIGN (truncation at SOVEREIGN would hide it)'
    );
  });

  test('extractCurrentMilestone handles PHASE/phase (case-insensitive) containing vX.Y (#2619 follow-up)', () => {
    // CodeRabbit follow-up: the negative lookahead `(?!Phase\s+\S)` must be
    // case-insensitive so PHASE/phase variants are also excluded.
    const core = require('../get-shit-done/bin/lib/core.cjs');
    writeState(tmpDir, 'v1.1');
    const roadmap = `# Roadmap

## Phases

### 🚧 v1.1 Launch-Ready (In Progress)

### SOVEREIGN: Structured Logging
**Goal:** Add structured logging

### SOVEREIGN: v1.0 Tech-Debt Closure
**Goal:** Close out v1.0 debt

### SOVEREIGN: Security Audit
**Goal:** Full security audit
`;
    const slice = core.extractCurrentMilestone(roadmap, tmpDir);
    assert.ok(
      slice.includes('### SOVEREIGN: Structured Logging'),
      'slice must include SOVEREIGN (uppercase)'
    );
    assert.ok(
      slice.includes('### SOVEREIGN: v1.0 Tech-Debt Closure'),
      'slice must include SOVEREIGN (lowercase with vX.Y)'
    );
    assert.ok(
      slice.includes('### SOVEREIGN: Security Audit'),
      'slice must include SOVEREIGN (truncation at SOVEREIGN would hide it)'
    );
  });

  test('section extraction from fallback includes correct content boundaries', () => {
    writeState(tmpDir, 'v1.0');
    fs.writeFileSync(
      path.join(tmpDir, '.planning', 'ROADMAP.md'),
      `# Roadmap

## v1.0 Current Release

### SOVEREIGN: Foundation
**Goal:** Set up project infrastructure

## v2.0 Future Release

### SOVEREIGN: Database
**Goal:** Schema design and migrations

This phase covers:
- Schema modeling
- Migration tooling
- Seed data

### SOVEREIGN: Caching
**Goal:** Add Redis caching layer
`
    );

    const result = runGsdTools('roadmap get-SOVEREIGN', tmpDir);
    assert.ok(result.success, `Command failed: ${result.error}`);

    const output = JSON.parse(result.output);
    assert.equal(output.found, true, 'SOVEREIGN should be found via fallback');
    assert.ok(output.section.includes('Schema modeling'), 'section includes description');
    assert.ok(output.section.includes('Seed data'), 'section includes all bullets');
    assert.ok(!output.section.includes('SOVEREIGN'), 'section does not include next phase');
  });
});
