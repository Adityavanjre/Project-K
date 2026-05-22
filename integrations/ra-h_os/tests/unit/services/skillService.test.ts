import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

const SKILL_FIXTURES = {
  onboarding: `---
name: Onboarding
description: "Initial setup guidance."
---

# Onboarding
`,
  'create-skill': `---
name: Create Skill
description: "Create or rewrite a reusable skill."
---

# Create Skill
`,
  refine: `---
name: Refine
description: "Refine a node or small set of nodes."
---

# Refine
`,
};

const LEGACY_AUDIT_SKILL = `---
name: Audit
description: "Legacy audit skill."
---

# Audit
`;

const CUSTOM_SKILL = `---
name: Custom Capture
description: "A custom user skill."
---

# Custom Capture
`;

let originalCwd: string;
let tempRoot: string;
let tempHome: string;

function writeFile(filepath: string, content: string) {
  fs.mkdirSync(path.dirname(filepath), { recursive: true });
  fs.writeFileSync(filepath, content, 'utf8');
}

function createCanonicalSkillSet(rootDir: string) {
  const skillDir = path.join(rootDir, 'src/config/skills');
  for (const [name, content] of Object.entries(SKILL_FIXTURES)) {
    writeFile(path.join(skillDir, `${name}.md`), content);
  }
}

async function loadSkillService() {
  vi.resetModules();
  vi.doMock('os', () => ({
    default: { homedir: () => tempHome },
    homedir: () => tempHome,
  }));

  return import('@/services/skills/skillService');
}

beforeEach(() => {
  originalCwd = process.cwd();
  tempRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'rah-skill-root-'));
  tempHome = fs.mkdtempSync(path.join(os.tmpdir(), 'rah-skill-home-'));
  createCanonicalSkillSet(tempRoot);
  process.chdir(tempRoot);
});

afterEach(() => {
  process.chdir(originalCwd);
  vi.doUnmock('os');
  vi.resetModules();
  fs.rmSync(tempRoot, { recursive: true, force: true });
  fs.rmSync(tempHome, { recursive: true, force: true });
});

describe('skillService', () => {
  it('seeds the canonical three-skill set into the live skills folder', async () => {
    const skillService = await loadSkillService();

    const skills = skillService.listSkills();

    expect(skills.map((skill) => skill.name)).toEqual([
      'Create Skill',
      'Onboarding',
      'Refine',
    ]);

    const liveSkillDir = path.join(tempHome, 'Library/Application Support/RA-H/skills');
    expect(fs.readdirSync(liveSkillDir).sort()).toEqual([
      '.seed-migrated-2026-03-07-skills-overhaul',
      'create-skill.md',
      'onboarding.md',
      'refine.md',
    ]);
  });

  it('hard-prunes retired built-in skills while preserving non-retired custom skills', async () => {
    const liveSkillDir = path.join(tempHome, 'Library/Application Support/RA-H/skills');
    writeFile(path.join(liveSkillDir, 'audit.md'), LEGACY_AUDIT_SKILL);
    writeFile(path.join(liveSkillDir, 'custom-capture.md'), CUSTOM_SKILL);

    const skillService = await loadSkillService();

    const skills = skillService.listSkills();

    expect(skills.map((skill) => skill.name)).toEqual([
      'Create Skill',
      'Custom Capture',
      'Onboarding',
      'Refine',
    ]);
    expect(fs.existsSync(path.join(liveSkillDir, 'audit.md'))).toBe(false);
    expect(fs.existsSync(path.join(liveSkillDir, 'custom-capture.md'))).toBe(true);
  });

  it('supports normalized skill CRUD against the live skills folder', async () => {
    const skillService = await loadSkillService();

    const content = `---
name: Capture Source
description: "Preserve raw source while writing a strong description."
---

# Capture Source
`;

    expect(skillService.writeSkill('Capture Source', content)).toEqual({ success: true });

    const created = skillService.readSkill('capture-source');
    expect(created?.name).toBe('Capture Source');
    expect(created?.description).toContain('Preserve raw source');
    expect(created?.content).toContain('# Capture Source');

    expect(skillService.deleteSkill('Capture Source')).toEqual({ success: true });
    expect(skillService.readSkill('capture-source')).toBeNull();
  });
});
