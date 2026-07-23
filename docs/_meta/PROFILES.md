# Profiles — Sky-Forge

Profiles declaram **o que gerar**, **em que ordem** e **com quais gates** num export.

## Disponíveis

| ID | Uso |
|----|-----|
| `generic-product` | Produto/feature sem camada comercial |
| `consulting-handoff` | Spec + handoff antes de implementação |
| `startup-mvp` | MVP com dívida explícita |
| `open-source` | Projeto público |
| `internal-corporate` | Projeto interno corporativo |
| `platform-evolution` | Brownfield — avaliar e evoluir plataforma existente (plugin host) |

Arquivos: `profiles/*.yaml` · Schema: `schemas/sky-forge/profile.schema.yaml`

## Validação

```powershell
./scripts/sky/validate-profile.ps1 -Profile consulting-handoff -PackagePath examples/sky-forge-packages/surya-workspace-mvp -FixtureMode
```

## Princípio

O core **não** conhece marcas de consultoria. Consumidores usam plugins externos — ver [PLUGINS.md](./PLUGINS.md).

Detalhe `consulting-handoff`: [CONSULTING_HANDOFF_PROFILE.md](./CONSULTING_HANDOFF_PROFILE.md)
