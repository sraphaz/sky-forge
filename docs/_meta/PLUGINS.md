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

- **Consumer:** [EXTERNAL_WORKSPACE_INTEGRATION.md](./EXTERNAL_WORKSPACE_INTEGRATION.md) — importa exports.
- **Host (brownfield):** [HOST_PLUGIN_INTEGRATION.md](./HOST_PLUGIN_INTEGRATION.md) — `sky attach` no repo existente.

## CI

```powershell
./scripts/sky/check-core-agnostic.ps1
```

Core deve passar com `plugins/examples/` ausente.

## Exemplo: Archify (visualização pós-export)

Adapter opcional em `plugins/examples/archify/`. Não é dependência do core.

```powershell
cd plugins/examples/archify
npm install
node scripts/bootstrap-archify.mjs
cd ../../..
./scripts/sky/sky.ps1 visualize -PackagePath examples/sky-forge-packages/surya-workspace-mvp -Renderer archify
```

Ver `plugins/examples/archify/README.md` e ADR-0007.
