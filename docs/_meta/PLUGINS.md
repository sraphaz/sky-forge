# Plugins — Sky-Forge

Plugins são pacotes **externos** que consomem exports — nunca estendem a geração no core.

## Contrato

- Schema: `schemas/sky-forge/plugin.schema.yaml`
- Pasta exemplo (removível): `plugins/examples/`
- README: [plugins/README.md](../../plugins/README.md)

## Garantias do core

1. Contratos de artefato versionados (semver em major)
2. Export determinístico para mesmo input + profile
3. **Nenhum hook de plugin na geração** — só pós-export

## Integração workspace

Ver [EXTERNAL_WORKSPACE_INTEGRATION.md](./EXTERNAL_WORKSPACE_INTEGRATION.md).

## CI

```powershell
./scripts/sky/check-core-agnostic.ps1
```

Core deve passar com `plugins/examples/` ausente.
