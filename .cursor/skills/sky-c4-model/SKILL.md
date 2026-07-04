# Sky C4 Model — Cursor skill

Use quando `technical.score >= 0.6` e gate `architecture` aprovado.

## Agente

`c4-modeler` — três níveis C4 + domínios + ADRs.

## Antes de produzir

1. `.sky/sessions/{slug}/brief-draft.yaml`, `functional-requirements.yaml`, `integrations.yaml`
2. `templates/architecture/README.md`
3. Consultar `stack-curator` e `security-compliance` para boundaries

## Outputs (em `.sky/sessions/{slug}/architecture/`)

| Arquivo | Nível |
|---------|-------|
| `c4-context.md` | L1 — sistema no mundo |
| `c4-containers.md` | L2 — apps, APIs, stores |
| `c4-components.md` | L3 — componentes por container crítico |
| `c4-summary.md` | Resumo sanitizado (showcase) |
| `domains.md` | Bounded contexts |
| `adrs/ADR-NNN-*.md` | Decisões estruturais |

## Formato

- Diagramas em **Mermaid** (`C4Context` style via flowchart ou blocos C4-like)
- Cada arquivo: propósito, diagrama, notas, refs a RFs
- Após L2/L3: convocar `clean-craft-advisor` (skill `sky-clean-craft`)

## Comando

```powershell
./scripts/sky/sky.ps1 approve -Slug <slug> -Stage architecture
```

Persistir em `.sky/sessions/{slug}/architecture/` antes do export.
