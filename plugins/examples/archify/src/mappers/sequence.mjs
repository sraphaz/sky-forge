import { toArchifyType } from './architecture.mjs';

export function mapSequence(ir, { qualityProfile = 'standard' } = {}) {
  const view = ir.views.find((v) => v.type === 'sequence');
  if (!view) return null;

  const include = new Set(view.include || []);
  const participants = ir.elements
    .filter((e) => include.has(e.id))
    .map((el) => ({
      id: el.id,
      type: toArchifyType(el.kind),
      label: el.name,
      sublabel: el.description || el.technology || undefined,
    }));

  if (participants.length < 2) return null;

  // Only sequence evidence — do not pull architecture/workflow topology edges
  // that happen to share participant IDs (see architecture.mjs source_refs filter).
  const messagesSource = (ir.relationships || []).filter(
    (rel) =>
      include.has(rel.source) &&
      include.has(rel.target) &&
      (rel.source_refs || []).some((ref) => String(ref).startsWith('sequences.yaml')),
  );
  if (!messagesSource.length) return null;

  const startY = 180;
  const gap = 42;
  const messages = messagesSource.map((rel, index) => ({
    from: rel.source,
    to: rel.target,
    y: startY + index * gap,
    label: rel.label,
    variant: rel.confidence === 'inferred' ? 'dashed' : index === 0 ? 'emphasis' : 'default',
  }));

  const lastY = messages[messages.length - 1].y;
  const activations = participants.slice(0, 4).map((p, index) => ({
    participant: p.id,
    from: startY - 10 + index * 4,
    to: lastY + 20,
    type: p.type,
  }));

  const segments = [
    { from: startY - 30, to: startY + Math.floor(messages.length / 2) * gap, label: 'Request' },
    {
      from: startY + Math.floor(messages.length / 2) * gap + 10,
      to: lastY + 30,
      label: 'Response',
    },
  ];

  return {
    schema_version: 1,
    diagram_type: 'sequence',
    meta: {
      title: view.name,
      subtitle: `${ir.system.name} · quality=${qualityProfile}`,
      output: 'critical-path.sequence.html',
      viewBox: [Math.max(720, 120 + participants.length * 110), Math.max(520, lastY + 160)],
    },
    participants,
    segments,
    messages,
    activations,
    cards: [
      {
        dot: 'cyan',
        title: 'Question',
        items: [view.question_answered],
      },
      {
        dot: 'emerald',
        title: 'Path',
        items: messages.slice(0, 4).map((m) => `${m.from} → ${m.to}: ${m.label}`),
      },
    ],
  };
}
