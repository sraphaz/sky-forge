# Atribuição — BMAD Method

**Upstream:** https://github.com/bmad-code-org/BMAD-METHOD  
**Licença:** MIT  
**Uso neste repo:** padrões apenas — tracks adaptativos, fases Analysis→Planning→Solutioning→Implementation, menus de elicitação.

**Não** usamos o nome BMad™ nem distribuímos o pacote npm `bmad-method` como dependência.

## Padrões adotados

- Três tracks de profundidade → nossos tiers + `sustainability_minimum` + `export -Completeness partial|full`
- Workflows por fase → skills `sky-intake`, `sky-plan`, `sky-agent-architecture`
- Agente PM/Architect como roles → operational/domain agents (intake-conductor, solutions-architect)
- **Story shards** → `templates/stories/story.template.yaml` (context-engineered development)
- **Party Mode** → `party_mode` + `co_activation` em choreography.yaml; showcase em `/agentes/`
- **Step-files** → `.skills/sky-plan/steps/*.step.yaml` (on-demand)
- **TEA** → `test-architect` + `sky-test-architecture`
- **Document sharding para IA** → `export-for-ai` essential/spec/full
- **Readiness gate** → `validate-maturity` + `approve -Stage`

Mapeamento completo: [BMAD_ENRICHMENT.md](../_meta/BMAD_ENRICHMENT.md)
