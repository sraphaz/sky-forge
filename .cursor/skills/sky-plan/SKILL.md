# Sky Plan — Cursor skill (step-files)

Pipeline batch pós-brief com **steps carregados sob demanda** (padrão BMAD step-file).

## Como usar

1. Carregar **apenas o step atual** — não o pipeline inteiro
2. Preferir **contexto fresco** entre steps (`fresh_context: recommended`)
3. Avançar só após outputs do step anterior existirem

## Ordem dos steps

| Step | Skill | Agente |
|------|-------|--------|
| `01-maturity-gate` | sky-plan | — |
| `02-c4-model` | sky-c4-model | c4-modeler |
| `03-journey-sequences` | sky-journey-sequences | journey-sequence-modeler |
| `04-agent-architecture` | sky-agent-architecture | solutions-architect |
| `05-test-strategy` | sky-test-architecture | test-architect (consult) |
| `06-clean-craft` | sky-clean-craft | clean-craft-advisor (consult) |
| `07-export` | sky-export | delivery-steward |

Arquivos em `.skills/sky-plan/steps/*.step.yaml`.

## Comando

```powershell
./scripts/sky/sky.ps1 architect -Slug <slug> -Force
# ou step a step no Cursor — ler um .step.yaml por turno
```

## Economia de tokens

- Cada step declara `read:` mínimo — não reler o pacote inteiro
- Step 04 só roda se épico E3/E4 ou containers Agent/Copilot
- Consultas (05, 06) não disparam side effects
