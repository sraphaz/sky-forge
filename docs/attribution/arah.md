# Atribuição — Arah

**Upstream:** repositório interno sraphaz/arah

## Padrões adotados

- Agent manifests `.agents/**/*.agent.yaml` (Sky-Forge) e `architecture/agents/` (solução)
- Choreography e domain consult posts
- Spec-driven harness (`docs/specs/*.spec.yaml` e `architecture/specs/agent-harness.spec.yaml`)
- Agent graph — `export-agent-graph` (plataforma) + `architecture/agent-graph.md` (solução)

Integrado no pipeline `sky-plan` via skill `sky-agent-architecture` (solutions-architect).

Não é dependência git — referência de operação madura.
