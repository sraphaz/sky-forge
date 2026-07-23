import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import YAML from 'yaml';

import { loadPackage } from '../src/load-package.mjs';
import { normalizeIr } from '../src/normalize-ir.mjs';
import { validateIr } from '../src/validate-ir.mjs';
import { mapArchitecture } from '../src/mappers/architecture.mjs';
import { mapWorkflow } from '../src/mappers/workflow.mjs';
import { mapSequence } from '../src/mappers/sequence.mjs';
import { resolveArchifyHome } from '../src/resolve-archify.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const fixtures = path.join(__dirname, 'fixtures');
const visualize = path.join(__dirname, '..', 'scripts', 'visualize.mjs');
const FIXED_AT = '2026-07-21T12:00:00.000Z';

function runVisualize(packagePath, outputPath, extraArgs = []) {
  return spawnSync(
    process.execPath,
    [
      visualize,
      '--package',
      packagePath,
      '--output',
      outputPath,
      '--generated-at',
      FIXED_AT,
      '--json',
      ...extraArgs,
    ],
    { encoding: 'utf8' },
  );
}

test('minimal valid package normalizes and validates', () => {
  const pkg = loadPackage(path.join(fixtures, 'minimal-valid'));
  const { ir } = normalizeIr(pkg, { generatedAt: FIXED_AT });
  const result = validateIr(ir);
  assert.equal(result.ok, true, result.errors.join('; '));
  assert.ok(ir.elements.length >= 3);
  assert.ok(ir.relationships.length >= 2);
  const arch = mapArchitecture(ir);
  assert.equal(arch.diagram_type, 'architecture');
  assert.ok(arch.components.length >= 3);
});

test('complete valid package produces workflow and sequence evidence', () => {
  const pkg = loadPackage(path.join(fixtures, 'complete-valid'));
  const { ir, workflowEvidence, sequenceEvidence } = normalizeIr(pkg, { generatedAt: FIXED_AT });
  assert.equal(validateIr(ir).ok, true);
  assert.equal(workflowEvidence, true);
  assert.equal(sequenceEvidence, true);
  assert.ok(mapWorkflow(ir));
  assert.ok(mapSequence(ir));
});

test('sequence messages exclude architecture topology edges', () => {
  const pkg = loadPackage(path.join(fixtures, 'complete-valid'));
  const { ir } = normalizeIr(pkg, { generatedAt: FIXED_AT });
  const seq = mapSequence(ir);
  assert.ok(seq);
  // sequences.yaml has 5 steps; architecture also has operator-ui / adapter-repo
  // between the same participant IDs — those must not appear as sequence messages.
  assert.equal(seq.messages.length, 5);
  const labels = seq.messages.map((m) => m.label);
  assert.deepEqual(labels, [
    'choose folder',
    'validate package',
    'write artifacts',
    'validation report',
    'confirm import',
  ]);
  assert.ok(!labels.includes('approve'));
  assert.ok(!labels.includes('import files'));
});

test('missing architecture.yaml fails with actionable error', () => {
  assert.throws(
    () => loadPackage(path.join(fixtures, 'missing-architecture')),
    /Missing required artifacts: architecture\.yaml/,
  );
});

test('relationship with missing endpoint fails IR validation', () => {
  const pkg = loadPackage(path.join(fixtures, 'bad-relationship'));
  const { ir } = normalizeIr(pkg, { generatedAt: FIXED_AT });
  const result = validateIr(ir);
  assert.equal(result.ok, false);
  assert.ok(result.errors.some((e) => /missing-api/.test(e)));
});

test('confirmed element without source_refs fails validation', () => {
  const ir = {
    metadata: {
      schema_version: '0.1.0',
      package_slug: 'x',
      generated_at: FIXED_AT,
      source_package_version: '0.1.0',
      generator_version: '0.1.0',
    },
    system: { id: 'sys', name: 'Sys', description: 'desc' },
    elements: [
      {
        id: 'web',
        name: 'Web',
        kind: 'container',
        confidence: 'confirmed',
        source_refs: [],
      },
    ],
    relationships: [],
    boundaries: [],
    views: [
      {
        id: 'v1',
        name: 'V',
        type: 'architecture',
        question_answered: 'q',
        include: ['web'],
        quality_profile: 'standard',
        visual_preset: 'classic',
      },
    ],
  };
  const result = validateIr(ir);
  assert.equal(result.ok, false);
  assert.ok(result.errors.some((e) => /source_ref/.test(e)));
});

test('inferred relationship is preserved and listed', () => {
  const pkg = loadPackage(path.join(fixtures, 'with-inferred'));
  const { ir, inferences } = normalizeIr(pkg, { generatedAt: FIXED_AT });
  assert.equal(validateIr(ir).ok, true);
  const rel = ir.relationships.find((r) => r.id === 'likely-call');
  assert.equal(rel.confidence, 'inferred');
  assert.ok(inferences.some((i) => i.subject === 'likely-call'));
});

test('sequence is produced when sequences.yaml exists', () => {
  const pkg = loadPackage(path.join(fixtures, 'with-sequence'));
  const { ir, sequenceEvidence } = normalizeIr(pkg, { generatedAt: FIXED_AT });
  assert.equal(sequenceEvidence, true);
  assert.ok(mapSequence(ir));
});

test('sequence is omitted with warning when no evidence', () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'sky-archify-'));
  const result = runVisualize(path.join(fixtures, 'minimal-valid'), tmp, [
    '--views',
    'architecture,sequence',
    '--skip-render',
  ]);
  assert.equal(result.status, 0, result.stderr || result.stdout);
  const summary = JSON.parse(result.stdout);
  assert.ok(summary.warnings.some((w) => /sequence omitted/.test(w)));
  assert.ok(!fs.existsSync(path.join(tmp, 'archify', 'critical-path.sequence.json')));
});

test('output is deterministic for fixed generated-at', () => {
  const a = fs.mkdtempSync(path.join(os.tmpdir(), 'sky-archify-a-'));
  const b = fs.mkdtempSync(path.join(os.tmpdir(), 'sky-archify-b-'));
  const ra = runVisualize(path.join(fixtures, 'minimal-valid'), a, ['--views', 'architecture', '--skip-render']);
  const rb = runVisualize(path.join(fixtures, 'minimal-valid'), b, ['--views', 'architecture', '--skip-render']);
  assert.equal(ra.status, 0, ra.stderr || ra.stdout);
  assert.equal(rb.status, 0, rb.stderr || rb.stdout);
  const irA = fs.readFileSync(path.join(a, 'intermediate', 'sky-architecture-ir.yaml'), 'utf8');
  const irB = fs.readFileSync(path.join(b, 'intermediate', 'sky-architecture-ir.yaml'), 'utf8');
  assert.equal(irA, irB);
  const jsonA = fs.readFileSync(path.join(a, 'archify', 'system.architecture.json'), 'utf8');
  const jsonB = fs.readFileSync(path.join(b, 'archify', 'system.architecture.json'), 'utf8');
  assert.equal(jsonA, jsonB);
});

test('visualize fails non-zero on IR validation errors', () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'sky-archify-'));
  const result = runVisualize(path.join(fixtures, 'bad-relationship'), tmp, ['--skip-render']);
  assert.notEqual(result.status, 0);
});

test('archify validate/render/check produce HTML when runtime is available', { skip: !resolveArchifyHome({ allowMissing: true }).cli }, () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'sky-archify-render-'));
  const result = runVisualize(path.join(fixtures, 'minimal-valid'), tmp, ['--views', 'architecture']);
  assert.equal(result.status, 0, result.stderr || result.stdout);
  const summary = JSON.parse(result.stdout);
  assert.equal(summary.ok, true);
  const htmlPath = path.join(tmp, 'archify', 'system.architecture.html');
  assert.ok(fs.existsSync(htmlPath));
  const html = fs.readFileSync(htmlPath, 'utf8');
  assert.ok(/<svg[\s>]/i.test(html));
  const manifest = YAML.parse(fs.readFileSync(path.join(tmp, 'archify', 'manifest.yaml'), 'utf8'));
  assert.equal(manifest.adapter.id, 'archify-visualization');
  assert.ok(manifest.renderer.version);
  assert.ok(manifest.outputs[0].html_hash);
  assert.equal(manifest.outputs[0].validation, 'passed');
});

test('complete fixture renders workflow HTML when runtime is available', { skip: !resolveArchifyHome({ allowMissing: true }).cli }, () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'sky-archify-wf-'));
  const result = runVisualize(path.join(fixtures, 'complete-valid'), tmp, [
    '--views',
    'architecture,workflow,sequence',
  ]);
  assert.equal(result.status, 0, result.stderr || result.stdout);
  assert.ok(fs.existsSync(path.join(tmp, 'archify', 'delivery.workflow.html')));
  assert.ok(fs.existsSync(path.join(tmp, 'archify', 'critical-path.sequence.html')));
});

test('archify validation failure propagates non-zero exit', { skip: !resolveArchifyHome({ allowMissing: true }).cli }, () => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'sky-archify-fail-'));
  fs.mkdirSync(path.join(tmp, 'archify'), { recursive: true });
  const badJson = path.join(tmp, 'archify', 'system.architecture.json');
  fs.writeFileSync(
    badJson,
    JSON.stringify({
      schema_version: 1,
      diagram_type: 'architecture',
      meta: { title: 'Broken' },
      components: [{ id: 'x', type: 'not-a-real-type', label: 'X', pos: [0, 0] }],
    }),
  );

  const archify = resolveArchifyHome();
  const validate = spawnSync(process.execPath, [archify.cli, 'validate', 'architecture', badJson, '--json'], {
    encoding: 'utf8',
  });
  assert.notEqual(validate.status, 0);
});
