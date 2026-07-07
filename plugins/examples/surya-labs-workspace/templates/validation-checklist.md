<!-- TEMPLATE do plugin — checklist de validação profissional para envio ao advisor externo.
     Fonte: validation-checklist da demanda. A resposta é do profissional, nunca da casa/IA. -->

VALIDAÇÃO PROFISSIONAL · SURYA LABS
{{ checklist.id }} · {{ demand.id }} · {{ date }}

# Itens para validação — {{ demand.title }}

Prezado(a) {{ advisor.name }},

Durante a maturação desta demanda identificamos os pontos abaixo que exigem parecer de profissional habilitado. Pedimos que trate cada item indicando: viabilidade, forma recomendada, riscos e o que devemos ajustar **antes** da etapa indicada.

{{#each checklist.items}}
## {{ this.id }} — {{ this.topic }}

- **Por que importa:** {{ this.why_it_matters }}
- **Profissional:** {{ this.professional }}
- **Precisamos da resposta antes de:** {{ this.before_stage }}
- **Bloqueante para a casa:** {{#if this.blocking}}sim — esta etapa fica travada no nosso sistema até o encaminhamento{{else}}não — mas será considerado na decisão{{/if}}
- **Contexto anexo:** {{ this.context_refs }}

Resposta do profissional:

_(espaço para parecer — será arquivado como `resolved_ref` deste item)_

---
{{/each}}

<!-- Bloco fixo — não remover -->
Notas:
- Este documento lista dúvidas; não contém posição jurídica/fiscal/contábil da Surya Labs.
- O parecer retornado será arquivado íntegro e referenciado no item correspondente (`resolved_ref`).
- Itens marcados como bloqueantes travam automaticamente as etapas correspondentes no nosso sistema até o encaminhamento.

☉ Surya Labs · {{ house.contact }}
