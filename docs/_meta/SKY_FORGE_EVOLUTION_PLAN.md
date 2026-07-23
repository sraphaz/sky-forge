# Sky-Forge — Plano de evolução

> Status: rascunho para revisão humana · Versão 0.1 · 2026-07-06
> Repo destino: `sky-forge` (raiz `docs/`)
> Objetivo: evoluir o Sky-Forge para servir consultorias (inclusive a Surya Labs) **sem acoplamento** a nenhuma delas.

---

## 1. Direção

**Decisões:**

1. **Não** criar `surya-consulting` (nem qualquer marca) no core.
2. Criar o profile genérico **`consulting-handoff`** — serve a qualquer consultoria/estúdio/arquiteto.
3. Formalizar **arquitetura de profiles** (o que gerar, em que ordem, com quais gates).
4. Formalizar **arquitetura de plugins/adapters** (como consumidores estendem sem tocar o core).
5. Permitir **plugins externos** (repos/pastas de terceiros), com exemplo opcional no core.
6. Criar **validação por profile** (um pacote só exporta se satisfizer o profile).
7. Manter o core agnóstico de marca, língua e modelo comercial.

**Anti-objetivo:** o Sky-Forge não vira ferramenta de gestão. Ele matura, especifica e exporta. Quem opera é o consumidor.

## 2. Estrutura proposta

```
sky-forge/
  core/                        # motor: intake, geração, validação, export
  profiles/
    generic-product.yaml       # produto genérico (default atual)
    consulting-handoff.yaml    # NOVO — spec e handoff antes de implementação
    startup-mvp.yaml           # velocidade com dívida explícita
    open-source.yaml           # governança pública, contribuição
    internal-corporate.yaml    # compliance, stakeholders internos
  plugins/
    README.md                  # como escrever um plugin
    plugin.schema.yaml         # contrato de plugin
    examples/
      surya-labs-workspace/    # EXEMPLO opcional, removível, fora do core
        plugin.yaml
        mappings/
        templates/
  schemas/                     # schemas de todos os artefatos
  docs/
```

**Regra de build/teste:** o core compila e passa testes com `plugins/examples/` deletado. Teste de CI garante isso.

## 3. Arquitetura de profiles

Um **profile** declara: artefatos obrigatórios e opcionais, ordem de geração, gates humanos, critérios de prontidão e regras de validação para export. Schema: `schemas/sky-forge/profile.schema.yaml`.

| Profile | Para quê | Artefatos distintivos |
|---|---|---|
| `generic-product` | especificar um produto sem contexto comercial | brief, requisitos, ux-spec, architecture |
| `consulting-handoff` | entregar spec + handoff antes de implementar | + consulting-brief, proposal-scope, handoff-solution, acceptance-criteria, professional-validation-needed |
| `startup-mvp` | MVP com dívida assumida | + assumptions agressivas, delivery-boundaries curtas, riscos explícitos |
| `open-source` | projeto público | + contribution/governance notes, licenciamento em validação externa |
| `internal-corporate` | projeto interno corporativo | + compliance hooks, stakeholders, validação de dados/LGPD |

Detalhe do `consulting-handoff`: [`CONSULTING_HANDOFF_PROFILE.md`](./CONSULTING_HANDOFF_PROFILE.md).

## 4. Arquitetura de plugins/adapters

Um **plugin** é um pacote externo que declara (schema `plugin.schema.yaml`):

- `requires`: artefatos/versões do pacote que consome;
- `mappings`: artefato de origem → entidade/arquivo de destino;
- `templates`: sobrescritas de linguagem/formato do lado do consumidor;
- `policies`: validações extras na importação (nunca na geração);
- `compatibility`: faixa de versões do core suportada.

Garantias do core para plugins:
1. Contratos de artefatos versionados (semver) e estáveis dentro de major.
2. Export determinístico: mesmo input + mesmo profile → mesmo pacote.
3. Nenhum hook de plugin roda **dentro** da geração — plugins operam sobre o pacote exportado. (Mantém o core puro e os plugins removíveis.)

## 5. Novos artefatos genéricos

Todos com schema em `schemas/sky-forge/`. Convenção: YAML, chaves em inglês `snake_case`, texto livre no idioma do projeto.

| Artefato | Propósito | Gerado quando | Campos principais | Produz | Revisa/Aprova |
|---|---|---|---|---|---|
| `consulting-brief.yaml` | contexto de consultoria: cliente, dor, sucesso, restrições | após intake, antes do benchmark | client_context, problem, success_criteria, constraints, stakeholders | agente de intake | consultor responsável |
| `proposal-scope.yaml` | escopo proposto: entregáveis, fases, limites | após requisitos/UX/arch estabilizarem | deliverables[], phases[], out_of_scope[] (obrigatório), prerequisites | agente de escopo | humano responsável + cliente |
| `handoff-solution.yaml` | a solução entregável: visão, arquitetura, specs, plano | no fechamento da maturação | solution_summary, architecture_refs, spec_refs, implementation_plan, repo_recommendation (incl. harness_profile sugerido) | agente de handoff | arquiteto humano |
| `delivery-boundaries.yaml` | fronteiras de entrega: o que encerra a responsabilidade | junto do proposal-scope | included[], excluded[], support_window, handover_conditions | agente de escopo | humano responsável |
| `assumptions.yaml` | premissas assumidas e seu risco se falsas | contínuo, consolidado no export | assumption, basis, impact_if_wrong, owner | qualquer agente | revisor humano |
| `risks-and-open-questions.yaml` | riscos e perguntas abertas | contínuo, consolidado no export | risks[]{severity, mitigation}, open_questions[]{blocking?} | qualquer agente | revisor humano |
| `professional-validation-needed.yaml` | temas que exigem profissional habilitado (jurídico/fiscal/contábil/regulatório) | sempre que um tema surgir; obrigatório no profile consulting | items[]{topic, why_it_matters, professional, before_stage, blocking} | qualquer agente | steward + advisor externo |
| `tooling-frugality.yaml` | estratégia de ferramentas: custo, alternativas, lock-in | na arquitetura | tools[]{purpose, cost, alternative, lock_in_risk}, principles | agente de arquitetura | humano responsável |
| `acceptance-criteria.yaml` | critérios verificáveis de aceite do handoff | antes do export | criteria[]{statement, verification, owner}, sign_off | agente de QA/handoff | cliente + responsável |

Regras transversais:
- Nenhum artefato pode conter parecer jurídico/fiscal definitivo — apenas apontar para `professional-validation-needed`.
- `proposal-scope` sem `out_of_scope` não valida.
- `handoff-solution` sem `acceptance-criteria` correspondente não valida.

## 6. Validação por profile

Pipeline de export:

```
sky-forge validate --profile consulting-handoff ./run
  1. cada artefato valida contra seu schema
  2. profile checa presença dos obrigatórios
  3. regras cruzadas do profile (ex.: out_of_scope não vazio)
  4. gates humanos marcados como 'passed' no manifesto
  → só então: sky-forge export → package.yaml + artefatos + hashes
```

Gate humano = registro no manifesto (`gates: [{id, passed_by, at}]`) — o CLI não inventa aprovação.

## 7. Sequência de implementação

1. **S1** — Extrair schemas dos artefatos atuais; criar `profile.schema.yaml`; mover comportamento default para `generic-product.yaml`. *(sem mudança funcional)*
2. **S2** — Implementar `consulting-handoff.yaml` + novos artefatos + validação por profile.
3. **S3** — `plugin.schema.yaml` + comando `sky-forge package validate` para consumidores; docs de plugin.
4. **S4** — Exemplo `plugins/examples/surya-labs-workspace/` (opcional, removível) + teste de CI "core sem examples".
5. **S5** — Profiles restantes (`startup-mvp`, `open-source`, `internal-corporate`) conforme demanda real. **Hipótese:** não fazer antes de existir uso.

## 8. Riscos e pendências

- **Risco:** profiles virarem forks de comportamento difíceis de manter → mitigar com composição (profiles herdam de `base`).
- **Risco:** plugin de exemplo desatualizar → CI valida o exemplo contra o contrato a cada release.
- **Pendência:** nome do manifesto (`package.yaml` vs `skyforge.lock`) — decidir em ADR no repo.
- **Pendência:** onde runs são armazenados (pasta local vs branch) — ADR.
