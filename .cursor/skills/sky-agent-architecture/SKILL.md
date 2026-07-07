# Sky Agent Architecture — Cursor skill

Use quando a solução tem **IA multi-agente**, copiloto ou orquestração (RF com epic E3/E4 ou containers Agent/Copilot no C4).

Padrão inspirado em [Arah](../../docs/attribution/arah.md) — manifests da **solução**, não dos agentes Sky-Forge.

## Quando produzir

1. Após C4 L2/L3 (`c4-containers.md`, `c4-components.md`)
2. Gate `architecture` aprovado
3. RFs de harness, roster ou copiloto confirmados

## Outputs (em `.sky/sessions/{slug}/architecture/`)

| Artefato | Propósito |
|----------|-----------|
| `agent-architecture.md` | Visão: como agentes da solução mapeiam containers C4 |
| `agent-graph.md` | Grafo Mermaid — ativação, handoffs, consultas |
| `agents/*.agent.yaml` | Manifests por agente da solução |
| `agents/choreography.yaml` | Regras de co-ativação e triggers |
| `agents/autonomy.yaml` | Níveis e gates HITL da solução |
| `specs/agent-harness.spec.yaml` | Harness spec-driven (aceite verificável) |

## Ordem no pipeline

```
c4-modeler → journey-sequence-modeler → sky-agent-architecture → clean-craft-advisor
```

## Comando

```powershell
./scripts/sky/sky.ps1 architect -Slug <slug> -Force
```

Persistir em `.sky/sessions/{slug}/architecture/` antes do export.
