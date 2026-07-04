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
Chegada (sky-host) → intake-conductor (conversa)
    → sky-elevator + ux-design-specialist (elevação & UX)
    → market-scout / solutions-architect + c4-modeler + journey-sequence-modeler
    → arquitetura agêntica da solução (sky-agent-architecture, padrão Arah)
    → clean-craft-advisor (consult)
    → delivery-steward (export → pasta externa)
    → showcase-curator (preview visual, opt-in)
    → repo-scaffolder / prompt-assembler (implementar)
    → learn-from-outcome
```

## Catálogo de agentes

### Experiência do usuário

| ID | Função |
|----|--------|
| `sky-host` | **Anfitrião** — progresso, opções numeradas, roteamento |
| `delivery-steward` | Export, `SKY_OUTPUTS_DIR`, privacidade do pacote |
| `showcase-curator` | Galeria visual, `publish -Public`, deploy |

### Operacionais

| ID | Função |
|----|--------|
| `orchestrator` | Roteamento |
| `intake-conductor` | Conversa; maturity; coreografia de lacunas |
| `ux-design-specialist` | **UX spec, acessibilidade, UXD** |
| `market-scout` | Pesquisa mercado/stack |
| `solutions-architect` | Coordena C4, domínios, ADRs, jornadas |
| `c4-modeler` | **C4 L1/L2/L3** + domains + resumo |
| `journey-sequence-modeler` | **Sequências** + fluxograma de contexto |
| `prompt-assembler` | Prompts avançados + export |
| `repo-scaffolder` | Scaffold `AGENTS.md` do app novo |

### Domínio (consultivos)

| ID | Função |
|----|--------|
| `sky-elevator` | **Índices SKY, prosperidade humana, expansão de consciência** |
| `market-benchmark` | **Posicionamento de mercado — MPI, benchmark comercial + open-source, sugestões de lacuna** |
| `cost-tier-advisor` | MVP / Growth / Enterprise |
| `ux-product` | Personas, jornadas, site institucional |
| `stack-curator` | Stack e integrações |
| `security-compliance` | LGPD, auth — Enterprise |
| `test-architect` | **Estratégia de testes (TEA)** — risk-based, a11y, gates CI |
| `clean-craft-advisor` | **Craft Uncle Bob** — SOLID, boundaries (consultivo) |

## Skills

| Skill | Quando |
|-------|--------|
| `sky-intake` | Sessão conversacional |
| `sky-elevate` | Índices SKY + UX + humanity_connections |
| `sky-approve` | Human gates |
| `sky-plan` | Pipeline batch (C4 + jornadas + craft) |
| `sky-c4-model` | C4 três níveis + domínios |
| `sky-journey-sequences` | Sequências + context-flow |
| `sky-clean-craft` | Revisão craftsmanship (Uncle Bob) |
| `sky-test-architecture` | Estratégia de testes TEA (consult) |
| `sky-plan` | Pipeline batch com step-files on-demand |
| `sky-validate` | Valida pacote |
| `sky-export` | Empacota + Cloud Design |
| `sky-deliver` | Entrega guiada (delivery-steward) |
| `sky-publish` | Preview sanitizado para showcase |
| `sky-showcase` | Site visual local |
| `sky-choreograph` | Resolver coreografia + check autonomia |
| `sky-audit` | Trilha de auditoria |
| `sky-rag-index` / `sky-rag-query` | PR 4 |
| `learn-from-outcome` | Retroalimentação |

## Comandos

```powershell
./scripts/sky/sky.ps1 intake -Slug <slug>
./scripts/sky/sky.ps1 elevate -Slug <slug>
./scripts/sky/sky.ps1 benchmark -Slug <slug>
./scripts/sky/sky.ps1 status -Slug <slug>
./scripts/sky/sky.ps1 approve -Slug <slug> -Stage brief|elevation|architecture|package
./scripts/sky/sky.ps1 validate -Slug <slug>
./scripts/sky/sky.ps1 export -Slug <slug>
./scripts/sky/sky.ps1 export -Slug <slug> -ForAI -Scope essential|spec|full
./scripts/sky/sky.ps1 link -Slug <slug> -WorkspacePath <app-repo> [-PullSpec]
./scripts/sky/sky.ps1 pull-spec -Slug <slug>
./scripts/sky/sky.ps1 publish -Slug <slug> -Public
./scripts/sky/sky.ps1 showcase
./scripts/sky/sky.ps1 agents -Slug <slug>
./scripts/sky/sky.ps1 audit -Slug <slug>
```

Autonomia e auditoria: [AGENT_AUTONOMY.md](docs/_meta/AGENT_AUTONOMY.md) · [AGENT_OBSERVABILITY.md](docs/_meta/AGENT_OBSERVABILITY.md)

Jornada UX: [USER_JOURNEY.md](docs/_meta/USER_JOURNEY.md) · Outputs externos: [OUTPUTS_AND_SHOWCASE.md](docs/_meta/OUTPUTS_AND_SHOWCASE.md)

Compat: `./scripts/forge/forge.ps1` delega para `sky.ps1`.

## Guardrails

- Elevação e humanity_connections: `ai_suggested` até confirmação.
- `open_to_elevation: false` → sky-elevator só documenta, não insiste.
- Catálogo `docs/humanity/challenges-catalog.yaml` — neutro, sem prescrição política.
- UX: sem dark patterns; cores via tokens.
- **sky-host** é a face da experiência — uma decisão por turno; privacidade por padrão.
- **Autonomia** — níveis 0–6; ações bloqueadas vão para `.sky/audit/`; ver `check-autonomy.ps1`.

## Referências

- [SKY_MERIT_INDICES.md](docs/_meta/SKY_MERIT_INDICES.md)
- [INTAKE_PROTOCOL.md](docs/_meta/INTAKE_PROTOCOL.md)
- [MATURITY_MODEL.md](docs/_meta/MATURITY_MODEL.md)
- [USER_JOURNEY.md](docs/_meta/USER_JOURNEY.md)
- [OUTPUTS_AND_SHOWCASE.md](docs/_meta/OUTPUTS_AND_SHOWCASE.md)
- [sky-package.spec.yaml](docs/specs/sky-package.spec.yaml)
