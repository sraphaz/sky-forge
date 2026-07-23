import fs from 'node:fs';
import path from 'node:path';
import { createHash } from 'node:crypto';

export function sha256Hex(value) {
  return createHash('sha256').update(value).digest('hex');
}

export function sha256File(filePath) {
  return sha256Hex(fs.readFileSync(filePath));
}

export function hashPackage(packagePath) {
  const files = listPackageFiles(packagePath);
  const payload = files
    .map((rel) => {
      const abs = path.join(packagePath, rel);
      return `${rel}\n${sha256File(abs)}`;
    })
    .join('\n');
  return `sha256:${sha256Hex(payload)}`;
}

export function listPackageFiles(packagePath) {
  const out = [];
  walk(packagePath, packagePath, out);
  return out.sort((a, b) => a.localeCompare(b));
}

function walk(root, current, out) {
  for (const entry of fs.readdirSync(current, { withFileTypes: true })) {
    if (entry.name.startsWith('.')) continue;
    const abs = path.join(current, entry.name);
    const rel = path.relative(root, abs).split(path.sep).join('/');
    if (entry.isDirectory()) {
      walk(root, abs, out);
    } else if (entry.isFile()) {
      out.push(rel);
    }
  }
}
