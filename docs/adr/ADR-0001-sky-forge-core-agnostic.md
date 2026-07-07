# ADR-0001 — Sky-Forge Core permanece agnóstico de consumidor

> Status: aceita · 2026-07-06 · Repo destino: `sky-forge/docs/adr/`

## Contexto
A Surya Labs será a primeira consumidora intensiva do Sky-Forge. A tentação natural é embutir conceitos da casa (propostas, shares, ritos) no core. Isso destruiria o valor do Sky-Forge como ferramenta genérica e criaria dependência circular entre os projetos.

## Decisão
O core do Sky-Forge não conhece nenhum consumidor. Extensão acontece por **profiles** (o que gerar, com quais gates) e **plugins consumidores** (que operam sobre o pacote exportado, nunca dentro da geração). Um exemplo de plugin pode viver em `plugins/examples/`, opcional e removível. Regra verificável: **o core compila e passa testes com `plugins/examples/` deletado** (job de CI dedicado); nenhuma string "surya" fora de `plugins/examples/`.

## Consequências
- (+) Sky-Forge utilizável por qualquer consultoria/estúdio; potencial open-source limpo.
- (+) O plugin Surya evolui no repo do Workspace, no seu próprio ritmo.
- (−) Necessidades da casa chegam ao core como generalização (mais lento, mais desenho).
- Follow-up: teste de CI "core sem examples" (plano de evolução, S4).

## Alternativas consideradas
Fork da Surya (dois motores para manter — rejeitada); hooks de plugin dentro da geração (acoplamento invisível e ordem de execução opaca — rejeitada).
