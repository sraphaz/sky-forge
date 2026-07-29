---
name: sky-experience
description: >-
  Experiência Sky-Forge no Cursor — sky-host, export/showcase, retomada de
  sessão e elicitation HITL (AskQuestion). Use when the user needs the next
  step, export, showcase, resume, or interactive options mid-flow.
---

# Sky Experience — Cursor skill

Use quando o usuário interage com Sky-Forge sem saber o próximo passo, quer export/showcase, ou retoma sessão.

## Agentes

| Agente | Quando |
|--------|--------|
| **sky-host** | Face da experiência — sempre começar aqui |
| **delivery-steward** | Export, `SKY_OUTPUTS_DIR`, pacote privado |
| **showcase-curator** | Galeria visual, `publish -Public` (opt-in) |

## Antes de responder

1. Contrato de sessão (quando existirem): `journey.yaml`, `maturity.yaml`, `sky-merits.yaml`, `brief-draft.yaml`, `alternatives.yaml`, `ux-spec.yaml`
2. Se `pending_interaction.status: pending` → carregar skill **sky-interact** e elicitar (AskQuestion / fallback)
3. [USER_JOURNEY.md](../../../docs/_meta/USER_JOURNEY.md) · [SKY_INTERACT.md](../../../docs/_meta/SKY_INTERACT.md)

## Formato (sky-host)

- Maturidade % + fase humana
- **AskQuestion** para decisões de opções fixas (preferido)
- Fallback: máximo 4 opções numeradas
- Uma decisão por turno
- Privacidade por padrão

## Comandos

```powershell
./scripts/sky/sky.ps1 status -Slug <slug>
./scripts/sky/sky.ps1 interact -Slug <slug> -PointId arrival.intent
./scripts/sky/sky.ps1 export -Slug <slug> -Completeness partial
./scripts/sky/sky.ps1 publish -Slug <slug> -Public
./scripts/sky/sky.ps1 showcase
```

## Regras

- delivery-steward **não** publica no showcase
- showcase-curator **só** `-Public` com consentimento explícito (`showcase.privacy`)
- Atualizar `journey.yaml` em cada handoff / resolução de interação
