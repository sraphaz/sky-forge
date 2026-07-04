# AGENTS.md — Sky-Forge

**Versão**: 1.1  
**Data**: 2026-07-04  
**Repo**: `sky-forge`

Manual de operação. Sky-Forge **eleva** propostas: especifica software e conecta, quando permitido, à prosperidade humana no planeta.

---

## Princípios

1. **Intake conversacional primeiro** — entrada em linguagem natural.
2. **Maturidade por dimensão** — negócio, produto, **ux_design**, técnico, sustentação, **elevation**.
3. **Elevação com permissão** — sky-elevator sugere; criador confirma (`policies.open_to_elevation`).
4. **UX digna** — ux-design-specialist: WCAG AA, mobile-first, baixa excitação, design tokens.
5. **Índices SKY** — SPI, HCE, GAP, CWB, UXD — ver [SKY_MERIT_INDICES.md](docs/_meta/SKY_MERIT_INDICES.md).
6. **Pacote verificável** — harness antes de export.

## Fluxo

```
Intenção → intake-conductor (conversa)
    → sky-elevator + ux-design-specialist (elevação & UX)
    → market-scout / architect (batch)
    → prompt-assembler → sky-export (+ Cloud Design)
    → learn-from-outcome
```

## Catálogo de agentes

### Operacionais

| ID | Função |
|----|--------|
| `orchestrator` | Roteamento |
| `intake-conductor` | Conversa; maturity; coreografia de lacunas |
| `ux-design-specialist` | **UX spec, acessibilidade, UXD** |
| `market-scout` | Pesquisa mercado/stack |
| `solutions-architect` | C4, domínios, ADRs |
| `prompt-assembler` | Prompts avançados + export |
| `repo-scaffolder` | Scaffold `AGENTS.md` do app novo |

### Domínio (consultivos)

| ID | Função |
|----|--------|
| `sky-elevator` | **Índices SKY, prosperidade humana, expansão de consciência** |
| `cost-tier-advisor` | MVP / Growth / Enterprise |
| `ux-product` | Personas, jornadas, site institucional |
| `stack-curator` | Stack e integrações |
| `security-compliance` | LGPD, auth — Enterprise |

## Skills

| Skill | Quando |
|-------|--------|
| `sky-intake` | Sessão conversacional |
| `sky-elevate` | Índices SKY + UX + humanity_connections |
| `sky-approve` | Human gates |
| `sky-plan` | Pipeline batch |
| `sky-validate` | Valida pacote |
| `sky-export` | Empacota + Cloud Design |
| `sky-rag-index` / `sky-rag-query` | PR 4 |
| `learn-from-outcome` | Retroalimentação |

## Comandos

```powershell
./scripts/sky/sky.ps1 intake -Slug <slug>
./scripts/sky/sky.ps1 elevate -Slug <slug>
./scripts/sky/sky.ps1 status -Slug <slug>
./scripts/sky/sky.ps1 approve -Slug <slug> -Stage brief|elevation|architecture|package
./scripts/sky/sky.ps1 validate -Slug <slug>
./scripts/sky/sky.ps1 export -Slug <slug>
```

Compat: `./scripts/forge/forge.ps1` delega para `sky.ps1`.

## Guardrails

- Elevação e humanity_connections: `ai_suggested` até confirmação.
- `open_to_elevation: false` → sky-elevator só documenta, não insiste.
- Catálogo `docs/humanity/challenges-catalog.yaml` — neutro, sem prescrição política.
- UX: sem dark patterns; cores via tokens.

## Referências

- [SKY_MERIT_INDICES.md](docs/_meta/SKY_MERIT_INDICES.md)
- [INTAKE_PROTOCOL.md](docs/_meta/INTAKE_PROTOCOL.md)
- [MATURITY_MODEL.md](docs/_meta/MATURITY_MODEL.md)
- [sky-package.spec.yaml](docs/specs/sky-package.spec.yaml)
