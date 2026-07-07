# Profile `consulting-handoff`

> Status: rascunho para revisão humana · Versão 0.1 · 2026-07-06
> Repo destino: `sky-forge` (`docs/`) · Arquivo de profile: `profiles/consulting-handoff.yaml`
> Este profile é **genérico**. Serve a qualquer consultoria, arquiteto, estúdio ou time que entregue especificação e handoff antes de implementação. Não contém nada da Surya Labs.

---

## 1. Objetivo

Levar uma intenção de software até um **pacote de handoff governável**: escopo claro, arquitetura, UX, riscos, critérios de aceite e recomendação de governança de repositório — sem escrever o software.

## 2. Quando usar

- O contratante quer clareza e especificação antes de comprometer implementação.
- Há ambiguidade alta de escopo, stakeholders ou viabilidade.
- A implementação será feita por outro time (ou depois, pela mesma casa, sob novo acordo).
- É preciso material auditável para decisão (proposta, orçamento, go/no-go).

## 3. Quando NÃO usar

- Bug fix, feature pontual em produto existente com escopo já claro.
- Protótipo descartável de um dia (usar `startup-mvp` ou nada).
- Projeto sem interlocutor decisor (não há quem passe os gates — corrigir isso primeiro).
- Quando o contratante espera código como entregável primário desta fase.

## 4. Artefatos

**Obrigatórios:**

| Ordem | Artefato | Etapa |
|---|---|---|
| 1 | `brief.yaml` | intake |
| 2 | `consulting-brief.yaml` | intake |
| 3 | `market-benchmark.yaml` | benchmark |
| 4 | `requirements.yaml` (funcionais + não funcionais) | requisitos |
| 5 | `ux-spec.yaml` | UX |
| 6 | `architecture.yaml` | arquitetura |
| 7 | `assumptions.yaml` | contínuo |
| 8 | `risks-and-open-questions.yaml` | contínuo |
| 9 | `proposal-scope.yaml` | proposta |
| 10 | `delivery-boundaries.yaml` | proposta |
| 11 | `tooling-frugality.yaml` | arquitetura |
| 12 | `professional-validation-needed.yaml` | contínuo (pode exportar vazio, nunca ausente) |
| 13 | `acceptance-criteria.yaml` | handoff |
| 14 | `handoff-solution.yaml` | handoff |

**Opcionais:** `data-model.yaml`, `content-inventory.yaml`, `design-tokens.json`, `agent-graph.yaml` (se o repo alvo usará agentes), protótipos HTML referenciados.

## 5. Gates humanos

| Gate | Após | Quem passa | O que confere |
|---|---|---|---|
| G1 `intent_confirmed` | intake | consultor responsável + contratante | o problema descrito é o problema real |
| G2 `scope_reviewed` | requisitos/UX/arch | responsável técnico | requisitos coerentes, riscos registrados |
| G3 `proposal_ready` | proposta | responsável comercial | escopo, fora-de-escopo e fronteiras fechados |
| G4 `handoff_approved` | handoff | contratante + responsável | critérios de aceite verificáveis, pacote íntegro |

Sem G-anterior não há etapa seguinte. Gates são registrados no manifesto do run (quem, quando).

## 6. Critérios de prontidão

**Mínimo para export do pacote:**
- todos os obrigatórios presentes e válidos por schema;
- todos os gates `passed`;
- zero `open_questions` com `blocking: true`;
- itens `blocking` de `professional-validation-needed` com encaminhamento registrado (não necessariamente resolvidos — mas nunca ignorados).

**Mínimo para proposta (G3):**
- `proposal-scope.yaml` com `deliverables`, `phases` e `out_of_scope` **não vazio**;
- `delivery-boundaries.yaml` presente;
- premissas de custo/ferramenta cobertas em `tooling-frugality.yaml`.

**Mínimo para handoff (G4):**
- `acceptance-criteria.yaml` com verificação objetiva por critério (como se verifica, quem verifica);
- `handoff-solution.yaml` com `repo_recommendation` (incl. `harness_profile` sugerido);
- riscos com severidade `high` têm mitigação ou aceitação explícita do contratante.

## 7. Regras do profile (validação dura)

1. **Não gerar proposta sem fora de escopo.** (`out_of_scope` vazio → export falha)
2. **Não gerar handoff sem critérios de aceite.** (`handoff-solution` exige `acceptance-criteria` válido)
3. **Não sugerir implementação sem explicitar escopo aprovado.** (plano de implementação referencia `proposal-scope` aprovado em G3)
4. **Não tratar validações jurídicas/fiscais/contábeis como parecer definitivo.** (campo `disclaimer: requires_licensed_professional` fixo no artefato)
5. **Não depender de ferramenta paga sem alternativa.** (cada tool com `cost > 0` exige `alternative` em `tooling-frugality`)

## 8. Riscos do próprio profile

- Excesso de artefato para demandas pequenas → usar variante `light` (**Pendência**: definir subconjunto mínimo) ou outro profile.
- Gates virarem carimbo automático → gate exige identidade humana no manifesto; auditoria por amostragem.
- Benchmark superficial tratado como verdade → `market-benchmark` carrega `confidence` e fontes datadas.

## 9. Fora de escopo do profile

- Execução da implementação e gestão do backlog dela.
- Precificação (o profile entrega escopo; preço é do consumidor/plugin).
- Contratos jurídicos (só aponta necessidade via `professional-validation-needed`).
- Instalação de governança no repo (recomenda `harness_profile`; instalar é com o Ara Harness).
