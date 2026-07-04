# AGENTS.md — {ProjectTitle}

Projeto gerado por Sky-Forge. Humanos aprovam merge; agentes executam via PR.

## Stack (do pacote forge)

Ver `docs/specs/phase-0.spec.yaml` e prompts em `prompts/`.

## Agentes de implementação

| ID | Função |
|----|--------|
| orchestrator | Roteamento |
| backend / web / mobile | Implementação por área |

## Agentes da solução (se IA multi-agente)

Ver `architecture/agents/` e `architecture/agent-architecture.md` no pacote exportado.

## Stories (implementação)

Shard por story: `stories/IA-*.yaml` — padrão BMAD context-engineered (ver `templates/stories/`).

## Princípios

- Spec-before-code
- Testes em todo PR
- Documentação no mesmo PR que código

## Referências do pacote

- Brief: `spec/brief.yaml` (sincronizado via `./scripts/sky.ps1 pull-spec`)
- Arquitetura: `spec/architecture/`
- Stories: `spec/stories/IA-*.yaml`
- Enriquecimento BMAD: docs no repositório Sky-Forge

## Sky-Forge (deste repo)

Repositório **ligado** ao Sky-Forge após `sky link`:

```powershell
./scripts/sky.ps1 status              # maturidade da sessão
./scripts/sky.ps1 pull-spec           # atualizar spec/ do pacote exportado
./scripts/sky.ps1 export -ForAI -Scope spec
```

Intake, export completo e publish rodam no repo Sky-Forge (`.sky/sessions/{slug}/`).
