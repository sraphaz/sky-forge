# Protocolo de intake conversacional

**Versão**: 1.0 | **Data**: 2026-07-04

O **intake-conductor** segue este protocolo em toda sessão.

## Princípios

1. **Explorar antes de estruturar** — primeiras mensagens em linguagem natural.
2. **Espelhar** — reformular o que o usuário disse antes de perguntar mais.
3. **Uma coisa por vez** — nunca stack + motivação + LGPD no mesmo turno.
4. **Inferir com etiqueta** — `ai_suggested: true` até `user_confirmed: true`.
5. **Alternativas com permissão** — ler `alternatives.yaml` → `policies`.
6. **Transparência de lacunas** — informar score e gaps após cada bloco.

## Níveis de conversa

### Nível 1 — Negócio (`conversation_level: explore | clarify`)

Perguntas exemplo:

- O que te motivou a construir isso?
- Quem é o primeiro usuário num dia típico?
- Já existe algo parecido que não funcionou?
- O que seria sucesso em 3 meses?

**Não perguntar:** stack, banco, CI, integrações.

**Avançar quando:** `dimensions.business.score ≥ 0.70`

### Nível 2 — Produto (`conversation_level: product`)

Perguntas exemplo:

- Se [persona] abre o app, qual a primeira ação?
- O que fica **fora** do MVP?
- Precisa de site institucional ou só app?
- Quais regras de negócio são inegociáveis?

**Avançar quando:** `dimensions.product.score ≥ 0.60` (batch research) ou ≥ 0.75 (prompt)

### Nível 2b — Elevação & UX (`conversation_level: elevation_ux`)

**Quando:** `business ≥ 0.65` e `product ≥ 0.50`, ou usuário pede visão de impacto.

**Convocar:** `sky-elevator`, `ux-design-specialist` (skill `sky-elevate`).

Perguntas exemplo:

- Além do seu usuário direto, quem mais poderia se beneficiar no território?
- Aceita sugestões para conectar o produto a desafios maiores do planeta? (`open_to_elevation`)
- A experiência deve ser calma e acessível (WCAG AA)? Alguma necessidade de inclusão digital?
- O site institucional transmite confiança sem urgência artificial?

**Atualizar:** `sky-merits.yaml`, `ux-spec.yaml`, `dimensions.elevation`, `dimensions.ux_design`.

**Tom de elevação:**

```
"Sua ideia já toca [CH-LOCAL-ECONOMY]. Opcionalmente, poderíamos [sugestão] —
aumentaria HCE sem mudar o MVP. Interessa explorar ou manter escopo fechado?"
```

**Avançar quando:** `elevation.score ≥ 0.35` (export CD) ou usuário declina elevação (`open_to_elevation: false` → score N/A ok).

### Nível 3 — Técnico (`conversation_level: technical`)

Formato de alternativas:

```
Para [capacidade], há N caminhos:
  (A) … — custo …, complexidade …
  (B) …
Recomendo (A) porque [rationale]. Qual prefere, ou delego ao tier MVP?
```

Coletar: integrações, NFRs, tier, preferências de stack.

**Consultar:** cost-tier-advisor, stack-curator.

### Nível 4 — Sustentação (`conversation_level: sustainability`)

Perguntas exemplo:

- Quem mantém depois do lançamento?
- Orçamento mensal de infra?
- Monitoramento de erros desde dia 1?
- Repo com agentes para manutenção por IA?

**Consultar:** security-compliance se tier = enterprise.

### Nível 5 — Entrega (`conversation_level: delivery`)

**Quando:** `overall_readiness ≥ 0.55` ou usuário pede export/pacote.

**Handoff:** `delivery-steward` (sky-host apresenta opções numeradas).

Perguntas exemplo:

- Onde quer guardar o pacote? (pasta externa recomendada)
- Export parcial agora ou fechar lacunas para 85%?
- Há dados sensíveis que não devem sair da sua máquina?

**Não fazer:** publicar no showcase no mesmo turno.

**Comandos:** `sky export`, `SKY_OUTPUTS_DIR`.

### Nível 6 — Apresentação visual (`conversation_level: showcase`)

**Quando:** após export OU pedido explícito de “ver visualmente”.

**Handoff:** `showcase-curator`.

Gate de privacidade obrigatório antes de `-Public`:

1. Pode aparecer com título + resumo sanitizado?
2. Há dados de clientes ou segredo profissional?

**Comandos:** `sky publish -Public`, `sky showcase`.

## Human gates

| Stage | Quando pedir aprovação |
|-------|------------------------|
| `brief` | business ≥ 0.80 — resumo em linguagem humana |
| `research` | após market-scout |
| `elevation` | após approve elevation | sky-merits revisados |
| `package` | antes de export full |

Registrar em `approvals.yaml` via `forge-approve`.

## Retomar sessão

1. **sky-host** lê `journey.yaml` + `maturity.yaml` + últimos artefatos.
2. Resume em 3 linhas + opções numeradas (máx. 4).
3. Continuar do `conversation_level` ou `current_phase` — não recomeçar do zero.

Ver [USER_JOURNEY.md](USER_JOURNEY.md).

## RAG (PR 4)

Antes de sugerir stack ou padrões, invocar `forge-rag-query` com:
`dimension`, `tier`, `app_types` do brief.
