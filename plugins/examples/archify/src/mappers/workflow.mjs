import { toArchifyType } from './architecture.mjs';

/** Archify workflow columns are limited to 0..5; keep nodes sparse enough for layout checks. */
const COL_SLOTS = [0, 2, 4, 5];

export function mapWorkflow(ir, { qualityProfile = 'standard' } = {}) {
  const view = ir.views.find((v) => v.type === 'workflow');
  if (!view) return null;

  const include = new Set(view.include || []);
  const nodesSource = ir.elements.filter((e) => include.has(e.id));
  if (!nodesSource.length) return null;

  const gates = nodesSource.filter((n) => (n.tags || []).includes('gate') || n.kind === 'policy');
  const milestones = nodesSource.filter((n) => (n.tags || []).includes('milestone'));
  const working = (gates.length ? gates : nodesSource).slice(0, COL_SLOTS.length);

  const lanes = [
    { id: 'gates', label: 'Package gates' },
    { id: 'delivery', label: 'Delivery notes' },
  ];

  const nodes = working.map((el, index) => ({
    id: el.id,
    lane: 'gates',
    col: COL_SLOTS[index],
    type: toArchifyType(el.kind),
    label: shortenLabel(el.name),
    sublabel: el.name !== shortenLabel(el.name) ? el.name : el.description || undefined,
    tag: el.confidence === 'inferred' ? 'inferred' : undefined,
  }));

  // Anchor note for milestones (evidence preserved in cards, not invented edges).
  if (milestones.length) {
    nodes.push({
      id: milestones[0].id,
      lane: 'delivery',
      col: COL_SLOTS[Math.min(working.length - 1, COL_SLOTS.length - 1)],
      type: toArchifyType(milestones[0].kind),
      label: shortenLabel(milestones[0].name),
      sublabel: milestones[0].name,
    });
  }

  const maxCol = Math.max(...nodes.map((n) => n.col), 0);
  const phases = [
    { id: 'start', label: 'Start', fromCol: 0, toCol: Math.min(2, maxCol) },
    {
      id: 'middle',
      label: 'Progress',
      fromCol: Math.min(2, maxCol),
      toCol: Math.min(4, maxCol),
      variant: 'emphasis',
    },
    {
      id: 'end',
      label: 'Handoff',
      fromCol: Math.min(4, maxCol),
      toCol: maxCol,
      variant: 'dashed',
    },
  ];

  const idSet = new Set(nodes.map((n) => n.id));
  const gateIds = new Set(working.map((n) => n.id));
  const edgeCandidates = (ir.relationships || []).filter(
    (rel) => gateIds.has(rel.source) && gateIds.has(rel.target),
  );

  const edges = [];
  if (edgeCandidates.length) {
    for (const rel of edgeCandidates) {
      edges.push({
        from: rel.source,
        to: rel.target,
        variant: rel.confidence === 'inferred' ? 'dashed' : 'emphasis',
      });
    }
  } else {
    for (let i = 0; i < working.length - 1; i += 1) {
      edges.push({
        from: working[i].id,
        to: working[i + 1].id,
        variant: 'emphasis',
      });
    }
  }

  const mainPath = (view.primary_path || working.map((n) => n.id)).filter((id) => idSet.has(id));

  return {
    schema_version: 1,
    diagram_type: 'workflow',
    meta: {
      title: view.name,
      subtitle: `${ir.system.name} · quality=${qualityProfile}`,
      output: 'delivery.workflow.html',
      viewBox: [960, 720],
    },
    lanes,
    phases,
    groups: [],
    mainPath: mainPath.length ? mainPath : working.map((n) => n.id),
    nodes,
    edges,
    cards: [
      {
        dot: 'cyan',
        title: 'Question',
        items: [view.question_answered],
      },
      {
        dot: 'emerald',
        title: 'Gates',
        items: working.map((n) => n.name),
      },
      ...(milestones.length
        ? [
            {
              dot: 'orange',
              title: 'Milestones (evidence)',
              items: milestones.map((m) => m.name).slice(0, 4),
            },
          ]
        : []),
    ],
  };
}

function shortenLabel(value) {
  const text = String(value || '')
    .replace(/^gate-/i, '')
    .replace(/_/g, ' ');
  if (text.length <= 14) return text;
  return `${text.slice(0, 13)}…`;
}
