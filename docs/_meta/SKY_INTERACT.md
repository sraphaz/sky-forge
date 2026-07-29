# Interatividade HITL — Sky-Forge no Cursor

**Versão**: 1.0 | **Data**: 2026-07-28

Como o Sky-Forge **pausa e pergunta** ao usuário dentro do Cursor — com UI
nativa (`AskQuestion`) quando disponível — mesmo quando o fluxo foi iniciado
por um agente (`attach`, `assess`, intake, export…).

## Objetivo

O usuário não deve adivinhar o próximo passo **nem** digitar “1/2/3” se o
Cursor puder mostrar opções clicáveis. A jornada continua a mesma
([USER_JOURNEY.md](USER_JOURNEY.md)); muda o **canal** da elicitation.

```
Agente detecta decision_point
        │
        ▼
┌───────────────────┐     disponível      ┌────────────────────┐
│ Catálogo          │ ───────────────────▶│ AskQuestion (UI)   │
│ interaction-points│                     └─────────┬──────────┘
└─────────┬─────────┘                               │
          │ indisponível                            ▼
          ▼                               Usuário escolhe
┌───────────────────┐                               │
│ Fallback numerado │◀──────────────────────────────┘
│ (sky-host chat)   │
└─────────┬─────────┘
          ▼
  journey.pending_interaction → resolved
  audit: human.interaction.answered
  handoff / comando (uma ação)
```

## Fonte de verdade

| Artefato | Função |
|----------|--------|
| [`.agents/interaction-points.yaml`](../../.agents/interaction-points.yaml) | Catálogo de pontos + prompts + opções |
| [`.cursor/skills/sky-interact/SKILL.md`](../../.cursor/skills/sky-interact/SKILL.md) | Protocolo para o agente Cursor |
| `journey.yaml` → `pending_interaction` | Estado da pergunta aberta / resolvida |
| [`interaction-turn.schema.yaml`](../schemas/interaction-turn.schema.yaml) | Contrato do bloco |
| `./scripts/sky/sky.ps1 interact` | Grava / limpa pending + imprime payload |

## Regras

1. **Uma decisão por turno** — alinhado ao sky-host.
2. **Máximo 4 opções** (+ no máximo um escape “Outra coisa…”).
3. **AskQuestion primeiro** — se a ferramenta existir no turno; senão fallback.
4. **Não empilhar** export + publish, nem múltiplos gates.
5. **Privacidade por padrão** — `showcase.privacy` antes de `-Public`.
6. **Auditoria** — `human.interaction.requested` / `human.interaction.answered`.

## CLI

```powershell
# Grava pending_interaction a partir do catálogo e imprime JSON para o agente
./scripts/sky/sky.ps1 interact -Slug minha-ideia -PointId arrival.intent

# Pós-assess (também chamado automaticamente por assess-platform.ps1)
./scripts/sky/sky.ps1 interact -Slug minha-plataforma -PointId assess.next_action

# Limpar pergunta pendente
./scripts/sky/sky.ps1 interact -Slug minha-ideia -Clear

# Registrar escolha (após resposta do usuário)
./scripts/sky/sky.ps1 interact -Slug minha-ideia -Resolve -ChoiceId deepen_top_gap
```

## Integrações automáticas

| Fluxo | PointId gravado |
|-------|-----------------|
| `sky attach` (sucesso) | `brownfield.after_attach` (default; use `-Assess` para rodar assessment na hora) |
| `sky assess` (sucesso) | `assess.next_action` |
| `sky new-session` / intake | `arrival.intent` (em `next_suggested_actions` + pending opcional) |

## Limitação do Cursor

`AskQuestion` depende do **modelo/modo**. Se indisponível, o agente **deve**
cair no fallback numerado — não bloquear o fluxo nem fingir que perguntou.

## Relação com human gates

Interação ≠ aprovação formal. Gates (`brief`, `package`, `public_showcase`…)
continuam via `sky approve`. O ponto `gate.approve_stage` **elicita** se o
usuário quer aprovar agora; a aprovação efetiva permanece no CLI/skill
`sky-approve`.
