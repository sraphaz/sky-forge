# Outputs externos e Showcase visual

**Versão**: 1.0 | **Data**: 2026-07-04

## Modelo open source

O **Sky-Forge** (MIT) separa três camadas:

| Camada | Onde fica | Versionado no Git? |
|--------|-----------|-------------------|
| **Core** | Repo `sky-forge` | Sim — código, agentes, docs |
| **Pacotes completos** | Pasta externa configurável | Não — briefs, Cloud Design, scaffold |
| **Previews públicos** | `showcase/registry/` | Sim — só metadados sanitizados |

Assim qualquer pessoa pode usar o funil sem expor projetos de clientes no repositório público.

## Configurar outputs fora do repo

### 1. Variável de ambiente (recomendado)

```powershell
$env:SKY_OUTPUTS_DIR = "C:\Users\rapha\sky-projects"
./scripts/sky/sky.ps1 export -Slug iautos -Completeness partial
```

### 2. Arquivo `sky.config.yaml`

```yaml
outputs:
  dir: C:/Users/rapha/sky-projects   # absoluto ou relativo à raiz
```

Pacotes ficam em `{outputs.dir}/{slug}/` com `PACKAGE_MANIFEST.yaml`, YAMLs, scaffold, cloud-design.

## Publicar preview visual

```powershell
./scripts/sky/sky.ps1 publish -Slug iautos -Public
```

Gera:

- `showcase/registry/iautos.preview.json` — dados para o site
- `showcase/registry/index.json` — catálogo

Só o que você marca com `-Public` aparece no showcase. Brief completo e `.dc.html` proprietários **não** entram no registry.

## Ver o site localmente

```powershell
./scripts/sky/sky.ps1 showcase
# http://localhost:4321
```

Ou:

```powershell
cd apps/showcase
pnpm install
pnpm dev
```

## Deploy (GitHub Pages)

O site institucional (`apps/showcase`) já está configurado para project Pages:

- `site`: `https://sraphaz.github.io`
- `base`: `/sky-forge`
- URL esperada: `https://sraphaz.github.io/sky-forge/`

### Automático (recomendado)

Workflow [`.github/workflows/showcase-pages.yml`](../../.github/workflows/showcase-pages.yml):

- Dispara em push em `main` quando mudam `apps/showcase/**` ou `showcase/registry/**`
- Também via **Actions → Deploy Showcase → Run workflow**
- Build Astro estático → artifact → `actions/deploy-pages`

No GitHub: **Settings → Pages → Source = GitHub Actions** (uma vez).

Fonte de design: `docs/design/high-premium/*.dc.html` (Claude Design). O que sobe no Pages é o Astro portado — **não** os `.dc.html` proprietários.

### Manual

```powershell
cd apps/showcase
pnpm install
pnpm exec astro build
# dist/ → GitHub Pages em /sky-forge
```

O site lê `showcase/registry/*.json` — inclui `{slug}.agents.json` (auditoria sanitizada).

### Snapshot de agentes (UI)

Gerado por `publish-agents-view.ps1` (automático em `sky publish`):

- Gates humanos e status
- Coreografia resolvida (agentes, skills)
- Trilha de eventos (últimos 30, sem paths absolutos)
- Contadores ok / blocked

Páginas: `/projects/{slug}/agentes/` e `/agentes/`

## Fluxo recomendado

```
intake → export (pasta externa) → publish -Public (opcional) → showcase
```

1. **Intake** conversacional — estado em `.sky/sessions/` (local)
2. **Export** — pacote completo em `SKY_OUTPUTS_DIR`
3. **Publish** — opt-in de preview sanitizado no repo
4. **Showcase** — galeria visual para equipe, investidores ou comunidade

## O que o showcase mostra

- SKY Score e maturidade (6 dimensões)
- Índices SPI, HCE, GAP, CWB, UXD
- Roadmap por fases
- Pipeline desbloqueado
- Lista de artefatos (sem conteúdo sensível)

## Repositório da aplicação (sky link)

Depois do export, ligue o repo onde o código será escrito:

```powershell
# No Sky-Forge (ou a partir do app com caminho absoluto)
./scripts/sky/sky.ps1 link -Slug iautos -WorkspacePath C:\repos\iautos -PullSpec
```

Isso cria:

| Onde | Arquivo | Função |
|------|---------|--------|
| App | `.sky/link.yaml` | Aponta para o forge + slug |
| App | `scripts/sky.ps1` | Wrapper CLI (status, pull-spec, export-for-ai) |
| App | `spec/` | Spec sincronizada (stories, architecture, brief) |
| Sessão | `.sky/sessions/{slug}/git.yaml` | `workspace_path` do app |

### Comandos no repo da aplicação

```powershell
cd C:\repos\iautos
./scripts/sky.ps1 status
./scripts/sky.ps1 pull-spec          # após re-export no forge
./scripts/sky.ps1 export -ForAI -Scope spec
```

Export completo, intake e `publish -Public` permanecem no Sky-Forge (gates de autonomia e privacidade).

### Sync automático (`after_export`)

```powershell
./scripts/sky/sky.ps1 link-sync -Slug iautos -SyncMode after_export
```

Após cada `export`, o hook `sync-linked-workspace.ps1` roda `pull-spec` no app ligado.

### Fluxo recomendado pós-export

```
export (forge) → link + pull-spec (app) → implementar (app) → pull-spec (sync)
```

Horizonte: `npx sky` multiplataforma (roadmap A-08) substituirá o wrapper PowerShell.

## Cloud Design e licença

Arquivos `.dc.html` da extensão proprietária permanecem no pacote externo. O showcase open source **não redistribui** esses templates — apenas indica que existem. Para preview visual rico, hospede screenshots ou HTML estático em URL externa (campo futuro `viewer_urls` no preview).

## Registry externo (opcional)

```yaml
registry:
  external_dir: C:/Users/rapha/sky-registry
```

Ou `$env:SKY_REGISTRY_DIR` — útil se o catálogo também não deve ir para o repo público.
