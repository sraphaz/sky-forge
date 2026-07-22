import YAML from 'yaml';
import { ADAPTER_VERSION } from './normalize-ir.mjs';

export function buildManifest({
  packageSlug,
  packageHash,
  generatedAt,
  archifyVersion,
  viewsRequested,
  outputs,
  inferences,
  missingOptional,
  publicAuthorized,
  warnings = [],
}) {
  return {
    adapter: {
      id: 'archify-visualization',
      version: ADAPTER_VERSION,
    },
    renderer: {
      name: 'archify',
      version: archifyVersion,
    },
    source: {
      package_slug: packageSlug,
      package_hash: packageHash,
      generated_at: generatedAt,
      public_authorized: Boolean(publicAuthorized),
    },
    views_requested: viewsRequested,
    outputs,
    inferences: inferences.map((i) => ({
      id: i.id,
      subject: i.subject,
      detail: i.detail,
    })),
    missing_optional_artifacts: missingOptional,
    warnings,
    privacy: {
      default: 'private',
      inherited_public_authorization: Boolean(publicAuthorized),
      note: publicAuthorized
        ? 'Source package marks public showcase approval.'
        : 'HTML outputs remain private by default.',
    },
  };
}

export function stringifyManifest(manifest) {
  return YAML.stringify(manifest, { lineWidth: 100 });
}
