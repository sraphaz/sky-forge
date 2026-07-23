# Enriquecimento Sky-Forge ← BMAD Method

**Versão:** 1.0 · **Data:** 2026-07-04  
**Upstream:** [BMAD Method](https://github.com/bmad-code-org/BMAD-METHOD) (MIT) — ver [BMAD.md](../attribution/BMAD.md)

Sky-Forge já absorve padrões BMAD de forma parcial. Este documento mapeia o que está pronto no BMAD, o que já temos, e o que enriquecer sem instalar `bmad-method` nem usar a marca BMad™.

---

## Mapeamento de fases

| BMAD | Sky-Forge | Agente principal |
|------|-----------|------------------|
| Analysis (opcional) | `shape` + market-benchmark | intake-conductor, market-scout |
| Planning | `shape` → `elevate` | intake-conductor, sky-elevator, ux-design-specialist |
| Solutioning | `specify` | solutions-architect, c4-modeler, journey-sequence-modeler |
| Implementation | `implement` | repo-scaffolder, prompt-assembler |

**Diferencial Sky:** fase `elevate` (índices SKY, humanity_connections) e `showcase` (opt-in) não existem no BMAD puro.

---

## Tracks adaptativos (scale-adaptive)

| BMAD track | Sky-Forge equivalente | Quando |
|------------|----------------------|--------|
| Quick Flow | `export -Completeness partial` + `export-for-ai -Scope essential` | Bugfix, feature pequena, readiness 55–84% |
| BMad Method (full) | `validate -Completeness full` + arquitetura + stories | Plataforma, SaaS, readiness ≥ 85% |
| Enterprise | tier `enterprise` + security-compliance + ops | LGPD, multi-tenant, auditoria |

**Ação adotada:** `maturity.yaml` + `tier-pricing.yaml` já funcionam como seletor de profundidade — documentar no intake quando o criador escolhe “rápido” vs “completo”.

---

## Padrões BMAD → Sky (status)

| Padrão BMAD | Sky-Forge hoje | Enriquecimento |
|-------------|------------------|----------------|
| Agentes especializados (PM, Architect, Dev, QA) | Catálogo `.agents/` + coreografia | ✅ Maduro |
| Document-driven (brief, PRD, arch, stories) | brief, RFs, C4, ADRs, acceptance-criteria | ✅ Maduro |
| **Story shards** (context-engineered dev) | `acceptance-criteria.yaml` (épico) | ✅ **Novo:** `templates/stories/` + `stories/IA-*.yaml` |
| **Document sharding** para IA | `export-for-ai` essential/spec/full | ✅ Incluir `agent-architecture.md` no escopo spec |
| Harness / QA contínua | `validate-package`, `agent-harness.spec.yaml` | ✅ Maduro (Arah) |
| Readiness gate pré-implementação | `validate-maturity`, gates `approve` | ✅ Maduro |
| `bmad-help` (o que fazer agora) | **sky-host** + `journey.yaml` | ✅ Equivalente nativo |
| Party Mode (multi-agente na sessão) | `co_activation` + `party_mode` em choreography.yaml | ✅ Showcase `/projects/{slug}/agentes/` |
| Step-file workflows (token savings) | `.skills/sky-plan/steps/*.step.yaml` | ✅ 7 steps on-demand |
| TEA (Test Architect enterprise) | `test-architect` + `sky-test-architecture` | ✅ Agente consultivo + template |
| `_bmad-output/` pasta única | `outputs/{slug}/` + `.sky/sessions/` | ✅ Equivalente |

---

## O que NÃO importar

- Instalador npm `bmad-method` — mantemos harness próprio
- Nome/marca BMad™
- Workflows genéricos sem elevação SKY nem showcase opt-in
- Party Mode como padrão — conflita com “uma decisão por turno” do sky-host

---

## Próximos passos de integração (prioridade)

1. **Story shards por IA-xx** — `templates/stories/story.template.yaml` → `stories/` na sessão antes de `implement`
2. **export-for-ai** — incluir resumo de arquitetura agêntica no escopo `spec`
3. **Scaffold** — `AGENTS.md` do app referencia `architecture/agents/` do pacote
4. **Intake** — pergunta explícita de track: “fluxo rápido ou pacote completo?”
5. ~~**Horizonte** — agente consultivo `test-architect` inspirado no módulo TEA do BMAD~~ ✅ v1.0

## Party Mode (como funciona)

- Definido em `.agents/choreography.yaml` → `party_mode.sessions`
- Resolvido por `current_phase` em `journey.yaml`
- Exibido no showcase em **Como foi produzido** → painel Party Mode
- sky-host media; máximo 4 opções por turno (não é chat livre multi-agente)

## Step-files sky-plan

```
.skills/sky-plan/steps/
  01-maturity-gate.step.yaml
  02-c4-model.step.yaml
  … 07-export.step.yaml
```

Carregar **um step por turno** no Cursor — ver `.cursor/skills/sky-plan/SKILL.md`.

---

## Referências cruzadas

- [USER_JOURNEY.md](USER_JOURNEY.md) — fases humanas
- [arah.md](../attribution/arah.md) — arquitetura agêntica da solução
- [spec-kit.md](../attribution/spec-kit.md) — harness spec-driven
- [SKY_INDICES_METHOD.md](SKY_INDICES_METHOD.md) — rubricas (além do BMAD)
