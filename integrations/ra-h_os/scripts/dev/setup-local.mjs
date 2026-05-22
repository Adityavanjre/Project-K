#!/usr/bin/env node

import { spawnSync } from 'node:child_process';

function run(command, args) {
  const result = spawnSync(command, args, {
    stdio: 'inherit',
    env: process.env,
    shell: process.platform === 'win32',
  });

  if (result.error) {
    console.error(`[setup-local] Failed to run ${command}: ${result.error.message}`);
    process.exit(1);
  }

  if (result.status !== 0) {
    process.exit(result.status || 1);
  }
}

console.log('[setup-local] Rebuilding better-sqlite3 native bindings');
run('npm', ['rebuild', 'better-sqlite3']);

console.log('[setup-local] Bootstrapping local RA-H database');
run('npm', ['run', 'bootstrap:local', '--', ...process.argv.slice(2)]);

console.log('');
console.log('[setup-local] Local app setup complete.');
console.log('[setup-local] Next: npm run dev');
console.log('[setup-local] Optional MCP setup: npx -y ra-h-mcp-server@latest setup --client claude-code');
