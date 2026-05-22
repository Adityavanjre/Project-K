'use strict';

const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');

const SKILLS_DIR = path.join(
  os.homedir(),
  'Library', 'Application Support', 'RA-H', 'skills'
);

const LEGACY_GUIDES_DIR = path.join(
  os.homedir(),
  'Library', 'Application Support', 'RA-H', 'guides'
);

const BUNDLED_SKILLS_DIR = path.join(__dirname, '..', 'skills');
const SEED_MIGRATION_FLAG = path.join(SKILLS_DIR, '.seed-migrated-2026-03-07-skills-overhaul');

const DEPRECATED_SKILL_IDS = new Set([
  'start-here',
  'schema',
  'creating-nodes',
  'edges',
  'dimensions',
  'extract',
  'troubleshooting',
  'integrate',
  'test-guide',
  'ghostwriting-brad',
  'write-the-debrief',
  'prep',
  'preferences',
  'research',
  'survey',
  'traverse-graph',
  'context-capsule',
  'audit',
  'calibration',
  'connect',
  'db-operations',
  'node-context-enrichment',
  'persona',
  'traverse',
]);

function parseFrontmatter(raw) {
  const match = raw.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n?([\s\S]*)$/);
  if (!match) return { data: {}, content: raw.trim() };

  const yamlBlock = match[1];
  const content = match[2];
  const data = {};

  for (const line of yamlBlock.split('\n')) {
    const colonIdx = line.indexOf(':');
    if (colonIdx === -1) continue;
    const key = line.slice(0, colonIdx).trim();
    let value = line.slice(colonIdx + 1).trim();

    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }

    if (value === 'true') value = true;
    else if (value === 'false') value = false;

    data[key] = value;
  }

  return { data, content: content.trim() };
}

function stripMdExtension(value) {
  return value.replace(/\.md$/i, '');
}

function normalizeSkillId(value) {
  return stripMdExtension(value)
    .trim()
    .toLowerCase()
    .replace(/[\s_]+/g, '-')
    .replace(/[^a-z0-9-]/g, '')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '');
}

function listMarkdownFiles(dir) {
  if (!fs.existsSync(dir)) return [];
  return fs.readdirSync(dir).filter((f) => f.endsWith('.md'));
}

function getBundledSkillFiles() {
  const bundledById = new Map();

  for (const file of listMarkdownFiles(BUNDLED_SKILLS_DIR)) {
    bundledById.set(normalizeSkillId(file), path.join(BUNDLED_SKILLS_DIR, file));
  }

  return bundledById;
}

function ensureSkillsDir() {
  if (!fs.existsSync(SKILLS_DIR)) {
    fs.mkdirSync(SKILLS_DIR, { recursive: true });
  }
}

function migrateLegacyGuides() {
  const files = listMarkdownFiles(LEGACY_GUIDES_DIR);
  for (const file of files) {
    const dest = path.join(SKILLS_DIR, file);
    if (!fs.existsSync(dest)) {
      fs.copyFileSync(path.join(LEGACY_GUIDES_DIR, file), dest);
    }
  }
}

function seedSkills() {
  ensureSkillsDir();

  const bundledById = getBundledSkillFiles();
  for (const [skillId, source] of bundledById.entries()) {
    const dest = path.join(SKILLS_DIR, `${skillId}.md`);
    if (!fs.existsSync(dest)) {
      fs.copyFileSync(source, dest);
    }
  }
}

function migrateSeededBaseline() {
  if (fs.existsSync(SEED_MIGRATION_FLAG)) {
    return;
  }

  const bundledById = getBundledSkillFiles();
  for (const [skillId, source] of bundledById.entries()) {
    const dest = path.join(SKILLS_DIR, `${skillId}.md`);
    fs.copyFileSync(source, dest);
  }

  fs.writeFileSync(SEED_MIGRATION_FLAG, 'ok', 'utf-8');
}

function pruneDeprecatedSkills() {
  const files = listMarkdownFiles(SKILLS_DIR);
  for (const file of files) {
    const normalized = normalizeSkillId(file);
    if (DEPRECATED_SKILL_IDS.has(normalized)) {
      fs.unlinkSync(path.join(SKILLS_DIR, file));
    }
  }
}

function resolveSkillFilename(name) {
  if (!fs.existsSync(SKILLS_DIR)) {
    return null;
  }

  const files = fs.readdirSync(SKILLS_DIR).filter((f) => f.endsWith('.md'));
  const normalizedInput = normalizeSkillId(name);
  const directCandidates = [
    `${name}.md`,
    `${name.toLowerCase()}.md`,
    normalizedInput ? `${normalizedInput}.md` : '',
  ].filter(Boolean);

  for (const candidate of directCandidates) {
    if (files.includes(candidate)) {
      return candidate;
    }
  }

  for (const file of files) {
    if (normalizeSkillId(file) === normalizedInput) {
      return file;
    }

    const raw = fs.readFileSync(path.join(SKILLS_DIR, file), 'utf-8');
    const { data } = parseFrontmatter(raw);
    if (typeof data.name === 'string' && normalizeSkillId(data.name) === normalizedInput) {
      return file;
    }
  }

  return null;
}

let initialized = false;

function init() {
  if (initialized) return;
  ensureSkillsDir();
  migrateLegacyGuides();
  migrateSeededBaseline();
  seedSkills();
  pruneDeprecatedSkills();
  initialized = true;
}

function listSkills() {
  init();
  if (!fs.existsSync(SKILLS_DIR)) return [];

  const files = fs.readdirSync(SKILLS_DIR).filter((f) => f.endsWith('.md'));
  const skills = files.map((file) => {
    const raw = fs.readFileSync(path.join(SKILLS_DIR, file), 'utf-8');
    const { data } = parseFrontmatter(raw);
    return {
      name: data.name || file.replace('.md', ''),
      description: data.description || '',
      immutable: false,
    };
  });

  return skills.sort((a, b) => a.name.localeCompare(b.name));
}

function readSkill(name) {
  init();
  const filename = resolveSkillFilename(name);
  if (!filename) {
    return null;
  }

  const filepath = path.join(SKILLS_DIR, filename);
  const raw = fs.readFileSync(filepath, 'utf-8');
  const { data, content } = parseFrontmatter(raw);
  return {
    name: data.name || stripMdExtension(filename),
    description: data.description || '',
    immutable: false,
    content,
  };
}

function writeSkill(name, content) {
  init();
  const normalizedName = normalizeSkillId(name);
  const existingFilename = resolveSkillFilename(name);
  const filename = existingFilename || `${normalizedName || name.toLowerCase()}.md`;
  const filepath = path.join(SKILLS_DIR, filename);

  ensureSkillsDir();
  fs.writeFileSync(filepath, content, 'utf-8');
  return { success: true };
}

function deleteSkill(name) {
  init();
  const filename = resolveSkillFilename(name);
  if (!filename) {
    return { success: false, error: `Skill "${name}" not found.` };
  }

  const filepath = path.join(SKILLS_DIR, filename);
  fs.unlinkSync(filepath);
  return { success: true };
}

module.exports = {
  listSkills,
  readSkill,
  writeSkill,
  deleteSkill,
};
