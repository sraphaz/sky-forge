# Sky-Forge

**Elevar o que está sendo proposto** — camada de funil de inteligência entre sua intenção e a produção de software (Cloud Design, Cursor, repos operáveis por agentes).

Sky-Forge transforma uma ideia em linguagem natural num **pacote de maturidade** completo: negócio → produto → **UX digna** → técnico → sustentação → **elevação e prosperidade humana** — com intake conversacional, **Índices SKY abertos e versionados** e export Cloud Design.

A régua é aberta: rubricas, evidências e governança em [SKY_INDICES_METHOD.md](docs/_meta/SKY_INDICES_METHOD.md) (espec CC BY-SA); qualquer terceiro reproduz um score com o harness. O que se comercializa é a execução — agentes completos, export Cloud Design, white-label.

---

## Propósito Sky

Além de especificar aplicativos, o Sky-Forge **conecta a solução da pessoa** a problemas que o planeta precisa endereçar — sugerindo expansão de consciência e benefício coletivo **sempre com sua permissão**, medido pelos índices SPI, HCE, GAP, CWB e UXD.

| Entrada | Saída |
|---------|-------|
| Conversa dinâmica | `brief.yaml`, RF/NFR, integrações, `sky-merits.yaml` |
| Especialista UX | `ux-spec.yaml`, índice UXD |
| Sky-elevator | Conexões humanidade, sugestões de elevação |
| Pipeline maduro | Arquitetura, roadmap, prompts, scaffold, `.dc.html` |

## Início rápido

```powershell
./scripts/sky/sky.ps1 intake -Slug minha-ideia
./scripts/sky/sky.ps1 elevate -Slug minha-ideia   # após brief inicial
./scripts/sky/sky.ps1 export -Slug minha-ideia -Completeness partial
```

No Cursor: converse com **sky-host** (regra `sky-host.mdc`) ou **intake-conductor** (`sky-intake.mdc`).

Documentação: [AGENTS.md](AGENTS.md) · [SKY_MERIT_INDICES.md](docs/_meta/SKY_MERIT_INDICES.md) · [SKY_INDICES_METHOD.md](docs/_meta/SKY_INDICES_METHOD.md)

## Estrutura

```
sky-forge/
├── .sky/sessions/            # estado conversacional (local)
├── showcase/registry/        # previews públicos para o site
├── apps/showcase/            # site visual (Astro, MIT)
├── sky.config.yaml           # outputs externos + registry
├── .agents/                  # intake, ux-design-specialist, sky-elevator…
├── docs/humanity/            # desafios planetários (catálogo GAP)
├── docs/_meta/SKY_MERIT_INDICES.md
└── extensions/sky-cloud-design/   # proprietário
```

## Outputs fora do repo + showcase visual

Pacotes completos **não precisam** ficar no repositório open source:

```powershell
$env:SKY_OUTPUTS_DIR = "C:\caminho\seus-projetos"
./scripts/sky/sky.ps1 export -Slug meu-projeto -Completeness partial
./scripts/sky/sky.ps1 publish -Slug meu-projeto -Public   # preview sanitizado
./scripts/sky/sky.ps1 showcase                            # site local
```

Detalhes: [OUTPUTS_AND_SHOWCASE.md](docs/_meta/OUTPUTS_AND_SHOWCASE.md) · [USER_JOURNEY.md](docs/_meta/USER_JOURNEY.md)

### Agentes de experiência

| Agente | Papel |
|--------|-------|
| **sky-host** | Anfitrião — progresso, opções, roteamento |
| **delivery-steward** | Export e pasta externa |
| **showcase-curator** | Galeria visual (opt-in) |

## Licença

- **Core**: MIT — [LICENSE](LICENSE)
- **sky-cloud-design**: proprietário — [extensions/sky-cloud-design/LICENSE](extensions/sky-cloud-design/LICENSE)
