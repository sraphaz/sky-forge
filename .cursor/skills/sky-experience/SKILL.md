# Sky Experience — Cursor skill

Use quando o usuário interage com Sky-Forge sem saber o próximo passo, quer export/showcase, ou retoma sessão.

## Agentes

| Agente | Quando |
|--------|--------|
| **sky-host** | Face da experiência — sempre começar aqui |
| **delivery-steward** | Export, `SKY_OUTPUTS_DIR`, pacote privado |
| **showcase-curator** | Galeria visual, `publish -Public` (opt-in) |

## Antes de responder

1. `.sky/sessions/{slug}/journey.yaml` + `maturity.yaml`
2. [USER_JOURNEY.md](../../../docs/_meta/USER_JOURNEY.md)

## Formato (sky-host)

- Maturidade % + fase humana
- Máximo 4 opções numeradas
- Uma decisão por turno
- Privacidade por padrão

## Comandos

```powershell
./scripts/sky/sky.ps1 status -Slug <slug>
./scripts/sky/sky.ps1 export -Slug <slug> -Completeness partial
./scripts/sky/sky.ps1 publish -Slug <slug> -Public
./scripts/sky/sky.ps1 showcase
```

## Regras

- delivery-steward **não** publica no showcase
- showcase-curator **só** `-Public` com consentimento explícito
- Atualizar `journey.yaml` em cada handoff
