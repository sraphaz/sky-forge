# Templates — arquitetura agêntica da solução (Arah)

Copie para `.sky/sessions/{slug}/architecture/agents/` após C4.

## Estrutura

```
architecture/
  agent-architecture.md     # Ponte C4 ↔ agentes
  agent-graph.md            # Grafo Mermaid
  agents/
    orchestrator.agent.yaml
    *.agent.yaml            # Especialistas da solução
    choreography.yaml
    autonomy.yaml
  specs/
    agent-harness.spec.yaml
```

## Manifest (`.agent.yaml`)

```yaml
id: orchestrator
name: Orchestrator
description: Roteia tarefas entre agentes da solução
triggers: [user_message, task_dispatch]
scope:
  paths: [case/{case_id}/]
  may_write: false
skills: []
domain_consults: [compliance-guard]
handoff_to: [case-analyst, document-researcher]
outputs: [task_plan.yaml]
guardrails:
  hitl_before_publish: true
```

## Coreografia

Regras com `when`, `paths` ou `intent`, lista de agentes com `type: operational|domain` e `max_autonomy`.

## Harness spec

`specs/agent-harness.spec.yaml` — critérios Given/When/Then para guardrails, Claim model e HITL.

## Referência

[docs/attribution/arah.md](../../../docs/attribution/arah.md)
