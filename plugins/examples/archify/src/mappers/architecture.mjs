/** Map Sky Architecture IR kinds to Archify componentType values. */
export function toArchifyType(kind) {
  switch (kind) {
    case 'person':
    case 'external':
      return 'external';
    case 'database':
      return 'database';
    case 'queue':
      return 'messagebus';
    case 'policy':
      return 'security';
    case 'agent':
      return 'backend';
    case 'container':
      return 'frontend';
    case 'artifact':
      return 'cloud';
    case 'system':
    case 'component':
    default:
      return 'backend';
  }
}

export function mapArchitecture(ir, { qualityProfile = 'standard' } = {}) {
  const view = ir.views.find((v) => v.type === 'architecture') || ir.views[0];
  const include = new Set(view?.include || ir.elements.map((e) => e.id));
  const elements = ir.elements.filter((e) => include.has(e.id)).slice(0, 12);

  const cols = Math.min(6, Math.max(3, Math.ceil(Math.sqrt(elements.length))));
  const components = elements.map((el, index) => {
    const row = Math.floor(index / cols);
    const col = index % cols;
    const inferred = el.confidence === 'inferred';
    return {
      id: el.id,
      type: toArchifyType(el.kind),
      label: el.name,
      sublabel: el.technology || el.role || undefined,
      tag: inferred ? 'inferred' : undefined,
      row,
      col,
    };
  });

  const idSet = new Set(components.map((c) => c.id));
  const byId = new Map(components.map((c) => [c.id, c]));
  const connections = (ir.relationships || [])
    .filter((rel) => idSet.has(rel.source) && idSet.has(rel.target))
    .filter((rel) => (rel.source_refs || []).some((ref) => String(ref).startsWith('architecture.yaml')))
    .map((rel) => {
      const from = byId.get(rel.source);
      const to = byId.get(rel.target);
      const sameRow = from && to && from.row === to.row;
      const sameCol = from && to && from.col === to.col;
      const connection = {
        from: rel.source,
        to: rel.target,
        // Keep edge labels short; long labels move to cards to avoid Archify layout collisions.
        label: String(rel.label || '').length > 12 ? undefined : rel.label,
        variant: rel.confidence === 'inferred' ? 'dashed' : 'default',
        labelDy: sameRow ? 54 : sameCol ? 28 : 40,
      };
      if (sameCol) {
        connection.fromSide = 'bottom';
        connection.toSide = 'top';
        connection.labelDx = 64;
      }
      return connection;
    });

  const boundaries = (ir.boundaries || [])
    .map((b) => ({
      kind: b.kind === 'trust' || b.kind === 'network' ? 'security-group' : 'region',
      label: b.name,
      wraps: (b.members || []).filter((id) => idSet.has(id)),
    }))
    .filter((b) => b.wraps.length > 0);

  const inferredCards = ir.elements
    .filter((e) => e.confidence === 'inferred')
    .slice(0, 4)
    .map((e) => `${e.name} (${e.id})`);

  return {
    schema_version: 1,
    diagram_type: 'architecture',
    meta: {
      title: view?.name || ir.system.name,
      subtitle: `${ir.system.name} · quality=${qualityProfile}`,
      output: 'system.architecture.html',
    },
    layout: {
      mode: 'grid',
      origin: [40, 100],
      cols,
      gapX: 28,
      gapY: 48,
      cellW: 140,
      cellH: 64,
    },
    components,
    boundaries,
    connections,
    cards: [
      {
        dot: 'cyan',
        title: 'Scope',
        items: [ir.system.description, view?.question_answered].filter(Boolean).slice(0, 3),
      },
      {
        dot: 'emerald',
        title: 'Primary components',
        items: components.slice(0, 4).map((c) => c.label),
      },
      ...(inferredCards.length
        ? [
            {
              dot: 'orange',
              title: 'Inferred (explicit)',
              items: inferredCards,
            },
          ]
        : []),
    ],
  };
}
