# Sky-Forge Host Plugin — integração brownfield

> Versão 0.1 · 2026-07-07  
> Profile: `platform-evolution` · Direção plugin: `host`

---

## Problema

Plataformas existentes (brownfield) precisam de **avaliação estruturada** e **spec de evolução** sem migrar o fluxo de trabalho para outro repositório. O modelo `consumer` (importar exports) e o `sky link` pós-export assumem que a spec nasce no forge antes do código.

O **host plugin** inverte a entrada: o Sky-Forge **entra no repo da plataforma** e expõe serviços de maturidade, elevação e arquitetura in loco.

## Modelo de duas direções

```
┌─────────────────────────────────────────────────────────────────┐
│  direction: consumer (adapter externo)                          │
│  sky export → pacote → workspace importa                        │
│  Ex.: surya-labs-workspace / consulting-handoff                 │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  direction: host (este documento)                               │
│  repo plataforma + sky attach → assess → evolve → pull-spec     │
│  Ex.: sky-forge-host / platform-evolution                       │
└─────────────────────────────────────────────────────────────────┘
```

Princípio inalterado: **nenhum hook de plugin na geração do core**. O host plugin só instala integração, CLI delegada e regras Cursor — a sessão e os gates continuam no Sky-Forge.

## Instalação

```powershell
# No clone do Sky-Forge
./scripts/sky/sky.ps1 attach -WorkspacePath C:\repos\minha-plataforma

# Slug explícito (senão deriva do nome da pasta)
./scripts/sky/sky.ps1 attach -Slug minha-plataforma -WorkspacePath C:\repos\minha-plataforma
```

O comando:

1. Cria sessão `.sky/sessions/{slug}/` (se não existir) com `intake_mode: brownfield_host`
2. Grava `profile.yaml` → `platform-evolution`
3. Copia `integrations/sky-forge/` (plugin + services)
4. Instala `.cursor/rules/sky-host-plugin.mdc` e wrapper `scripts/sky.ps1`
5. Cria `.sky/link.yaml` com `mode: host`
6. Executa **assessment** inicial do repo

## Estrutura no repo da plataforma

```
minha-plataforma/
├── .sky/
│   ├── link.yaml              # slug, forge_root, mode: host
│   └── plugin.yaml            # declaração host
├── integrations/sky-forge/
│   ├── plugin.yaml
│   ├── services.yaml
│   ├── platform-assessment.yaml   # cópia após assess
│   └── README.md
├── scripts/sky.ps1            # CLI delegada (assess, status, architect, …)
├── .cursor/rules/sky-host-plugin.mdc
├── AGENTS.sky.md              # complemento (se AGENTS.md já existir)
└── spec/                      # após pull-spec / export
```

## Serviços expostos

| CLI (no app) | Delegação | Fase profile |
|--------------|-----------|--------------|
| `assess` | Varre repo → `platform-assessment.yaml` | assess |
| `status` | Maturidade + SKY | assess |
| `elevate` | Índices + UX digna | benchmark |
| `architect` | Ciclo C4 brownfield | architecture |
| `pull-spec` | Sync `spec/` | evolution |
| `export -ForAI` | Contexto sanitizado | evolution |

Export completo, intake conversacional longo e `publish -Public` permanecem **no repositório Sky-Forge** (autonomia e privacidade).

## Profile `platform-evolution`

Estágios:

1. **assess** — baseline (`platform-assessment`, brief) → gate `baseline_confirmed`
2. **benchmark** — mercado (opcional)
3. **requirements / ux / architecture** — alvo de evolução
4. **evolution** — `evolution-roadmap` + critérios → gate `evolution_approved`

Artefatos-chave além do `generic-product`:

- `platform-assessment.yaml` — sinais do repo (stack, CI, testes, gaps)
- `evolution-roadmap.yaml` — fases incrementais com done verificável

## Fluxo operacional

```
attach (forge)
  → assess automático
  → intake-conductor confirma baseline (gate baseline_confirmed)
  → sky-elevator + ux-design-specialist (opcional)
  → architect (C4 alvo)
  → export no forge (profile platform-evolution)
  → pull-spec no app
  → implementar por fase do roadmap
  → reassess após mudanças grandes
```

## Assessment — o que é detectado

Heurística leve (sem AST):

- Stack: `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, …
- CI: `.github/workflows`, GitLab CI, Azure Pipelines
- Docs: `README.md`, `docs/`, `AGENTS.md`
- Testes: contagem de arquivos `*test*` / `*spec.*`
- Git: commit HEAD atual como baseline

Scores iniciais alimentam `maturity.yaml` (dimensões technical/product). **Não substituem** conversa de intake — são ponto de partida com `ai_suggested: true`.

## Compatibilidade com `sky link`

| | `sky link` | `sky attach` |
|---|-----------|--------------|
| Momento | Após export | Brownfield, sem export prévio |
| mode | `linked` (default) | `host` |
| Profile | qualquer | `platform-evolution` |
| Wrapper | scaffold básico | scaffold-host (+ assess, architect) |
| Assessment | não | sim |

Religar: `attach -Force` ou `link -Force` após remover `.sky/link.yaml`.

## Referências

- Plugin exemplo: [plugins/examples/sky-forge-host/](../../plugins/examples/sky-forge-host/)
- Schema: [schemas/sky-forge/plugin.schema.yaml](../../schemas/sky-forge/plugin.schema.yaml)
- Profile: [profiles/platform-evolution.yaml](../../profiles/platform-evolution.yaml)
- Link bidirecional: [OUTPUTS_AND_SHOWCASE.md](./OUTPUTS_AND_SHOWCASE.md) § Repositório da aplicação
- Consumer adapter: [EXTERNAL_WORKSPACE_INTEGRATION.md](./EXTERNAL_WORKSPACE_INTEGRATION.md)

## Pendências (roadmap)

- ~~Schema JSON formal para `platform-assessment.yaml`~~ → `schemas/sky-forge/platform-assessment.schema.yaml`
- ~~`evolution-roadmap.yaml` template~~ → `templates/sessions/platform-evolution/` + `sky seed-roadmap`
- Tarball/URL como entrada de attach (hoje: pasta local)
- `npx sky attach` multiplataforma (A-08)
