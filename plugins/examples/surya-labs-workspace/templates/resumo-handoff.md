<!-- TEMPLATE do plugin — resumo de handoff para o cliente (1–2 páginas).
     Fonte: handoff-solution + acceptance-criteria + repository-link. -->

RESUMO DE HANDOFF · SURYA LABS
{{ demand.id }} · {{ date }}

# {{ demand.title }} — o que você está recebendo

## A solução, em linguagem clara

{{ handoff_solution.solution_summary }}

## Onde tudo vive

- Repositório: {{ repository.url }} ({{ repository.ownership }})
- Especificações instaladas em: `docs/specs/` — cada spec referencia o artefato de origem
- Governança: Ara Harness profile **{{ handoff_solution.repo_recommendation.harness_profile }}** instalado (specs, checks de PR, Definition of Done)
- Pacote de origem: {{ package.id }} (hashes verificáveis)

## Como a implementação deve acontecer

{{ handoff_solution.implementation_plan.approach }}

Milestones sugeridos:
{{#each handoff_solution.implementation_plan.milestones}}
- {{ this.id }} · {{ this.name }} → {{ this.outcome }}
{{/each}}

Base de escopo: {{ handoff_solution.implementation_plan.scope_basis }} — implementar fora disso requer novo acordo, não improviso.

## Como o aceite funciona

Percorremos juntos cada critério abaixo; nada é subjetivo:

{{#each acceptance_criteria.criteria}}
- [{{ this.status }}] {{ this.statement }} — verificação: {{ this.verification }} (responsável: {{ this.owner }})
{{/each}}

## Riscos que permanecem abertos

{{#each risks.open}}
- {{ this.description }} ({{ this.severity }}) — {{ this.mitigation }}
{{/each}}

## Cuidados operacionais

{{#each handoff_solution.operational_notes}}
- {{ this }}
{{/each}}

<!-- Bloco fixo — não remover -->
Este handoff encerra a fase de especificação ({{ delivery_boundaries.support_window.duration }} de janela para dúvidas sobre o pacote). Implementação assistida, se desejada, é um novo acordo sobre o escopo aprovado.

☉ Surya Labs · {{ house.contact }}
