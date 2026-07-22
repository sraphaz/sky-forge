import { sanitizeDeep, sanitizeText } from './sanitize.mjs';

const ADAPTER_VERSION = '0.1.0';
const KIND_ENUM = new Set([
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

export function normalizeIr(pkg, { generatedAt, qualityProfile = 'standard', visualPreset = 'classic' } = {}) {
  const brief = pkg.artifacts['brief.yaml'];
  const architecture = pkg.artifacts['architecture.yaml'];
  const inferences = [];
  const elements = [];
  const relationships = [];
  const boundaries = [];
  const views = [];

  const systemId = slugify(brief.title || pkg.slug || 'system');
  const components = Array.isArray(architecture.components) ? architecture.components : [];

  for (const component of components) {
    if (!component?.id) continue;
    const kind = mapKind(component);
    if (kind.inferred) {
      inferences.push({
        id: `kind:${component.id}`,
        subject: component.id,
        detail: `Mapped kind "${kind.value}" from tech/role heuristics`,
      });
    }
    elements.push({
      id: ensureId(component.id),
      name: sanitizeText(component.name || component.id),
      kind: kind.value,
      description: sanitizeText(component.role || ''),
      technology: sanitizeText(component.tech || ''),
      role: sanitizeText(component.role || ''),
      confidence: 'confirmed',
      source_refs: [`architecture.yaml#/components/${component.id}`],
      tags: kind.inferred ? ['kind_inferred_from_tech'] : [],
    });
  }

  // Explicit relationships only — never invent topology from prose.
  const explicitRels = architecture.relationships || architecture.connections || [];
  for (const rel of explicitRels) {
    if (!rel?.id || !rel?.source || !rel?.target) continue;
    const confidence = rel.confidence || 'confirmed';
    const sourceRefs = Array.isArray(rel.source_refs) && rel.source_refs.length
      ? rel.source_refs
      : [`architecture.yaml#/relationships/${rel.id}`];
    if (confidence === 'inferred') {
      inferences.push({
        id: `rel:${rel.id}`,
        subject: rel.id,
        detail: sanitizeText(rel.label || 'inferred relationship'),
      });
    }
    relationships.push({
      id: ensureId(rel.id),
      source: ensureId(rel.source),
      target: ensureId(rel.target),
      label: sanitizeText(rel.label || 'uses'),
      protocol: sanitizeText(rel.protocol || ''),
      data_classification: sanitizeText(rel.data_classification || ''),
      confidence,
      source_refs: sourceRefs,
    });
  }

  const explicitBoundaries = architecture.boundaries || [];
  for (const boundary of explicitBoundaries) {
    if (!boundary?.id) continue;
    boundaries.push({
      id: ensureId(boundary.id),
      name: sanitizeText(boundary.name || boundary.id),
      kind: boundary.kind || 'system',
      members: (boundary.members || []).map(ensureId),
      source_refs: boundary.source_refs || [`architecture.yaml#/boundaries/${boundary.id}`],
    });
  }

  const primaryIds = components.slice(0, 12).map((c) => ensureId(c.id));
  views.push({
    id: 'system-architecture',
    name: 'System architecture',
    type: 'architecture',
    question_answered: sanitizeText(
      architecture.approach ||
        brief.desired_outcome ||
        'What are the primary runtime components of the solution?',
    ),
    include: primaryIds,
    primary_path: primaryIds.slice(0, Math.min(primaryIds.length, 6)),
    quality_profile: qualityProfile === 'showcase' ? 'showcase' : 'standard',
    visual_preset: ['classic', 'signal-flow', 'blueprint'].includes(visualPreset)
      ? visualPreset
      : 'classic',
  });

  const workflowEvidence = collectWorkflowEvidence(pkg);
  if (workflowEvidence) {
    for (const node of workflowEvidence.nodes) {
      if (elements.some((e) => e.id === node.id)) continue;
      elements.push(node);
      if (node.confidence === 'inferred') {
        inferences.push({
          id: `workflow-node:${node.id}`,
          subject: node.id,
          detail: node.description || node.name,
        });
      }
    }
    for (const rel of workflowEvidence.relationships) {
      relationships.push(rel);
      if (rel.confidence === 'inferred') {
        inferences.push({
          id: `workflow-rel:${rel.id}`,
          subject: rel.id,
          detail: rel.label,
        });
      }
    }
    views.push({
      id: 'delivery-workflow',
      name: 'Delivery workflow',
      type: 'workflow',
      question_answered: 'How does the package move through human gates to handoff?',
      include: workflowEvidence.nodes.map((n) => n.id),
      primary_path: workflowEvidence.mainPath,
      quality_profile: qualityProfile === 'showcase' ? 'showcase' : 'standard',
      visual_preset: 'classic',
    });
  }

  const sequenceEvidence = collectSequenceEvidence(pkg);
  if (sequenceEvidence) {
    for (const node of sequenceEvidence.participants) {
      if (elements.some((e) => e.id === node.id)) continue;
      elements.push(node);
    }
    for (const rel of sequenceEvidence.relationships) {
      relationships.push(rel);
    }
    views.push({
      id: 'critical-path-sequence',
      name: 'Critical path sequence',
      type: 'sequence',
      question_answered: sequenceEvidence.question,
      include: sequenceEvidence.participants.map((p) => p.id),
      primary_path: sequenceEvidence.mainPath,
      quality_profile: qualityProfile === 'showcase' ? 'showcase' : 'standard',
      visual_preset: 'classic',
    });
  }

  const ir = {
    metadata: {
      schema_version: '0.1.0',
      package_slug: String(pkg.slug),
      generated_at: generatedAt || new Date().toISOString(),
      source_package_version: String(pkg.packageVersion),
      generator_version: ADAPTER_VERSION,
    },
    system: {
      id: systemId,
      name: sanitizeText(brief.title || pkg.slug),
      description: sanitizeText(brief.intent || brief.desired_outcome || ''),
      scope: sanitizeText(architecture.approach || ''),
    },
    elements,
    relationships,
    boundaries,
    views,
  };

  return {
    ir: sanitizeDeep(ir),
    inferences,
    workflowEvidence: Boolean(workflowEvidence),
    sequenceEvidence: Boolean(sequenceEvidence),
  };
}

function collectWorkflowEvidence(pkg) {
  const packageMeta = pkg.artifacts['package.yaml'];
  const handoff = pkg.artifacts['handoff-solution.yaml'];
  const gates = Array.isArray(packageMeta?.gates) ? packageMeta.gates : [];
  const milestones = Array.isArray(handoff?.implementation_plan?.milestones)
    ? handoff.implementation_plan.milestones
    : [];

  if (!gates.length && !milestones.length) return null;

  const nodes = [];
  const relationships = [];
  const mainPath = [];

  if (gates.length) {
    for (const gate of gates) {
      const id = ensureId(`gate-${gate.id}`);
      nodes.push({
        id,
        name: sanitizeText(gate.id),
        kind: 'policy',
        description: sanitizeText(gate.notes || `Gate passed by ${gate.passed_by || 'unknown'}`),
        confidence: 'confirmed',
        source_refs: [`package.yaml#/gates/${gate.id}`],
        tags: ['workflow', 'gate'],
      });
      mainPath.push(id);
    }
    for (let i = 0; i < gates.length - 1; i += 1) {
      const from = ensureId(`gate-${gates[i].id}`);
      const to = ensureId(`gate-${gates[i + 1].id}`);
      relationships.push({
        id: ensureId(`flow-${gates[i].id}-to-${gates[i + 1].id}`),
        source: from,
        target: to,
        label: 'then',
        confidence: 'confirmed',
        source_refs: [`package.yaml#/gates/${gates[i].id}`, `package.yaml#/gates/${gates[i + 1].id}`],
      });
    }
  }

  if (milestones.length) {
    for (const milestone of milestones) {
      const id = ensureId(`ms-${milestone.id}`);
      nodes.push({
        id,
        name: sanitizeText(milestone.name || milestone.id),
        kind: 'artifact',
        description: sanitizeText(milestone.outcome || ''),
        confidence: 'confirmed',
        source_refs: [`handoff-solution.yaml#/implementation_plan/milestones/${milestone.id}`],
        tags: ['workflow', 'milestone'],
      });
    }
  }

  return { nodes, relationships, mainPath: mainPath.length ? mainPath : nodes.map((n) => n.id) };
}

function collectSequenceEvidence(pkg) {
  const sequences = pkg.artifacts['sequences.yaml'];
  if (!sequences) return null;

  const list = Array.isArray(sequences.sequences)
    ? sequences.sequences
    : Array.isArray(sequences)
      ? sequences
      : sequences.critical_path
        ? [sequences.critical_path]
        : [];

  const chosen = list[0];
  if (!chosen) return null;

  const participantsRaw = chosen.participants || chosen.actors || [];
  const steps = chosen.steps || chosen.messages || [];
  if (!participantsRaw.length || !steps.length) return null;

  const participants = participantsRaw.map((p) => {
    const id = ensureId(typeof p === 'string' ? p : p.id);
    return {
      id,
      name: sanitizeText(typeof p === 'string' ? p : p.name || p.id),
      kind: mapParticipantKind(p),
      description: sanitizeText(typeof p === 'string' ? '' : p.role || ''),
      confidence: 'confirmed',
      source_refs: [`sequences.yaml#/participants/${id}`],
      tags: ['sequence'],
    };
  });

  const relationships = [];
  steps.forEach((step, index) => {
    const from = ensureId(step.from || step.source);
    const to = ensureId(step.to || step.target);
    if (!from || !to) return;
    relationships.push({
      id: ensureId(step.id || `msg-${index + 1}`),
      source: from,
      target: to,
      label: sanitizeText(step.label || step.message || `step ${index + 1}`),
      confidence: 'confirmed',
      source_refs: [`sequences.yaml#/steps/${index}`],
    });
  });

  return {
    participants,
    relationships,
    mainPath: participants.map((p) => p.id),
    question: sanitizeText(chosen.question || chosen.name || 'What is the critical interaction path?'),
    title: sanitizeText(chosen.name || 'Critical path'),
    raw: chosen,
  };
}

function mapKind(component) {
  const tech = `${component.tech || ''} ${component.role || ''} ${component.name || ''}`.toLowerCase();
  if (/\b(person|human|user|steward)\b/.test(tech)) return { value: 'person', inferred: true };
  if (/\b(postgres|sqlite|redis|database|db|ledger|append-only)\b/.test(tech)) {
    return { value: 'database', inferred: true };
  }
  if (/\b(queue|sqs|kafka|bus)\b/.test(tech)) return { value: 'queue', inferred: true };
  if (/\b(agent|harness)\b/.test(tech)) return { value: 'agent', inferred: true };
  if (/\b(policy|gate|approval|auth)\b/.test(tech)) return { value: 'policy', inferred: true };
  if (/\b(git|repo|arquivo|file|yaml|schema)\b/.test(tech)) return { value: 'artifact', inferred: true };
  if (/\b(next\.js|ui|frontend|react)\b/.test(tech)) return { value: 'container', inferred: true };
  if (/\b(external|third.party|provider)\b/.test(tech)) return { value: 'external', inferred: true };
  if (KIND_ENUM.has(component.kind)) return { value: component.kind, inferred: false };
  return { value: 'component', inferred: true };
}

function mapParticipantKind(p) {
  if (typeof p !== 'string' && KIND_ENUM.has(p.kind)) return p.kind;
  const text = `${typeof p === 'string' ? p : `${p.name || ''} ${p.role || ''}`}`.toLowerCase();
  if (/\b(user|person|human)\b/.test(text)) return 'person';
  if (/\b(db|database|redis|postgres)\b/.test(text)) return 'database';
  if (/\b(api|service|backend)\b/.test(text)) return 'container';
  return 'component';
}

function ensureId(value) {
  const raw = String(value || '')
    .trim()
    .replace(/[^a-zA-Z0-9_-]+/g, '-')
    .replace(/^-+|-+$/g, '');
  if (!raw) return 'item';
  if (/^[0-9]/.test(raw)) return `n-${raw}`;
  return raw;
}

function slugify(value) {
  return ensureId(String(value || 'system').toLowerCase());
}

export { ADAPTER_VERSION };
