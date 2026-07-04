# Sky Journey Sequences — Cursor skill

Use após `c4-containers.md` existir — modela jornadas do `ux-spec.yaml`.

## Agente

`journey-sequence-modeler`

## Outputs

| Arquivo | Conteúdo |
|---------|----------|
| `architecture/context-flow.md` | Fluxograma end-to-end do sistema |
| `architecture/sequences/journey-*.md` | Um diagrama `sequenceDiagram` por jornada principal |

## Jornadas mínimas

1. Jornada do advogado (abrir caso → analisar → aprovar rascunho)
2. Onboarding de tenant (admin → marca → IA)
3. Opcional: upload/OCR (E2)

## Regras

- Citar IDs de RF (ex. RF-006, RF-009)
- Human-in-the-loop visível nos passos de aprovação
- Atores = containers do C4 L2
- Mermaid `sequenceDiagram` + notas de guardrails

## Skill manifest

`.skills/sky-journey-sequences.skill.yaml`
