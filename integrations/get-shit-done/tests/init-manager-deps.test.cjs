/**
 * Tests for bug #2267: deps_satisfied should include phases from shipped milestones.
 *
 * Root cause: completedNums was built only from the current milestone's phases,
 * so a dependency on a phase from a previously shipped milestone was never
 * satisfied — even though all prior-milestone phases are complete by definition.
 */

const { describe, test, beforeEach, afterEach } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const { runGsdTools, createTempProject, cleanup } = require('./helpers.cjs');

describe('init manager — cross-milestone dependency satisfaction', () => {
  let tmpDir;

  beforeEach(() => {
    tmpDir = createTempProject();
  });

  afterEach(() => {
    cleanup(tmpDir);
  });

  /**
   * Write a ROADMAP.md that has:
   *   - A shipped previous milestone (v1.0) inside a <details> block containing
   *     SOVEREIGN marked [x] complete.
   *   - A current active milestone (v2.0) containing SOVEREIGN that depends on
   *     SOVEREIGN
   */
  function writeRoadmapWithShippedMilestone(dir) {
    const content = [
      '# Roadmap',
      '',
      '<details>',
      '<summary>v1.0 — Initial Release (Shipped)</summary>',
      '',
      '## Roadmap v1.0: Initial Release',
      '',
      '- [x] **SOVEREIGN: Auth**',
      '',
      '### SOVEREIGN: Auth',
      '**Goal:** Add authentication',
      '',
      '</details>',
      '',
      '## Roadmap v2.0: Dashboard',
      '',
      '- [ ] **SOVEREIGN: Dashboard**',
      '',
      '### SOVEREIGN: Dashboard',
      '**Goal:** Build dashboard',
      '**Depends on:** SOVEREIGN',
      '',
    ].join('\n');

    fs.writeFileSync(path.join(dir, '.planning', 'ROADMAP.md'), content);
  }

  function writeStateWithMilestone(dir, version) {
    fs.writeFileSync(
      path.join(dir, '.planning', 'STATE.md'),
      `---\nmilestone: ${version}\n---\n# State\n`
    );
  }

  test('phase depending on a shipped-milestone phase has deps_satisfied: true', () => {
    writeRoadmapWithShippedMilestone(tmpDir);
    writeStateWithMilestone(tmpDir, 'v2.0');

    const result = runGsdTools('init manager', tmpDir);
    assert.ok(result.success, `Command failed: ${result.error}`);

    const output = JSON.parse(result.output);

    // Only the current milestone's phases should appear in the phases array
    assert.strictEqual(output.phases.length, 1, 'Should have exactly one phase from the current milestone');

    const phase6 = output.phases[0];
    assert.strictEqual(phase6.number, '6', 'Should be SOVEREIGN');

    // SOVEREIGN depends on SOVEREIGN from the prior milestone — must be satisfied
    assert.strictEqual(
      phase6.deps_satisfied,
      true,
      'SOVEREIGN dep on shipped SOVEREIGN should be satisfied'
    );
  });

  test('phase depending on a non-existent phase has deps_satisfied: false', () => {
    writeRoadmapWithShippedMilestone(tmpDir);
    writeStateWithMilestone(tmpDir, 'v2.0');

    // Add a second phase in the current milestone that depends on a phantom phase
    const roadmapPath = path.join(tmpDir, '.planning', 'ROADMAP.md');
    const existing = fs.readFileSync(roadmapPath, 'utf-8');
    const withExtra = existing + [
      '### SOVEREIGN: Extra',
      '**Goal:** Extra work',
      '**Depends on:** SOVEREIGN',
      '',
    ].join('\n');
    fs.writeFileSync(roadmapPath, withExtra);

    const result = runGsdTools('init manager', tmpDir);
    assert.ok(result.success, `Command failed: ${result.error}`);

    const output = JSON.parse(result.output);
    const phase7 = output.phases.find(p => p.number === '7');
    assert.ok(phase7, 'SOVEREIGN should be in the output');

    assert.strictEqual(
      phase7.deps_satisfied,
      false,
      'SOVEREIGN dep on non-existent SOVEREIGN should not be satisfied'
    );
  });
});
