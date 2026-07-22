const RENDERER_FIELDS = new Set([
  'pos',
  'size',
  'row',
  'col',
  'x',
  'y',
  'color',
  'colour',
  'fill',
  'stroke',
  'svg',
  'labelAt',
  'labelDx',
  'labelDy',
  'fromSide',
  'toSide',
  'route',
]);

const ELEMENT_KINDS = new Set([
  'person',
  'system',
  'container',
  'component',
  'agent',
  'database',
  'queue',
  'external',
  'policy',
  'artifact',
]);

const CONFIDENCE = new Set(['confirmed', 'inferred', 'unknown']);
const VIEW_TYPES = new Set(['architecture', 'workflow', 'sequence', 'dataflow', 'lifecycle']);

export function validateIr(ir) {
  const errors = [];
  const warnings = [];

  if (!ir || typeof ir !== 'object') {
    return { ok: false, errors: ['IR must be an object'], warnings };
  }

  if (!ir.metadata?.schema_version) errors.push('metadata.schema_version is required');
  if (!ir.metadata?.package_slug) errors.push('metadata.package_slug is required');
  if (!ir.metadata?.generated_at) errors.push('metadata.generated_at is required');
  if (!ir.metadata?.source_package_version) errors.push('metadata.source_package_version is required');
  if (!ir.metadata?.generator_version) errors.push('metadata.generator_version is required');

  if (!ir.system?.id || !ir.system?.name || !ir.system?.description) {
    errors.push('system.id, system.name and system.description are required');
  }

  if (!Array.isArray(ir.elements)) errors.push('elements must be a list');
  if (!Array.isArray(ir.relationships)) errors.push('relationships must be a list');
  if (!Array.isArray(ir.views)) errors.push('views must be a list');

  const elementIds = new Set();
  for (const el of ir.elements || []) {
    if (!el?.id) {
      errors.push('element missing id');
      continue;
    }
    if (elementIds.has(el.id)) errors.push(`duplicate element id: ${el.id}`);
    elementIds.add(el.id);
    if (!el.name) errors.push(`element ${el.id} missing name`);
    if (!ELEMENT_KINDS.has(el.kind)) errors.push(`element ${el.id} has invalid kind: ${el.kind}`);
    if (!CONFIDENCE.has(el.confidence)) errors.push(`element ${el.id} has invalid confidence`);
    if (!Array.isArray(el.source_refs)) errors.push(`element ${el.id} source_refs must be a list`);
    if (el.confidence === 'confirmed' && (!el.source_refs || el.source_refs.length === 0)) {
      errors.push(`confirmed element ${el.id} requires at least one source_ref`);
    }
    collectRendererFields(el, `element ${el.id}`, errors);
  }

  const relationshipIds = new Set();
  for (const rel of ir.relationships || []) {
    if (!rel?.id) {
      errors.push('relationship missing id');
      continue;
    }
    if (relationshipIds.has(rel.id)) errors.push(`duplicate relationship id: ${rel.id}`);
    relationshipIds.add(rel.id);
    if (!elementIds.has(rel.source)) errors.push(`relationship ${rel.id} source missing: ${rel.source}`);
    if (!elementIds.has(rel.target)) errors.push(`relationship ${rel.id} target missing: ${rel.target}`);
    if (!rel.label) errors.push(`relationship ${rel.id} missing label`);
    if (!CONFIDENCE.has(rel.confidence)) errors.push(`relationship ${rel.id} has invalid confidence`);
    if (!Array.isArray(rel.source_refs)) errors.push(`relationship ${rel.id} source_refs must be a list`);
    if (rel.confidence === 'confirmed' && (!rel.source_refs || rel.source_refs.length === 0)) {
      errors.push(`confirmed relationship ${rel.id} requires at least one source_ref`);
    }
    collectRendererFields(rel, `relationship ${rel.id}`, errors);
  }

  const boundaryIds = new Set();
  for (const boundary of ir.boundaries || []) {
    if (!boundary?.id) {
      errors.push('boundary missing id');
      continue;
    }
    if (boundaryIds.has(boundary.id)) errors.push(`duplicate boundary id: ${boundary.id}`);
    boundaryIds.add(boundary.id);
    for (const member of boundary.members || []) {
      if (!elementIds.has(member)) errors.push(`boundary ${boundary.id} unknown member: ${member}`);
    }
    collectRendererFields(boundary, `boundary ${boundary.id}`, errors);
  }

  const viewIds = new Set();
  for (const view of ir.views || []) {
    if (!view?.id) {
      errors.push('view missing id');
      continue;
    }
    if (viewIds.has(view.id)) errors.push(`duplicate view id: ${view.id}`);
    viewIds.add(view.id);
    if (!VIEW_TYPES.has(view.type)) errors.push(`view ${view.id} has invalid type: ${view.type}`);
    if (!view.name) errors.push(`view ${view.id} missing name`);
    if (!view.question_answered || !String(view.question_answered).trim()) {
      errors.push(`view ${view.id} missing question_answered`);
    }
    if (!Array.isArray(view.include) || view.include.length === 0) {
      errors.push(`view ${view.id} include list is empty`);
    }
    for (const id of view.include || []) {
      if (!elementIds.has(id)) errors.push(`view ${view.id} include unknown id: ${id}`);
    }
    for (const id of view.primary_path || []) {
      if (!elementIds.has(id)) errors.push(`view ${view.id} primary_path unknown id: ${id}`);
    }
    collectRendererFields(view, `view ${view.id}`, errors);
  }

  return { ok: errors.length === 0, errors, warnings };
}

function collectRendererFields(obj, label, errors) {
  for (const key of Object.keys(obj || {})) {
    if (RENDERER_FIELDS.has(key)) {
      errors.push(`${label} contains renderer-specific field: ${key}`);
    }
  }
}
