# Templates de arquitetura — Sky-Forge

Copie para `.sky/sessions/{slug}/architecture/` e preencha a partir do brief.

## Estrutura

```
architecture/
  c4-context.md       # L1
  c4-containers.md    # L2
  c4-components.md    # L3
  c4-summary.md       # Showcase (sanitizado)
  domains.md
  context-flow.md     # Fluxograma end-to-end
  agent-architecture.md  # Ponte C4 ↔ agentes (padrão Arah)
  agent-graph.md      # Grafo de agentes da solução
  craft-review.md     # clean-craft-advisor
  agents/             # Manifests da solução (não Sky-Forge)
    *.agent.yaml
    choreography.yaml
    autonomy.yaml
  specs/
    agent-harness.spec.yaml
  sequences/
    journey-*.md
  adrs/
    ADR-001-*.md
```

## Diagramas

Preferir **Mermaid** embutido em Markdown. Renderizável no showcase e no GitHub.

## Gates

- Maturidade: business ≥ 0.80, product ≥ 0.60, ux_design ≥ 0.40
- `./scripts/sky/sky.ps1 approve -Slug <slug> -Stage architecture`

## Agentes

| Agente Sky-Forge | Skill |
|----------------|-------|
| c4-modeler | sky-c4-model |
| journey-sequence-modeler | sky-journey-sequences |
| solutions-architect | sky-agent-architecture |
| clean-craft-advisor | sky-clean-craft |

Soluções com IA multi-agente: ver `agents/README.md` e [arah.md](../../docs/attribution/arah.md).
