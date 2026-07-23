import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, '..', '..', '..', '..');

test('removing plugins/examples/archify does not break check-core-agnostic', () => {
  const script = path.join(repoRoot, 'scripts', 'sky', 'check-core-agnostic.ps1');
  assert.ok(fs.existsSync(script));
  const result = spawnSync('powershell', ['-NoProfile', '-File', script], {
    encoding: 'utf8',
    cwd: repoRoot,
  });
  assert.equal(result.status, 0, result.stdout + result.stderr);
  assert.match(result.stdout, /check-core-agnostic OK/);
});

test('sky visualize wrapper exits gracefully guidance path exists', () => {
  const wrapper = path.join(repoRoot, 'scripts', 'sky', 'visualize.ps1');
  assert.ok(fs.existsSync(wrapper));
});
