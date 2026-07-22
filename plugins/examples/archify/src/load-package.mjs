import fs from 'node:fs';
import path from 'node:path';
import YAML from 'yaml';

const REQUIRED = ['brief.yaml', 'architecture.yaml'];
const OPTIONAL = [
  'package.yaml',
  'sequences.yaml',
  'integrations.yaml',
  'ux-spec.yaml',
  'sky-merits.yaml',
  'agentic-repo-recommendation.yaml',
  'handoff-solution.yaml',
  'delivery-boundaries.yaml',
  'consulting-brief.yaml',
];

export function loadPackage(packagePath) {
  const abs = path.resolve(packagePath);
  if (!fs.existsSync(abs) || !fs.statSync(abs).isDirectory()) {
    throw new Error(`Package path not found or not a directory: ${abs}`);
  }

  const missingRequired = REQUIRED.filter((name) => !fs.existsSync(path.join(abs, name)));
  if (missingRequired.length) {
    throw new Error(
      `Missing required artifacts: ${missingRequired.join(', ')}. ` +
        'Export/validate the Sky package first, then rerun visualize.',
    );
  }

  const artifacts = {};
  const missingOptional = [];

  for (const name of REQUIRED) {
    artifacts[name] = readYaml(path.join(abs, name));
  }

  for (const name of OPTIONAL) {
    const file = path.join(abs, name);
    if (fs.existsSync(file)) {
      artifacts[name] = readYaml(file);
    } else {
      missingOptional.push(name);
    }
  }

  const packageMeta = artifacts['package.yaml'] || {};
  const publicAuthorized = Boolean(
    packageMeta.public_showcase_approved === true ||
      (Array.isArray(packageMeta.gates) &&
        packageMeta.gates.some((g) => g?.id === 'public_showcase' && g.passed_by)),
  );

  return {
    path: abs,
    artifacts,
    missingOptional,
    publicAuthorized,
    slug:
      packageMeta.package_id ||
      artifacts['brief.yaml']?.title ||
      path.basename(abs),
    packageVersion: packageMeta.contract_version || packageMeta.profile_version || '0.0.0-fixture',
  };
}

function readYaml(filePath) {
  const raw = fs.readFileSync(filePath, 'utf8');
  return YAML.parse(raw);
}
