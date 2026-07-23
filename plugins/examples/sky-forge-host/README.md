# Sky-Forge Host Plugin — exemplo (opcional)

**Não é parte obrigatória do core.** Referência para instalar capacidades Sky-Forge **dentro** de um repo brownfield existente.

## Direção `host` vs `consumer`

| Direção | Onde vive | Fluxo |
|---------|-----------|-------|
| `consumer` | Repo externo (ex.: workspace consultoria) | Importa pacote **exportado** |
| `host` | Repo da plataforma (`integrations/sky-forge/`) | Sky-Forge **opera no repo** via attach |

## Instalação

No Sky-Forge (ou com `SKY_FORGE_ROOT` apontando para o clone):

```powershell
./scripts/sky/sky.ps1 attach -WorkspacePath C:\repos\minha-plataforma
# ou slug explícito:
./scripts/sky/sky.ps1 attach -Slug minha-plataforma -WorkspacePath C:\repos\minha-plataforma
```

No repo da plataforma, depois:

```powershell
./scripts/sky.ps1 assess      # baseline automático
./scripts/sky.ps1 status        # maturidade + SKY
./scripts/sky.ps1 pull-spec     # após export no forge
```

## Profile

`platform-evolution` — assessment → spec → roadmap → implementação incremental.

## Arquivos

- `plugin.yaml` — declaração host + catálogo de serviços
- `services.yaml` — fases, agentes, fontes de evidência
- `templates/` — regra Cursor e stub AGENTS

Documentação: [docs/_meta/HOST_PLUGIN_INTEGRATION.md](../../docs/_meta/HOST_PLUGIN_INTEGRATION.md)
