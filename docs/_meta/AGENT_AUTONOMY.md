# Autonomia dos agentes — Sky-Forge

**Versão**: 1.0 | **Data**: 2026-07-04

## Níveis (0–6)

| Nível | ID | O que pode fazer |
|-------|-----|------------------|
| 0 | `observe` | Ler sessão, maturity, journey |
| 1 | `consult` | Parecer de domínio (sem escrita) |
| 2 | `route` | Handoff e opções (sky-host) |
| 3 | `activate` | Escrever `.sky/sessions/` |
| 4 | `invoke_skill` | Executar `sky.ps1` / skills |
| 5 | `side_effect` | Export, `outputs/`, registry |
| 6 | `public` | `publish -Public` — **sempre** gate humano |

Fonte: [`.agents/autonomy.yaml`](../../.agents/autonomy.yaml)

## Gates humanos

| Gate | Bloqueia até aprovar |
|------|----------------------|
| `brief` | Export e side effects |
| `elevation` | Publish público (se aplicável) |
| `package` | Export completo |
| `public_showcase` | `-Public` no showcase |

```powershell
./scripts/sky/sky.ps1 approve -Slug <slug> -Stage package
./scripts/sky/sky.ps1 approve -Slug <slug> -Stage public_showcase
```

## Verificar antes de agir

```powershell
./scripts/sky/check-autonomy.ps1 -Slug iautos -AgentId delivery-steward -Action export.package
./scripts/sky/sky.ps1 choreograph -Slug iautos -Intent deliver
```

## Bloqueio

Ações acima do `max_autonomy` do agente na coreografia são **bloqueadas** e registradas em `.sky/audit/{slug}/events.jsonl` com `outcome: blocked`.

## Co-ativação

Domínio (`sky-elevator`, `cost-tier-advisor`) nunca passa de `consult`. Operacionais têm teto declarado em [choreography.yaml](../../.agents/choreography.yaml) v3.
