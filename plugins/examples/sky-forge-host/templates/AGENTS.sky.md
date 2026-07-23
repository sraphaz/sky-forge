# AGENTS.md — complemento Sky-Forge (host plugin)

Este arquivo **complementa** o AGENTS.md do projeto. Não substitui regras de domínio da plataforma.

## Sky-Forge host

- Profile: `platform-evolution`
- Modo: brownfield — evoluir o que existe, não reescrever sem gate
- Spec sincronizada: `spec/` (somente leitura; fonte no forge)

## Princípios de evolução

1. **Assessment antes de refactor** — `./scripts/sky.ps1 assess` se o repo mudou muito
2. **Spec-before-code** — shard ativa em `spec/stories/` ou fase do roadmap
3. **Gates humanos** — export completo e mudanças estruturais exigem aprovação no forge

## ARAH Harness

Se `spec/agentic-repo-recommendation.yaml` tiver tier `recommended` ou `suggested`, preferir [ARAH Harness](https://github.com/sraphaz/arah-harness) para implementação agêntica.

## Referências

- Assessment: `spec/platform-assessment.yaml`
- Roadmap: `spec/evolution-roadmap.yaml`
- Sessão forge: `.sky/link.yaml`
