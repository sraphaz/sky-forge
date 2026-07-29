---
name: sky-interact
description: >-
  Elicitação interativa Sky-Forge no Cursor (AskQuestion + fallback numerado).
  Use when Sky-Forge needs a user decision, deepen an idea, attach/assess a
  repo, approve a human gate, choose export/privacy options, or present
  numbered choices — especially mid-agent flows that must pause for HITL.
---

# Sky Interact — UI de decisão no Cursor

Pausa o fluxo Sky-Forge e elicita **uma** decisão do usuário com UI nativa
quando possível.

## Quando usar (obrigatório)

Qualquer `decision_point` em [`.agents/interaction-points.yaml`](../../../.agents/interaction-points.yaml), incluindo:

- Chegada / intenção
- Attach / assess de repositório
- Aprofundar lacuna de maturidade
- Confirmar elevação
- Aprovar human gate
- Escopo de export / privacidade de showcase
- ARAH Harness antes de scaffold

Também use quando o usuário pedir “opções”, “o que posso fazer”, ou quando
um agente estiver prestes a escolher sozinho entre caminhos divergentes.

## Protocolo (ordem)

1. **Ler contexto de sessão** (quando existirem): `journey.yaml`, `maturity.yaml` (top gaps incl. `elevation` / `ux_design`), `sky-merits.yaml`, `brief-draft.yaml`, `alternatives.yaml`, `ux-spec.yaml`, e o `point` no catálogo.
2. **Preferir AskQuestion** — se a ferramenta `AskQuestion` estiver disponível neste turno:
   - Uma pergunta por mensagem
   - Até **4** opções (labels curtos)
   - Incluir no máximo um escape freeform: `Outra coisa (vou digitar)`
   - Não listar as mesmas opções em prosa no mesmo turno
3. **Fallback** — se AskQuestion indisponível (modelo/modo):
   - Formato sky-host: maturidade · fase · opções `1)…4)` · “Responda com o número…”
4. **Após a resposta** — resolver **somente** via CLI auditado (não editar YAML à mão):

```powershell
./scripts/sky/sky.ps1 interact -Slug <slug> -Resolve -ChoiceId <id>
```

   Isso grava `choice_id` / `next_suggested_actions` e `human.interaction.answered`. Depois seguir **uma** ação (`routes_to` / `command`).
5. **CLI para abrir pending**:

```powershell
./scripts/sky/sky.ps1 interact -Slug <slug> -PointId <point.id>
./scripts/sky/sky.ps1 interact -Slug <slug> -Clear
```

## Anti-padrões

- Export + publish no mesmo turno
- Vários AskQuestion no mesmo turno
- Prosseguir com side effect sem gate quando o catálogo exige pause
- Inventar >4 opções
- Usar AskQuestion para perguntas abertas longas (aí use prosa)

## Canvas (opcional)

Para resultados densos (ex.: assessment com muitos gaps), pode abrir um
Cursor Canvas **além** da decisão — a escolha acionável continua via
AskQuestion / fallback. Não substitua o HITL só com canvas.

## Referências

- [SKY_INTERACT.md](../../../docs/_meta/SKY_INTERACT.md)
- [USER_JOURNEY.md](../../../docs/_meta/USER_JOURNEY.md)
- [AGENT_AUTONOMY.md](../../../docs/_meta/AGENT_AUTONOMY.md)
