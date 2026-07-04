# AGENTS.md — {ProjectTitle}

Projeto gerado por Sky-Forge. Humanos aprovam merge; agentes executam via PR.

## Stack (do pacote forge)

Ver `docs/specs/phase-0.spec.yaml` e prompts em `prompts/`.

## Agentes

| ID | Função |
|----|--------|
| orchestrator | Roteamento |
| backend / flutter / web | Implementação por área |

## Princípios

- Spec-before-code
- Testes em todo PR
- Documentação no mesmo PR que código

## Referências do pacote

- Brief: importado de Sky-Forge `outputs/{slug}/`
- Arquitetura: `architecture/`
