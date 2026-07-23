#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import YAML from 'yaml';

import { loadPackage } from '../src/load-package.mjs';
import { normalizeIr, ADAPTER_VERSION } from '../src/normalize-ir.mjs';
import { validateIr } from '../src/validate-ir.mjs';
import { mapArchitecture } from '../src/mappers/architecture.mjs';
import { mapWorkflow } from '../src/mappers/workflow.mjs';
import { mapSequence } from '../src/mappers/sequence.mjs';
import { resolveArchifyHome, runArchify } from '../src/resolve-archify.mjs';
import { buildManifest, stringifyManifest } from '../src/manifest.mjs';
import { hashPackage, sha256File, sha256Hex } from '../src/hash.mjs';
import { logStep, logWarn } from '../src/log.mjs';
import { sanitizeDeep } from '../src/sanitize.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

function parseArgs(argv) {
  const args = {
    packagePath: null,
    outputPath: null,
    views: ['architecture', 'workflow', 'sequence'],
    quality: 'standard',
    generatedAt: null,
    json: false,
    skipRender: false,
  };

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    const next = argv[i + 1];
    switch (token) {
      case '--package':
      case '-p':
        args.packagePath = next;
        i += 1;
        break;
      case '--output':
      case '-o':
        args.outputPath = next;
        i += 1;
        break;
      case '--views':
        args.views = String(next)
          .split(',')
          .map((v) => v.trim())
          .filter(Boolean);
        i += 1;
        break;
      case '--quality':
        args.quality = next;
        i += 1;
        break;
      case '--generated-at':
        args.generatedAt = next;
        i += 1;
        break;
      case '--json':
        args.json = true;
        break;
      case '--skip-render':
        args.skipRender = true;
        break;
      case '--help':
      case '-h':
        args.help = true;
        break;
      default:
        if (token.startsWith('-')) {
          throw new Error(`Unknown argument: ${token}`);
        }
    }
  }
  return args;
}

function usage() {
  return `Usage:
  node plugins/examples/archify/scripts/visualize.mjs \\
    --package <exported-package> \\
    --output <destination> \\
    [--views architecture,workflow,sequence] \\
    [--quality standard|showcase] \\
    [--generated-at ISO-8601] \\
    [--json] \\
    [--skip-render]

Archify must be bootstrapped first:
  node plugins/examples/archify/scripts/bootstrap-archify.mjs
`;
}

function writeJson(filePath, data) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  fs.writeFileSync(filePath, `${JSON.stringify(data, null, 2)}\n`, 'utf8');
}

function writeText(filePath, text) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  fs.writeFileSync(filePath, text, 'utf8');
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help || !args.packagePath || !args.outputPath) {
    console.log(usage());
    process.exit(args.help ? 0 : 2);
  }

  const jsonMode = args.json;
  const outputRoot = path.resolve(args.outputPath);
  const warnings = [];
  const outputs = [];

  try {
    logStep('load package', { json: jsonMode });
    const pkg = loadPackage(args.packagePath);

    logStep('normalize IR', { json: jsonMode });
    const { ir, inferences, workflowEvidence, sequenceEvidence } = normalizeIr(pkg, {
      generatedAt: args.generatedAt,
      qualityProfile: args.quality,
    });

    logStep('validate IR', { json: jsonMode });
    const validation = validateIr(ir);
    if (!validation.ok) {
      const message = `Sky Architecture IR validation failed:\n- ${validation.errors.join('\n- ')}`;
      if (jsonMode) {
        console.log(JSON.stringify({ ok: false, stage: 'validate-ir', errors: validation.errors }, null, 2));
      } else {
        console.error(message);
      }
      process.exit(1);
    }

    const intermediateDir = path.join(outputRoot, 'intermediate');
    const archifyDir = path.join(outputRoot, 'archify');
    fs.mkdirSync(intermediateDir, { recursive: true });
    fs.mkdirSync(archifyDir, { recursive: true });

    const irPath = path.join(intermediateDir, 'sky-architecture-ir.yaml');
    writeText(irPath, YAML.stringify(ir, { lineWidth: 100 }));

    const requested = new Set(args.views);
    const diagrams = [];

    if (requested.has('architecture')) {
      logStep('map architecture', { json: jsonMode });
      const jsonDoc = sanitizeDeep(mapArchitecture(ir, { qualityProfile: args.quality }));
      const jsonPath = path.join(archifyDir, 'system.architecture.json');
      writeJson(jsonPath, jsonDoc);
      diagrams.push({ view: 'system', type: 'architecture', jsonPath, htmlName: 'system.architecture.html' });
    }

    if (requested.has('workflow')) {
      if (!workflowEvidence) {
        const msg = 'workflow omitted: no gates/milestones evidence in package';
        warnings.push(msg);
        logWarn(msg, { json: jsonMode });
      } else {
        logStep('map workflow', { json: jsonMode });
        const jsonDoc = sanitizeDeep(mapWorkflow(ir, { qualityProfile: args.quality }));
        if (!jsonDoc) {
          warnings.push('workflow omitted: mapper produced empty diagram');
        } else {
          const jsonPath = path.join(archifyDir, 'delivery.workflow.json');
          writeJson(jsonPath, jsonDoc);
          diagrams.push({ view: 'delivery', type: 'workflow', jsonPath, htmlName: 'delivery.workflow.html' });
        }
      }
    }

    if (requested.has('sequence')) {
      if (!sequenceEvidence) {
        const msg = 'sequence omitted: sequences.yaml evidence not found';
        warnings.push(msg);
        logWarn(msg, { json: jsonMode });
      } else {
        logStep('map sequence', { json: jsonMode });
        const jsonDoc = sanitizeDeep(mapSequence(ir, { qualityProfile: args.quality }));
        if (!jsonDoc) {
          warnings.push('sequence omitted: mapper produced empty diagram');
        } else {
          const jsonPath = path.join(archifyDir, 'critical-path.sequence.json');
          writeJson(jsonPath, jsonDoc);
          diagrams.push({
            view: 'critical-path',
            type: 'sequence',
            jsonPath,
            htmlPath: path.join(archifyDir, 'critical-path.sequence.html'),
            htmlName: 'critical-path.sequence.html',
          });
        }
      }
    }

    let archify = { version: 'unresolved', cli: null };
    if (!args.skipRender) {
      archify = resolveArchifyHome();
    } else {
      archify = resolveArchifyHome({ allowMissing: true });
    }

    for (const diagram of diagrams) {
      const htmlPath = path.join(archifyDir, diagram.htmlName);
      let validateStatus = 'skipped';
      let renderStatus = 'skipped';
      let checkStatus = 'skipped';

      if (!args.skipRender) {
        logStep('archify validate', { json: jsonMode });
        // Archify 2.11.0 has no --quality flag; quality is recorded in IR/manifest only.
        const validate = runArchify(archify.cli, ['validate', diagram.type, diagram.jsonPath, '--json'], {
          json: true,
        });
        if (!validate.ok) {
          if (jsonMode) {
            console.log(
              JSON.stringify(
                {
                  ok: false,
                  stage: 'archify-validate',
                  type: diagram.type,
                  stdout: validate.stdout,
                  stderr: validate.stderr,
                },
                null,
                2,
              ),
            );
          } else {
            console.error(validate.stderr || validate.stdout || 'archify validate failed');
          }
          process.exit(validate.status || 1);
        }
        validateStatus = 'passed';

        logStep('archify render', { json: jsonMode });
        const render = runArchify(archify.cli, ['render', diagram.type, diagram.jsonPath, htmlPath], {
          json: true,
        });
        if (!render.ok) {
          console.error(render.stderr || render.stdout || 'archify render failed');
          process.exit(render.status || 1);
        }
        renderStatus = 'passed';

        logStep('archify check', { json: jsonMode });
        const check = runArchify(archify.cli, ['check', htmlPath], { json: true });
        if (!check.ok) {
          console.error(check.stderr || check.stdout || 'archify check failed');
          process.exit(check.status || 1);
        }
        checkStatus = 'passed';
      }

      outputs.push({
        view: diagram.view,
        type: diagram.type,
        json: path.relative(outputRoot, diagram.jsonPath).split(path.sep).join('/'),
        html: args.skipRender ? null : path.relative(outputRoot, htmlPath).split(path.sep).join('/'),
        json_hash: `sha256:${sha256File(diagram.jsonPath)}`,
        html_hash: args.skipRender || !fs.existsSync(htmlPath) ? null : `sha256:${sha256File(htmlPath)}`,
        validation: validateStatus,
        render: renderStatus,
        check: checkStatus,
      });
    }

    logStep('write manifest', { json: jsonMode });
    const manifest = buildManifest({
      packageSlug: pkg.slug,
      packageHash: hashPackage(pkg.path),
      generatedAt: ir.metadata.generated_at,
      archifyVersion: archify.version || 'unresolved',
      viewsRequested: args.views,
      outputs,
      inferences,
      missingOptional: pkg.missingOptional,
      publicAuthorized: pkg.publicAuthorized,
      warnings,
    });
    const manifestPath = path.join(archifyDir, 'manifest.yaml');
    writeText(manifestPath, stringifyManifest(manifest));

    const summary = {
      ok: true,
      adapter_version: ADAPTER_VERSION,
      archify_version: archify.version,
      package: pkg.slug,
      output: outputRoot,
      ir: path.relative(outputRoot, irPath).split(path.sep).join('/'),
      manifest: path.relative(outputRoot, manifestPath).split(path.sep).join('/'),
      outputs,
      warnings,
      inferences: inferences.length,
      public_authorized: pkg.publicAuthorized,
      ir_hash: `sha256:${sha256Hex(fs.readFileSync(irPath))}`,
    };

    if (jsonMode) {
      console.log(JSON.stringify(summary, null, 2));
    } else {
      console.log(`Visualization complete: ${outputRoot}`);
      console.log(`IR: ${irPath}`);
      console.log(`Manifest: ${manifestPath}`);
      for (const out of outputs) {
        console.log(`- ${out.type}: ${out.json}${out.html ? ` → ${out.html}` : ''}`);
      }
      for (const warning of warnings) {
        console.log(`warning: ${warning}`);
      }
    }
  } catch (error) {
    if (jsonMode) {
      console.log(JSON.stringify({ ok: false, error: error.message }, null, 2));
    } else {
      console.error(`[sky-archify] error: ${error.message}`);
    }
    process.exit(1);
  }
}

main();
