#!/usr/bin/env node
/**
 * Explicit bootstrap for the pinned Archify runtime.
 * Never runs implicitly during visualize.
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const pluginRoot = path.resolve(__dirname, '..');
const lock = JSON.parse(fs.readFileSync(path.join(pluginRoot, 'ARCHIFY.lock.json'), 'utf8'));
const vendorRoot = path.join(pluginRoot, '.vendor', 'archify');

const force = process.argv.includes('--force');

if (fs.existsSync(path.join(vendorRoot, lock.skill_relative_path, 'bin', 'archify.mjs')) && !force) {
  console.log(`Archify already bootstrapped at ${vendorRoot}`);
  console.log(`Pin: ${lock.package}@${lock.version} (${lock.commit})`);
  process.exit(0);
}

fs.mkdirSync(path.dirname(vendorRoot), { recursive: true });
if (fs.existsSync(vendorRoot)) {
  fs.rmSync(vendorRoot, { recursive: true, force: true });
}

console.log(`Cloning ${lock.repository} @ ${lock.tag} (${lock.commit})...`);
const clone = spawnSync(
  'git',
  ['clone', '--depth', '1', '--branch', lock.tag, lock.repository, vendorRoot],
  { encoding: 'utf8', stdio: 'inherit' },
);
if ((clone.status ?? 1) !== 0) {
  console.error('Bootstrap failed: git clone error');
  process.exit(clone.status ?? 1);
}

const head = spawnSync('git', ['-C', vendorRoot, 'rev-parse', 'HEAD'], { encoding: 'utf8' });
const commit = (head.stdout || '').trim();
if (commit && commit !== lock.commit) {
  console.warn(`Warning: resolved commit ${commit} differs from lock ${lock.commit}`);
}

const cli = path.join(vendorRoot, lock.cli_relative_path);
if (!fs.existsSync(cli)) {
  console.error(`Bootstrap incomplete: missing CLI at ${cli}`);
  process.exit(1);
}

console.log('Bootstrap complete.');
console.log(`CLI: ${cli}`);
console.log(`Set ARCHIFY_HOME=${path.join(vendorRoot, lock.skill_relative_path)} (optional)`);
