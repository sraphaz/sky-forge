# Agent Graph — Sky-Forge

**Versão**: 1.0 | **Data**: 2026-07-04

Espelho auditável do grafo operacional: agentes ↔ coreografia ↔ skills ↔ gates ↔ autonomia.

## Comandos

```powershell
./scripts/agents/export-agent-graph.ps1
./scripts/agents/validate-agent-graph.ps1
./scripts/agents/choreograph-agents.ps1 -ChangedFiles .sky/sessions/iautos/maturity.yaml -Slug iautos
```

## Artefato

[`docs/_meta/agent-graph.generated.json`](../_meta/agent-graph.generated.json)

## Nós

| Tipo | Fonte |
|------|-------|
| Agent | `.agents/**/*.agent.yaml` |
| Skill | `.skills/*.skill.yaml` |
| ChoreographyRule | `.agents/choreography.yaml` v3 |
| AutonomyLevel | `.agents/autonomy.yaml` |
| HumanGate | `.agents/autonomy.yaml` |

## Arestas

- `activates_agent` — rule → agent
- `may_invoke_skill` — agent → skill
- `requires_gate` — agent → gate
- `max_autonomy` — agent → nível

## Runtime vs graph

- **Runtime**: `choreograph-agents.ps1` decide quem ativa
- **Graph**: export + validate — consistência e onboarding

Não substitui o orquestrador; complementa com observabilidade.

Ver também: [AGENT_AUTONOMY.md](../_meta/AGENT_AUTONOMY.md) · [AGENT_OBSERVABILITY.md](../_meta/AGENT_OBSERVABILITY.md)
