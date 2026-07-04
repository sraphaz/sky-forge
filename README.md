# Sky-Forge

**Elevar o que está sendo proposto** — camada de funil de inteligência entre sua intenção e a produção de software (Cloud Design, Cursor, repos operáveis por agentes).

Sky-Forge transforma uma ideia em linguagem natural num **pacote de maturidade** completo: negócio → produto → **UX digna** → técnico → sustentação → **elevação e prosperidade humana** — com intake conversacional, **Índices SKY** proprietários e export Cloud Design.

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

No Cursor: converse com **intake-conductor** (regra `sky-intake.mdc`).

Documentação: [AGENTS.md](AGENTS.md) · [SKY_MERIT_INDICES.md](docs/_meta/SKY_MERIT_INDICES.md)

## Estrutura

```
sky-forge/
├── .sky/sessions/            # estado conversacional
├── .agents/                  # intake, ux-design-specialist, sky-elevator…
├── docs/humanity/            # desafios planetários (catálogo GAP)
├── docs/_meta/SKY_MERIT_INDICES.md
└── extensions/sky-cloud-design/   # proprietário
```

## Licença

- **Core**: MIT — [LICENSE](LICENSE)
- **sky-cloud-design**: proprietário — [extensions/sky-cloud-design/LICENSE](extensions/sky-cloud-design/LICENSE)
