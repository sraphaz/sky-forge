# Observabilidade e auditoria — agentes Sky-Forge

**Versão**: 1.0 | **Data**: 2026-07-04

## Trilha de auditoria

Append-only por sessão:

```
.sky/audit/{slug}/events.jsonl
```

Cada linha:

```json
{
  "ts": "2026-07-04T15:30:00Z",
  "correlation_id": "a1b2c3d4e5f6",
  "slug": "iautos",
  "agent_id": "delivery-steward",
  "action": "export.package",
  "autonomy_level": "side_effect",
  "outcome": "ok",
  "human_gate": null,
  "details": ""
}
```

### Registrar manualmente

```powershell
./scripts/sky/record-agent-event.ps1 -Slug iautos -AgentId intake-conductor -Action session.write -Outcome ok
```

### Consultar

```powershell
./scripts/sky/sky.ps1 audit -Slug iautos
./scripts/sky/sky.ps1 audit -Last 50
./scripts/sky/agent-audit.ps1 -MetricsOnly
```

## Métricas agregadas

```
.sky/observability/summary.yaml
```

Atualizado a cada evento: `total_events`, `last_agent`, `last_action`, `last_outcome`.

## Coreografia observável

```powershell
./scripts/sky/sky.ps1 agents -Slug iautos -Intent deliver
./scripts/sky/sky.ps1 choreograph -Slug iautos   # JSON
```

Resolve: rules matched, agentes operacionais, consultas de domínio, skills, gates pendentes.

## Hook passivo (Cursor)

[`.cursor/hooks.json`](../../.cursor/hooks.json) → `scripts/hooks/on-stop.ps1`

Ao terminar turno: registra `hook_stop` + resolve coreografia da sessão mais recente.

Defina `$env:SKY_ACTIVE_SLUG` para sessão explícita.

## Agent Graph

```powershell
./scripts/agents/export-agent-graph.ps1
./scripts/agents/validate-agent-graph.ps1
```

Artefato: [`docs/_meta/agent-graph.generated.json`](agent-graph.generated.json)

## Integração CLI

| Comando | Auditoria automática |
|---------|---------------------|
| `sky export` | `export.package` ok/blocked |
| `sky publish` | `publish.preview` / `publish.public` |
| `sky approve` | `human.gate.approved` |
| `choreograph-agents` | `choreography.resolve` |

## Privacidade

## Integração showcase (UI)

Cada `sky publish` gera `showcase/registry/{slug}.agents.json` — visível em:

- `/projects/{slug}/agentes/` — gates, coreografia, trilha
- `/agentes/` — índice global
- Teaser na página do projeto

Atualizar UI: `./scripts/sky/publish-preview.ps1 -Slug <slug>` (inclui agents view).
