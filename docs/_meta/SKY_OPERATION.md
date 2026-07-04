# Operação do Sky-Forge

**Versão**: 1.1 | **Data**: 2026-07-04

## Objetivo

Repositório operável por agentes que **eleva** intenções vagas em pacotes de especificação
maduros — com índices SKY, UX digna e export Cloud Design.

## Sequência de PRs

| PR | Conteúdo | Status |
|----|----------|--------|
| **1** | Esqueleto + Sky-Forge + sky-elevator + ux-design-specialist | ✅ |
| **1c** | Autonomia + coreografia v3 + auditoria + agent graph | ✅ |
| **2** | sky-plan batch + task graph | pendente |
| **3** | learn-from-outcome | pendente |
| **4** | RAG local | pendente |
| **5** | sky-cloud-design completo | pendente |
| **6** | Piloto end-to-end | pendente |

## Artefatos por sessão

| Path | Conteúdo |
|------|----------|
| `.sky/sessions/{slug}/maturity.yaml` | 6 dimensões de maturidade |
| `.sky/sessions/{slug}/sky-merits.yaml` | Índices SKY + elevação |
| `.sky/sessions/{slug}/ux-spec.yaml` | UX specialist |
| `.sky/sessions/{slug}/brief-draft.yaml` | Brief |
| `.sky/sessions/{slug}/functional-requirements.yaml` | RFs |
| `outputs/{slug}/` | Pacote exportável (pasta configurável via `SKY_OUTPUTS_DIR`) |
| `showcase/registry/` | Previews públicos para site visual |
| `apps/showcase/` | Galeria Astro (MIT) |
| `.sky/audit/{slug}/` | Trilha de auditoria de agentes (local) |
| `docs/_meta/agent-graph.generated.json` | Grafo operacional exportado |

## CLI

```powershell
./scripts/sky/sky.ps1 intake -Slug <slug>
./scripts/sky/sky.ps1 elevate -Slug <slug>
./scripts/sky/sky.ps1 export -Slug <slug> -Completeness partial
./scripts/sky/sky.ps1 publish -Slug <slug> -Public
./scripts/sky/sky.ps1 audit -Slug <slug>
./scripts/agents/export-agent-graph.ps1
./scripts/harness/run-harness.ps1
./scripts/harness/validate-specs.ps1 -SpecId sky-package
```
