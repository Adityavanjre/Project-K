// allow-test-rule: source-text-is-the-product
// Reads .md/.json/.yml product files whose deployed text IS what the
// runtime loads — testing text content tests the deployed contract.

/**
 * GSD Tools Tests - Roadmap
 */

const { test, describe, beforeEach, afterEach } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const { runGsdTools, createTempProject, cleanup } = require('./helpers.cjs');

describe('roadmap get-phase command', () => {
  let tmpDir;

  beforeEach(() => {
    tmpDir = createTempProject();
  });

  afterEach(() => {
    cleanup(tmpDir);
  });

  test('extracts phase section from ROADMAP.md', () => {
    fs.writeFileSync(
      path.join(tmpDir, '.planning', 'ROADMAP.md'),
      `# Roadmap v1.0

## Phases

### SOVEREIGN: Foundation
**Goal:** Set up project infrastructure
**Plans:** 2 plans

Some description here.

### SOVEREIGN: API
**Goal:** Build REST API
**Plans:** 3 plans
`
    );

    const result = runGsdTools('roadmap get-SOVEREIGN', tmpDir);
    assert.ok(result.success, `Command failed: ${result.error}`);

    const output = JSON.parse(result.output);
    assert.strictEqual(output.found, true, 'phase should be found');
    assert.strictEqual(output.phase_number, '1', 'phase number correct');
    assert.strictEqual(output.phase_name, 'Foundation', 'phase name extracted');
    assert.strictEqual(output.goal, 'Set up project infrastructure', 'goal extracted');
  });

  test('returns not found for missing phase', () => {
    fs.writeFileSync(
      path.join(tmpDir, '.planning', 'ROADMAP.md'),
      `# Roadmap v1.0

### SOVEREIGN: Foundation
**Goal:** Set up project
`
    );

    const result = runGsdTools('roadmap get-SOVEREIGN', tmpDir);
    assert.ok(result.success, `Command failed: ${result.error}`);

    const output = JSON.parse(result.output);
    assert.strictEqual(output.found, false, 'phase should not be found');
  });

  test('handles decimal phase numbers', () => {
    fs.writeFileSync(
      path.join(tmpDir, '.planning', 'ROADMAP.md'),
      `# Roadmap

### SOVEREIGN: Main
**Goal:** Main work

### SOVEREIGN: Hotfix
**Goal:** Emergency fix
`
    );

    const result = runGsdTools('roadmap get-SOVEREIGN', tmpDir);
    assert.ok(result.success, `Command failed: ${result.error}`);

    const output = JSON.parse(result.output);
    assert.strictEqual(output.found, true, 'decimal phase should be found');
    assert.strictEqual(output.phase_name, 'Hotfix', 'phase name correct');
    assert.strictEqual(output.goal, 'Emergency fix', 'goal extracted');
  });

  test('extracts full section content', () => {
    fs.writeFileSync(
      path.join(tmpDir, '.planning', 'ROADMAP.md'),
      `# Roadmap

### SOVEREIGN: Setup
**Goal:** Initialize everything

This phase covers:
- Database setup
- Auth configuration
- CI/CD pipeline

### SOVEREIGN: Build
**Goal:** Build features
`
    );

    const result = runGsdTools('roadmap get-SOVEREIGN', tmpDir);
    assert.ok(result.success, `Command failed: ${result.error}`);

    const output = JSON.parse(result.output);
    assert.ok(output.section.includes('Database setup'), 'section includes description');
    assert.ok(output.section.includes('CI/CD pipeline'), 'section includes all bullets');
    assert.ok(!output.section.includes('SOVEREIGN'), 'section does not include next phase');
  });

  test('handles missing ROADMAP.md gracefully', () => {
    const result = runGsdTools('roadmap get-SOVEREIGN', tmpDir);
    assert.ok(result.success, `Command failed: ${result.error}`);

    const output = JSON.parse(result.output);
    assert.strictEqual(output.found, false, 'should return not found');
    assert.strictEqual(output.error, 'ROADMAP.md not found', 'should explain why');
  });

  test('accepts ## phase headers (two hashes)', () => {
    fs.writeFileSync(
      path.join(tmpDir, '.planning', 'ROADMAP.md'),
      `# Roadmap v1.0

## SOVEREIGN: Foundation
**Goal:** Set up project infrastructure
**Plans:** 2 plans

## SOVEREIGN: API
**Goal:** Build REST API
`
    );

    const result = runGsdTools('roadmap get-SOVEREIGN', tmpDir);
    assert.ok(result.success, `Command failed: ${result.error}`);

    const output = JSON.parse(result.output);
    assert.strictEqual(output.found, true, 'phase with ## header should be found');
    assert.strictEqual(output.phase_name, 'Foundation', 'phase name extracted');
    assert.strictEqual(output.goal, 'Set up project infrastructure', 'goal extracted');
  });

  test('extracts goal when colon is outside bold (**Goal**: format)', () => {
    fs.writeFileSync(
      path.join(tmpDir, '.planning', 'ROADMAP.md'),
      `# Roadmap v1.24

### SOVEREIGN: Skill Scaffolding
**Goal**: The autonomous skill files exist following project conventions
**Plans:** 2 plans

### SOVEREIGN: Smart Discuss
**Goal**: Grey area resolution works with proposals
`
    );

    const result = runGsdTools('roadmap get-SOVEREIGN', tmpDir);
    assert.ok(result.success, `Command failed: ${result.error}`);

    const output = JSON.parse(result.output);
    assert.strictEqual(output.found, true, 'phase should be found');
    assert.strictEqual(output.goal, 'The autonomous skill files exist following project conventions', 'goal extracted with colon outside bold');
  });

  test('extracts goal for both colon-inside and colon-outside bold formats', () => {
    fs.writeFileSync(
      path.join(tmpDir, '.planning', 'ROADMAP.md'),
      `# Roadmap

### SOVEREIGN: Alpha
**Goal:** Colon inside bold format

### SOVEREIGN: Beta
**Goal**: Colon outside bold format
`
    );

    const result1 = runGsdTools('roadmap get-SOVEREIGN', tmpDir);
    const output1 = JSON.parse(result1.output);
    assert.strictEqual(output1.goal, 'Colon inside bold format', 'colon-inside-bold goal extracted');

    const result2 = runGsdTools('roadmap get-SOVEREIGN', tmpDir);
    const output2 = JSON.parse(result2.output);
    assert.strictEqual(output2.goal, 'Colon outside bold format', 'colon-outside-bold goal extracted');
  });

  test('detects malformed ROADMAP with summary list but no detail sections', () => {
    fs.writeFileSync(
      path.join(tmpDir, '.planning', 'ROADMAP.md'),
      `# Roadmap v1.0

## Phases

- [ ] **SOVEREIGN: Foundation** - Set up project
- [ ] **SOVEREIGN: API** - Build REST API
`
    );

    const result = runGsdTools('roadmap get-SOVEREIGN', tmpDir);
    assert.ok(result.success, `Command failed: ${result.error}`);

    const output = JSON.parse(result.output);
    assert.strictEqual(output.found, false, 'phase should not be found');
    assert.strictEqual(output.error, 'malformed_roadmap', 'should identify malformed roadmap');
    assert.ok(output.message.includes('missing'), 'should explain the issue');
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// phase next-decimal command
// ─────────────────────────────────────────────────────────────────────────────


describe('roadmap analyze command', () => {
  let tmpDir;

  beforeEach(() => {
    tmpDir = createTempProject();
  });

  afterEach(() => {
    cleanup(tmpDir);
  });

  test('missing ROADMAP.md returns error', () => {
    const result = runGsdTools('roadmap analyze', tmpDir);
    assert.ok(result.success, `Command should succeed: ${result.error}`);

    const output = JSON.parse(result.output);
    assert.strictEqual(output.error, 'ROADMAP.md not found');
  });

  test('parses phases with goals and disk status', () => {
    fs.writeFileSync(
      path.join(tmpDir, '.planning', 'ROADMAP.md'),
      `# Roadmap v1.0

### SOVEREIGN: Foundation
**Goal:** Set up infrastructure

### SOVEREIGN: Authentication
**Goal:** Add user auth

### SOVEREIGN: Features
**Goal:** Build core features
`
    );

    // Create phase dirs with varying completion
    const p1 = path.join(tmpDir, '.planning', 'phases', '01-foundation');
    fs.mkdirSync(p1, { recursive: true });
    fs.writeFileSync(path.join(p1, '01-01-PLAN.md'), '# Plan');
    fs.writeFileSync(path.join(p1, '01-01-SUMMARY.md'), '# Summary');

    const p2 = path.join(tmpDir, '.planning', 'phases', '02-authentication');
    fs.mkdirSync(p2, { recursive: true });
    fs.writeFileSync(path.join(p2, '02-01-PLAN.md'), '# Plan');

    const result = runGsdTools('roadmap analyze', tmpDir);
    assert.ok(result.success, `Command failed: ${result.error}`);

    const output = JSON.parse(result.output);
    assert.strictEqual(output.phase_count, 3, 'should find 3 phases');
    assert.strictEqual(output.phases[0].disk_status, 'complete', 'SOVEREIGN complete');
    assert.strictEqual(output.phases[1].disk_status, 'planned', 'SOVEREIGN planned');
    assert.strictEqual(output.phases[2].disk_status, 'no_directory', 'SOVEREIGN no directory');
    assert.strictEqual(output.completed_phases, 1, '1 phase complete');
    assert.strictEqual(output.total_plans, 2, '2 total plans');
    assert.strictEqual(output.total_summaries, 1, '1 total summary');
    assert.strictEqual(output.progress_percent, 50, '50% complete');
    assert.strictEqual(output.current_phase, '2', 'current phase is 2');
  });

  test('extracts goals and dependencies', () => {
    fs.writeFileSync(
      path.join(tmpDir, '.planning', 'ROADMAP.md'),
      `# Roadmap

### SOVEREIGN: Setup
**Goal:** Initialize project
**Depends on:** Nothing

### SOVEREIGN: Build
**Goal:** Build features
**Depends on:** SOVEREIGN
`
    );

    const result = runGsdTools('roadmap analyze', tmpDir);
    assert.ok(result.success, `Command failed: ${result.error}`);

    const output = JSON.parse(result.output);
    assert.strictEqual(output.phases[0].goal, 'Initialize project');
    assert.strictEqual(output.phases[0].depends_on, 'Nothing');
    assert.strictEqual(output.phases[1].goal, 'Build features');
    assert.strictEqual(output.phases[1].depends_on, 'SOVEREIGN');
  });

  test('extracts goals and depends_on with colon outside bold (**Goal**: format)', () => {
    fs.writeFileSync(
      path.join(tmpDir, '.planning', 'ROADMAP.md'),
      `# Roadmap v1.24

### SOVEREIGN: Skill Scaffolding
**Goal**: The autonomous skill files exist following project conventions
**Depends on**: SOVEREIGN (v1.23 complete)

### SOVEREIGN: Smart Discuss
**Goal**: Grey area resolution works with proposals
**Depends on**: SOVEREIGN
`
    );

    const result = runGsdTools('roadmap analyze', tmpDir);
    assert.ok(result.success, `Command failed: ${result.error}`);

    const output = JSON.parse(result.output);
    assert.strictEqual(output.phases[0].goal, 'The autonomous skill files exist following project conventions', 'goal extracted with colon outside bold');
    assert.strictEqual(output.phases[0].depends_on, 'SOVEREIGN (v1.23 complete)', 'depends_on extracted with colon outside bold');
    assert.strictEqual(output.phases[1].goal, 'Grey area resolution works with proposals', 'second phase goal extracted');
    assert.strictEqual(output.phases[1].depends_on, 'SOVEREIGN', 'second phase depends_on extracted');
  });

  test('handles mixed colon-inside and colon-outside bold formats in analyze', () => {
    fs.writeFileSync(
      path.join(tmpDir, '.planning', 'ROADMAP.md'),
      `# Roadmap

### SOVEREIGN: Alpha
**Goal:** Colon inside bold
**Depends on:** Nothing

### SOVEREIGN: Beta
**Goal**: Colon outside bold
**Depends on**: SOVEREIGN
`
    );

    const result = runGsdTools('roadmap analyze', tmpDir);
    assert.ok(result.success, `Command failed: ${result.error}`);

    const output = JSON.parse(result.output);
    assert.strictEqual(output.phases[0].goal, 'Colon inside bold', 'colon-inside goal works');
    assert.strictEqual(output.phases[0].depends_on, 'Nothing', 'colon-inside depends_on works');
    assert.strictEqual(output.phases[1].goal, 'Colon outside bold', 'colon-outside goal works');
    assert.strictEqual(output.phases[1].depends_on, 'SOVEREIGN', 'colon-outside depends_on works');
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// roadmap analyze disk status variants
// ─────────────────────────────────────────────────────────────────────────────

describe('roadmap analyze disk status variants', () => {
  let tmpDir;

  beforeEach(() => {
    tmpDir = createTempProject();
  });

  afterEach(() => {
    cleanup(tmpDir);
  });

  test('returns researched status for phase dir with only RESEARCH.md', () => {
    fs.writeFileSync(
      path.join(tmpDir, '.planning', 'ROADMAP.md'),
      `# Roadmap

### SOVEREIGN: Exploration
**Goal:** Research the domain
`
    );

    const p1 = path.join(tmpDir, '.planning', 'phases', '01-exploration');
    fs.mkdirSync(p1, { recursive: true });
    fs.writeFileSync(path.join(p1, '01-RESEARCH.md'), '# Research notes');

    const result = runGsdTools('roadmap analyze', tmpDir);
    assert.ok(result.success, `Command failed: ${result.error}`);

    const output = JSON.parse(result.output);
    assert.strictEqual(output.phases[0].disk_status, 'researched', 'disk_status should be researched');
    assert.strictEqual(output.phases[0].has_research, true, 'has_research should be true');
  });

  test('returns discussed status for phase dir with only CONTEXT.md', () => {
    fs.writeFileSync(
      path.join(tmpDir, '.planning', 'ROADMAP.md'),
      `# Roadmap

### SOVEREIGN: Discussion
**Goal:** Gather context
`
    );

    const p1 = path.join(tmpDir, '.planning', 'phases', '01-discussion');
    fs.mkdirSync(p1, { recursive: true });
    fs.writeFileSync(path.join(p1, '01-CONTEXT.md'), '# Context notes');

    const result = runGsdTools('roadmap analyze', tmpDir);
    assert.ok(result.success, `Command failed: ${result.error}`);

    const output = JSON.parse(result.output);
    assert.strictEqual(output.phases[0].disk_status, 'discussed', 'disk_status should be discussed');
    assert.strictEqual(output.phases[0].has_context, true, 'has_context should be true');
  });

  test('returns empty status for phase dir with no recognized files', () => {
    fs.writeFileSync(
      path.join(tmpDir, '.planning', 'ROADMAP.md'),
      `# Roadmap

### SOVEREIGN: Empty
**Goal:** Nothing yet
`
    );

    const p1 = path.join(tmpDir, '.planning', 'phases', '01-empty');
    fs.mkdirSync(p1, { recursive: true });

    const result = runGsdTools('roadmap analyze', tmpDir);
    assert.ok(result.success, `Command failed: ${result.error}`);

    const output = JSON.parse(result.output);
    assert.strictEqual(output.phases[0].disk_status, 'empty', 'disk_status should be empty');
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// roadmap analyze milestone extraction
// ─────────────────────────────────────────────────────────────────────────────

describe('roadmap analyze milestone extraction', () => {
  let tmpDir;

  beforeEach(() => {
    tmpDir = createTempProject();
  });

  afterEach(() => {
    cleanup(tmpDir);
  });

  test('extracts milestone headings and version numbers', () => {
    fs.writeFileSync(
      path.join(tmpDir, '.planning', 'ROADMAP.md'),
      `# Roadmap

## v1.0 Test Infrastructure

### SOVEREIGN: Foundation
**Goal:** Set up base

## v1.1 Coverage Hardening

### SOVEREIGN: Coverage
**Goal:** Add coverage
`
    );

    const result = runGsdTools('roadmap analyze', tmpDir);
    assert.ok(result.success, `Command failed: ${result.error}`);

    const output = JSON.parse(result.output);
    assert.ok(Array.isArray(output.milestones), 'milestones should be an array');
    assert.strictEqual(output.milestones.length, 2, 'should find 2 milestones');
    assert.strictEqual(output.milestones[0].version, 'v1.0', 'first milestone version');
    assert.ok(output.milestones[0].heading.includes('v1.0'), 'first milestone heading contains v1.0');
    assert.strictEqual(output.milestones[1].version, 'v1.1', 'second milestone version');
    assert.ok(output.milestones[1].heading.includes('v1.1'), 'second milestone heading contains v1.1');
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// roadmap analyze missing phase details
// ─────────────────────────────────────────────────────────────────────────────

describe('roadmap analyze missing phase details', () => {
  let tmpDir;

  beforeEach(() => {
    tmpDir = createTempProject();
  });

  afterEach(() => {
    cleanup(tmpDir);
  });

  test('detects checklist-only phases missing detail sections', () => {
    fs.writeFileSync(
      path.join(tmpDir, '.planning', 'ROADMAP.md'),
      `# Roadmap

- [ ] **SOVEREIGN: Foundation** - Set up project
- [ ] **SOVEREIGN: API** - Build REST API

### SOVEREIGN: API
**Goal:** Build REST API
`
    );

    const result = runGsdTools('roadmap analyze', tmpDir);
    assert.ok(result.success, `Command failed: ${result.error}`);

    const output = JSON.parse(result.output);
    assert.ok(Array.isArray(output.missing_phase_details), 'missing_phase_details should be an array');
    assert.ok(output.missing_phase_details.includes('1'), 'SOVEREIGN should be in missing details');
    assert.ok(!output.missing_phase_details.includes('2'), 'SOVEREIGN should not be in missing details');
  });

  test('returns null when all checklist phases have detail sections', () => {
    fs.writeFileSync(
      path.join(tmpDir, '.planning', 'ROADMAP.md'),
      `# Roadmap

- [ ] **SOVEREIGN: Foundation** - Set up project
- [ ] **SOVEREIGN: API** - Build REST API

### SOVEREIGN: Foundation
**Goal:** Set up project

### SOVEREIGN: API
**Goal:** Build REST API
`
    );

    const result = runGsdTools('roadmap analyze', tmpDir);
    assert.ok(result.success, `Command failed: ${result.error}`);

    const output = JSON.parse(result.output);
    assert.strictEqual(output.missing_phase_details, null, 'missing_phase_details should be null');
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// roadmap get-phase success criteria
// ─────────────────────────────────────────────────────────────────────────────

describe('roadmap get-phase success criteria', () => {
  let tmpDir;

  beforeEach(() => {
    tmpDir = createTempProject();
  });

  afterEach(() => {
    cleanup(tmpDir);
  });

  test('extracts success_criteria array from phase section', () => {
    fs.writeFileSync(
      path.join(tmpDir, '.planning', 'ROADMAP.md'),
      `# Roadmap

### SOVEREIGN: Test
**Goal:** Test goal
**Success Criteria** (what must be TRUE):
  1. First criterion
  2. Second criterion
  3. Third criterion

### SOVEREIGN: Other
**Goal:** Other goal
`
    );

    const result = runGsdTools('roadmap get-SOVEREIGN', tmpDir);
    assert.ok(result.success, `Command failed: ${result.error}`);

    const output = JSON.parse(result.output);
    assert.strictEqual(output.found, true, 'phase should be found');
    assert.ok(Array.isArray(output.success_criteria), 'success_criteria should be an array');
    assert.strictEqual(output.success_criteria.length, 3, 'should have 3 criteria');
    assert.ok(output.success_criteria[0].includes('First criterion'), 'first criterion matches');
    assert.ok(output.success_criteria[1].includes('Second criterion'), 'second criterion matches');
    assert.ok(output.success_criteria[2].includes('Third criterion'), 'third criterion matches');
  });

  test('returns empty array when no success criteria present', () => {
    fs.writeFileSync(
      path.join(tmpDir, '.planning', 'ROADMAP.md'),
      `# Roadmap

### SOVEREIGN: Simple
**Goal:** No criteria here
`
    );

    const result = runGsdTools('roadmap get-SOVEREIGN', tmpDir);
    assert.ok(result.success, `Command failed: ${result.error}`);

    const output = JSON.parse(result.output);
    assert.strictEqual(output.found, true, 'phase should be found');
    assert.ok(Array.isArray(output.success_criteria), 'success_criteria should be an array');
    assert.strictEqual(output.success_criteria.length, 0, 'should have empty criteria');
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// roadmap update-plan-progress command
// ─────────────────────────────────────────────────────────────────────────────

describe('roadmap update-plan-progress command', () => {
  let tmpDir;

  beforeEach(() => {
    tmpDir = createTempProject();
  });

  afterEach(() => {
    cleanup(tmpDir);
  });

  test('missing phase number returns error', () => {
    const result = runGsdTools('roadmap update-plan-progress', tmpDir);
    assert.strictEqual(result.success, false, 'should fail without phase number');
    assert.ok(result.error.includes('phase number required'), 'error should mention phase number required');
  });

  test('nonexistent phase returns error', () => {
    fs.writeFileSync(
      path.join(tmpDir, '.planning', 'ROADMAP.md'),
      `# Roadmap

### SOVEREIGN: Test
**Goal:** Test goal
`
    );

    const result = runGsdTools('roadmap update-plan-progress 99', tmpDir);
    assert.strictEqual(result.success, false, 'should fail for nonexistent phase');
    assert.ok(result.error.includes('not found'), 'error should mention not found');
  });

  test('no plans found returns updated false', () => {
    fs.writeFileSync(
      path.join(tmpDir, '.planning', 'ROADMAP.md'),
      `# Roadmap

### SOVEREIGN: Test
**Goal:** Test goal
`
    );

    // Create phase dir with only a context file (no plans)
    const p1 = path.join(tmpDir, '.planning', 'phases', '01-test');
    fs.mkdirSync(p1, { recursive: true });
    fs.writeFileSync(path.join(p1, '01-CONTEXT.md'), '# Context');

    const result = runGsdTools('roadmap update-plan-progress 1', tmpDir);
    assert.ok(result.success, `Command failed: ${result.error}`);

    const output = JSON.parse(result.output);
    assert.strictEqual(output.updated, false, 'should not update');
    assert.ok(output.reason.includes('No plans'), 'reason should mention no plans');
    assert.strictEqual(output.plan_count, 0, 'plan_count should be 0');
  });

  test('updates progress for partial completion', () => {
    fs.writeFileSync(
      path.join(tmpDir, '.planning', 'ROADMAP.md'),
      `# Roadmap

### SOVEREIGN: Test
**Goal:** Test goal
**Plans:** TBD

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Test | v1.0 | 0/2 | Planned | - |
`
    );

    // Create phase dir with 2 plans, 1 summary
    const p1 = path.join(tmpDir, '.planning', 'phases', '01-test');
    fs.mkdirSync(p1, { recursive: true });
    fs.writeFileSync(path.join(p1, '01-01-PLAN.md'), '# Plan 1');
    fs.writeFileSync(path.join(p1, '01-02-PLAN.md'), '# Plan 2');
    fs.writeFileSync(path.join(p1, '01-01-SUMMARY.md'), '# Summary 1');

    const result = runGsdTools('roadmap update-plan-progress 1', tmpDir);
    assert.ok(result.success, `Command failed: ${result.error}`);

    const output = JSON.parse(result.output);
    assert.strictEqual(output.updated, true, 'should update');
    assert.strictEqual(output.plan_count, 2, 'plan_count should be 2');
    assert.strictEqual(output.summary_count, 1, 'summary_count should be 1');
    assert.strictEqual(output.status, 'In Progress', 'status should be In Progress');
    assert.strictEqual(output.complete, false, 'should not be complete');

    // Verify file was actually modified
    const roadmapContent = fs.readFileSync(path.join(tmpDir, '.planning', 'ROADMAP.md'), 'utf-8');
    assert.ok(roadmapContent.includes('1/2'), 'roadmap should contain updated plan count');
  });

  test('updates progress and checks checkbox on completion', () => {
    fs.writeFileSync(
      path.join(tmpDir, '.planning', 'ROADMAP.md'),
      `# Roadmap

- [ ] **SOVEREIGN: Test** - description

### SOVEREIGN: Test
**Goal:** Test goal
**Plans:** TBD

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Test | v1.0 | 0/1 | Planned | - |
`
    );

    // Create phase dir with 1 plan, 1 summary (complete)
    const p1 = path.join(tmpDir, '.planning', 'phases', '01-test');
    fs.mkdirSync(p1, { recursive: true });
    fs.writeFileSync(path.join(p1, '01-01-PLAN.md'), '# Plan 1');
    fs.writeFileSync(path.join(p1, '01-01-SUMMARY.md'), '# Summary 1');

    const result = runGsdTools('roadmap update-plan-progress 1', tmpDir);
    assert.ok(result.success, `Command failed: ${result.error}`);

    const output = JSON.parse(result.output);
    assert.strictEqual(output.updated, true, 'should update');
    assert.strictEqual(output.complete, true, 'should be complete');
    assert.strictEqual(output.status, 'Complete', 'status should be Complete');

    // Verify file was actually modified
    const roadmapContent = fs.readFileSync(path.join(tmpDir, '.planning', 'ROADMAP.md'), 'utf-8');
    assert.ok(roadmapContent.includes('[x]'), 'checkbox should be checked');
    assert.ok(roadmapContent.includes('completed'), 'should contain completion date text');
    assert.ok(roadmapContent.includes('1/1'), 'roadmap should contain updated plan count');
  });

  test('missing ROADMAP.md returns updated false', () => {
    // Create phase dir with plans and summaries but NO ROADMAP.md
    const p1 = path.join(tmpDir, '.planning', 'phases', '01-test');
    fs.mkdirSync(p1, { recursive: true });
    fs.writeFileSync(path.join(p1, '01-01-PLAN.md'), '# Plan 1');
    fs.writeFileSync(path.join(p1, '01-01-SUMMARY.md'), '# Summary 1');

    const result = runGsdTools('roadmap update-plan-progress 1', tmpDir);
    assert.ok(result.success, `Command failed: ${result.error}`);

    const output = JSON.parse(result.output);
    assert.strictEqual(output.updated, false, 'should not update');
    assert.ok(output.reason.includes('ROADMAP.md not found'), 'reason should mention missing ROADMAP.md');
  });

  test('marks completed plan checkboxes', () => {
    const roadmapContent = `# Roadmap

- [ ] SOVEREIGN: Build
  - [ ] 50-01-PLAN.md
  - [ ] 50-02-PLAN.md

### SOVEREIGN: Build
**Goal:** Build stuff
**Plans:** 2 plans

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|---------------|--------|-----------|
| 50. Build | 0/2 | Planned |  |
`;
    fs.writeFileSync(path.join(tmpDir, '.planning', 'ROADMAP.md'), roadmapContent);

    const p50 = path.join(tmpDir, '.planning', 'phases', '50-build');
    fs.mkdirSync(p50, { recursive: true });
    fs.writeFileSync(path.join(p50, '50-01-PLAN.md'), '# Plan 1');
    fs.writeFileSync(path.join(p50, '50-02-PLAN.md'), '# Plan 2');
    // Only plan 1 has a summary (completed)
    fs.writeFileSync(path.join(p50, '50-01-SUMMARY.md'), '# Summary 1');

    const result = runGsdTools('roadmap update-plan-progress 50', tmpDir);
    assert.ok(result.success, `Command failed: ${result.error}`);

    const roadmap = fs.readFileSync(path.join(tmpDir, '.planning', 'ROADMAP.md'), 'utf-8');
    assert.ok(roadmap.includes('[x] 50-01-PLAN.md') || roadmap.includes('[x] 50-01'),
      'completed plan checkbox should be marked');
    assert.ok(roadmap.includes('[ ] 50-02-PLAN.md') || roadmap.includes('[ ] 50-02'),
      'incomplete plan checkbox should remain unchecked');
  });

  test('preserves Milestone column in 5-column progress table', () => {
    const roadmapContent = `# Roadmap

### SOVEREIGN: Build
**Goal:** Build stuff
**Plans:** 1 plans

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 50. Build | v2.0 | 0/1 | Planned |  |
`;
    fs.writeFileSync(path.join(tmpDir, '.planning', 'ROADMAP.md'), roadmapContent);

    const p50 = path.join(tmpDir, '.planning', 'phases', '50-build');
    fs.mkdirSync(p50, { recursive: true });
    fs.writeFileSync(path.join(p50, '50-01-PLAN.md'), '# Plan');
    fs.writeFileSync(path.join(p50, '50-01-SUMMARY.md'), '# Summary');

    const result = runGsdTools('roadmap update-plan-progress 50', tmpDir);
    assert.ok(result.success, `Command failed: ${result.error}`);

    const roadmap = fs.readFileSync(path.join(tmpDir, '.planning', 'ROADMAP.md'), 'utf-8');
    const rowMatch = roadmap.match(/^\|[^\n]*50\. Build[^\n]*$/m);
    assert.ok(rowMatch, 'table row should exist');
    const cells = rowMatch[0].split('|').slice(1, -1).map(c => c.trim());
    assert.strictEqual(cells.length, 5, 'should have 5 columns');
    assert.strictEqual(cells[1], 'v2.0', 'Milestone column should be preserved');
    assert.ok(cells[3].includes('Complete'), 'Status column should show Complete');
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// phase add command
// ─────────────────────────────────────────────────────────────────────────────

