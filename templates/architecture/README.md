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
  craft-review.md     # clean-craft-advisor
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

| Agente | Skill |
|--------|-------|
| c4-modeler | sky-c4-model |
| journey-sequence-modeler | sky-journey-sequences |
| clean-craft-advisor | sky-clean-craft |
