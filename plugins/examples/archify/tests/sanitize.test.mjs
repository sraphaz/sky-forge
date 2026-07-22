import test from 'node:test';
import assert from 'node:assert/strict';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { loadPackage } from '../src/load-package.mjs';
import { normalizeIr } from '../src/normalize-ir.mjs';
import { mapArchitecture } from '../src/mappers/architecture.mjs';
import { sanitizeText } from '../src/sanitize.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const fixtures = path.join(__dirname, 'fixtures');

test('sanitizeText redacts tokens and connection strings', () => {
  assert.match(sanitizeText('token=super-secret-value'), /\[REDACTED\]/);
  assert.match(sanitizeText('Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.abc'), /Bearer \[REDACTED\]/);
  assert.match(sanitizeText('postgres://user:pass@host/db'), /postgres:\/\/\[REDACTED\]/);
  assert.match(sanitizeText('sql?access_token=abc123'), /\[REDACTED\]/);
});

test('normalize + map architecture never leaks raw secrets', () => {
  const pkg = loadPackage(path.join(fixtures, 'with-secrets'));
  const { ir } = normalizeIr(pkg, { generatedAt: '2026-07-21T12:00:00.000Z' });
  const serialized = JSON.stringify(ir);
  assert.doesNotMatch(serialized, /super-secret-value/);
  assert.doesNotMatch(serialized, /eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9/);
  assert.doesNotMatch(serialized, /user:pass@host/);
  assert.doesNotMatch(serialized, /access_token=abc123/);

  const arch = mapArchitecture(ir);
  const archText = JSON.stringify(arch);
  assert.doesNotMatch(archText, /super-secret-value/);
  assert.doesNotMatch(archText, /user:pass@host/);
});
