import fs from 'fs';
import path from 'path';
import os from 'os';
import matter from 'gray-matter';
import type { Skill, SkillMeta } from '@/types/skills';

export type { Skill, SkillMeta } from '@/types/skills';

const SKILLS_DIR = path.join(
  os.homedir(),
  'Library/Application Support/RA-H/skills'
);

const LEGACY_GUIDES_DIR = path.join(
  os.homedir(),
  'Library/Application Support/RA-H/guides'
);

const BUNDLED_SKILLS_DIR = path.join(
  process.cwd(),
  'src/config/skills'
);
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
  'audit',
  'calibration',
  'connect',
  'db-operations',
  'node-context-enrichment',
  'persona',
  'traverse',
]);

function ensureSkillsDir(): void {
  if (!fs.existsSync(SKILLS_DIR)) {
    fs.mkdirSync(SKILLS_DIR, { recursive: true });
  }
}

function stripMdExtension(value: string): string {
  return value.replace(/\.md$/i, '');
}

function normalizeSkillId(value: string): string {
  return stripMdExtension(value)
    .trim()
    .toLowerCase()
    .replace(/[\s_]+/g, '-')
    .replace(/[^a-z0-9-]/g, '')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '');
}

function listMarkdownFiles(dir: string): string[] {
  if (!fs.existsSync(dir)) return [];
  return fs.readdirSync(dir).filter((f) => f.endsWith('.md'));
}

function getBundledSkillFiles(): Map<string, string> {
  const bundledById = new Map<string, string>();

  for (const file of listMarkdownFiles(BUNDLED_SKILLS_DIR)) {
    bundledById.set(normalizeSkillId(file), path.join(BUNDLED_SKILLS_DIR, file));
  }

  return bundledById;
}

function migrateLegacyGuides(): void {
  const guideFiles = listMarkdownFiles(LEGACY_GUIDES_DIR);
  for (const file of guideFiles) {
    const target = path.join(SKILLS_DIR, file);
    if (!fs.existsSync(target)) {
      fs.copyFileSync(path.join(LEGACY_GUIDES_DIR, file), target);
    }
  }
}

function seedSkills(): void {
  const bundledById = getBundledSkillFiles();

  for (const [skillId, source] of bundledById.entries()) {
    const dest = path.join(SKILLS_DIR, `${skillId}.md`);
    if (!fs.existsSync(dest)) {
      fs.copyFileSync(source, dest);
    }
  }
}

function migrateSeededBaseline(): void {
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

function pruneDeprecatedSkills(): void {
  const files = listMarkdownFiles(SKILLS_DIR);
  for (const file of files) {
    const normalized = normalizeSkillId(file);
    if (DEPRECATED_SKILL_IDS.has(normalized)) {
      fs.unlinkSync(path.join(SKILLS_DIR, file));
    }
  }
}

function resolveSkillFilename(name: string): string | null {
  const files = listMarkdownFiles(SKILLS_DIR);
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
    const { data } = matter(raw);
    if (typeof data.name === 'string' && normalizeSkillId(data.name) === normalizedInput) {
      return file;
    }
  }

  return null;
}

let initialized = false;

function init(): void {
  if (initialized) return;
  ensureSkillsDir();
  migrateLegacyGuides();
  migrateSeededBaseline();
  seedSkills();
  pruneDeprecatedSkills();
  initialized = true;
}

export function listSkills(): SkillMeta[] {
  init();
  const files = listMarkdownFiles(SKILLS_DIR);

  const skills = files.map((file) => {
    const raw = fs.readFileSync(path.join(SKILLS_DIR, file), 'utf-8');
    const { data } = matter(raw);

    return {
      name: data.name || file.replace('.md', ''),
      description: data.description || '',
      immutable: false,
    };
  });

  return skills.sort((a, b) => a.name.localeCompare(b.name));
}

export function readSkill(name: string): Skill | null {
  init();

  const filename = resolveSkillFilename(name);
  if (!filename) {
    return null;
  }

  const filepath = path.join(SKILLS_DIR, filename);
  const raw = fs.readFileSync(filepath, 'utf-8');
  const { data, content } = matter(raw);

  return {
    name: data.name || stripMdExtension(filename),
    description: data.description || '',
    immutable: false,
    content: content.trim(),
  };
}

export function writeSkill(name: string, content: string): { success: boolean; error?: string } {
  init();
  const normalizedName = normalizeSkillId(name);
  const existingFilename = resolveSkillFilename(name);
  const filename = existingFilename || `${normalizedName || name.toLowerCase()}.md`;

  const filepath = path.join(SKILLS_DIR, filename);
  fs.writeFileSync(filepath, content, 'utf-8');
  return { success: true };
}

export function deleteSkill(name: string): { success: boolean; error?: string } {
  init();

  const filename = resolveSkillFilename(name);
  if (!filename) {
    return { success: false, error: `Skill "${name}" not found.` };
  }

  const filepath = path.join(SKILLS_DIR, filename);
  fs.unlinkSync(filepath);
  return { success: true };
}

export function getUserSkillCount(): number {
  init();
  return listMarkdownFiles(SKILLS_DIR).length;
}

export function getSkillStats(): { userSkills: number; maxUserSkills: number; systemSkills: number } {
  const count = getUserSkillCount();
  return {
    userSkills: count,
    maxUserSkills: 9999,
    systemSkills: 0,
  };
}
