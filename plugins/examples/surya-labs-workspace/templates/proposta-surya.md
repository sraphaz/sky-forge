<!-- TEMPLATE do plugin — renderizado pelo adapter com dados do proposal-scope + delivery-boundaries.
     Placeholders: {{ }} mustache. Tom da casa: claro, técnico, sem hype. Sentence case. -->

PROPOSTA · SURYA LABS
{{ proposal.id }} · v{{ proposal.version }} · {{ date }}

# {{ demand.title }}

{{ client.name }} — esta proposta nasce do processo de maturação que percorremos juntos. Tudo que está aqui deriva de artefatos versionados que você pode auditar; nada é implícito.

## O que entendemos

{{ consulting_brief.problem.statement }}

Critérios de sucesso que você nomeou:
{{#each consulting_brief.success_criteria}}
- {{ this }}
{{/each}}

## O que propomos

{{ proposal_scope.summary }}

### Entregáveis

{{#each proposal_scope.deliverables}}
**{{ this.name }}** — {{ this.description }}
Aceite: critério {{ this.acceptance_ref }} (verificação objetiva, listada no anexo de aceite).
{{/each}}

### Fases

{{#each proposal_scope.phases}}
{{ this.id }} · {{ this.name }} — {{ this.duration_estimate }}
{{/each}}

## O que NÃO está incluído

Dizemos isto com o mesmo cuidado com que dizemos o que entra:

{{#each proposal_scope.out_of_scope}}
- {{ this }}
{{/each}}

## Fronteiras da entrega

- Janela de suporte: {{ delivery_boundaries.support_window.duration }} — cobre {{ delivery_boundaries.support_window.covers }}.
- A entrega se considera feita quando: {{#each delivery_boundaries.handover_conditions}}{{ this }}; {{/each}}
- Depois da entrega: {{ delivery_boundaries.after_handover }}
- Mudanças de escopo: {{ proposal_scope.revision_policy }}

## O que precisamos de você

{{#each proposal_scope.prerequisites}}
- {{ this }}
{{/each}}

## Condições

Valor: {{ proposal.value_total }} ({{ proposal.value_conditions }})
Validade desta proposta: {{ proposal.valid_until }}

<!-- Bloco fixo — não remover -->
Notas de integridade: os artefatos desta proposta têm hash registrado ({{ package.id }}). Temas jurídicos, fiscais e contábeis identificados durante a maturação estão listados no anexo de validação profissional e serão tratados com profissionais habilitados — nenhuma afirmação nossa substitui esse parecer.

Aceite: registrado por escrito (assinatura ou aceite eletrônico), com referência ao hash deste documento.

☉ Surya Labs · {{ house.contact }}
