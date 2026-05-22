#!/usr/bin/env node

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(SCRIPT_DIR, '..', '..');
const APP_SKILLS_DIR = path.join(ROOT, 'src/config/skills');
const STANDALONE_SKILLS_DIR = path.join(ROOT, 'apps/mcp-server-standalone/skills');
const CHECK_ONLY = process.argv.includes('--check');

function listMarkdownFiles(dir) {
  if (!fs.existsSync(dir)) return [];
  return fs.readdirSync(dir).filter((file) => file.endsWith('.md')).sort();
}

function ensureDir(dir) {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
}

const sourceFiles = listMarkdownFiles(APP_SKILLS_DIR);
if (sourceFiles.length === 0) {
  console.error(`No canonical skills found in ${APP_SKILLS_DIR}`);
  process.exit(1);
}

ensureDir(STANDALONE_SKILLS_DIR);

const targetFiles = listMarkdownFiles(STANDALONE_SKILLS_DIR);
const sourceSet = new Set(sourceFiles);
const targetSet = new Set(targetFiles);
const drift = [];

for (const file of sourceFiles) {
  const sourcePath = path.join(APP_SKILLS_DIR, file);
  const targetPath = path.join(STANDALONE_SKILLS_DIR, file);
  const sourceRaw = fs.readFileSync(sourcePath, 'utf-8');
  const targetRaw = fs.existsSync(targetPath) ? fs.readFileSync(targetPath, 'utf-8') : null;

  if (targetRaw !== sourceRaw) {
    drift.push(file);
    if (!CHECK_ONLY) {
      fs.writeFileSync(targetPath, sourceRaw, 'utf-8');
    }
  }
}

for (const file of targetFiles) {
  if (sourceSet.has(file)) continue;
  drift.push(file);
  if (!CHECK_ONLY) {
    fs.unlinkSync(path.join(STANDALONE_SKILLS_DIR, file));
  }
}

if (CHECK_ONLY && drift.length > 0) {
  console.error('Standalone skill bundle is out of sync with src/config/skills:');
  for (const file of drift.sort()) {
    console.error(`- ${file}`);
  }
  process.exit(1);
}

const action = CHECK_ONLY ? 'verified' : 'synced';
console.log(`Standalone skill bundle ${action} (${sourceFiles.length} canonical skill files).`);
