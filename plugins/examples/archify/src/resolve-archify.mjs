import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const pluginRoot = path.resolve(__dirname, '..');
const lockPath = path.join(pluginRoot, 'ARCHIFY.lock.json');

export function loadArchifyLock() {
  return JSON.parse(fs.readFileSync(lockPath, 'utf8'));
}

/**
 * Resolution order:
 * 1. ARCHIFY_HOME
 * 2. plugin .vendor/archify (bootstrapped)
 * 3. actionable bootstrap error
 */
export function resolveArchifyHome({ allowMissing = false } = {}) {
  const lock = loadArchifyLock();
  const envHome = process.env.ARCHIFY_HOME;
  const candidates = [];

  if (envHome) {
    candidates.push(path.resolve(envHome));
  }

  candidates.push(path.join(pluginRoot, '.vendor', 'archify', lock.skill_relative_path));
  candidates.push(path.join(pluginRoot, '.vendor', 'archify'));

  for (const candidate of candidates) {
    const cli = path.join(candidate, 'bin', 'archify.mjs');
    if (fs.existsSync(cli)) {
      return {
        home: candidate,
        cli,
        version: readArchifyVersion(candidate) || lock.version,
        lock,
      };
    }
  }

  if (allowMissing) {
    return { home: null, cli: null, version: lock.version, lock };
  }

  throw new Error(
    [
      'Archify runtime not found.',
      'Set ARCHIFY_HOME to a pinned Archify skill directory, or bootstrap explicitly:',
      '  node plugins/examples/archify/scripts/bootstrap-archify.mjs',
      `Expected pin: ${lock.package}@${lock.version} (${lock.commit})`,
    ].join('\n'),
  );
}

export function readArchifyVersion(home) {
  try {
    const pkg = JSON.parse(fs.readFileSync(path.join(home, 'package.json'), 'utf8'));
    return pkg.version;
  } catch {
    return null;
  }
}

export function runArchify(cli, args, { json = false } = {}) {
  const result = spawnSync(process.execPath, [cli, ...args], {
    encoding: 'utf8',
    cwd: path.dirname(cli),
  });

  if (result.error) {
    throw new Error(`Failed to spawn Archify: ${result.error.message}`);
  }

  const stdout = result.stdout || '';
  const stderr = result.stderr || '';
  if (!json) {
    if (stdout) process.stdout.write(stdout);
    if (stderr) process.stderr.write(stderr);
  }

  return {
    status: result.status ?? 1,
    stdout,
    stderr,
    ok: (result.status ?? 1) === 0,
  };
}
