# Plugin/Adapter Surya Labs para Sky-Forge

> Status: rascunho para revisão humana · Versão 0.1 · 2026-07-06
> Repo destino: `surya-labs-workspace` (`docs/` + `integrations/sky-forge/`)
> Princípio: o plugin **traduz e valida**; não contém regra de negócio, não altera o core do Sky-Forge, não cria dependência inversa.

---

## 1. Papel do plugin

O Surya Labs Workspace consome pacotes do Sky-Forge (profile `consulting-handoff`) através deste adapter. O plugin:

1. **valida** o pacote exportado (schemas + policies da casa);
2. **mapeia** artefatos genéricos → entidades do Workspace;
3. **adapta** linguagem e templates (pt-BR, tom da casa, modelos de proposta);
4. **registra** a importação (hash, versão, origem) no artifact-registry.

O plugin vive no repo do Workspace (`integrations/sky-forge/`). Uma cópia-exemplo pode existir em `sky-forge/plugins/examples/surya-labs-workspace/` — opcional, removível, sincronizada a partir daqui (nunca o contrário).

## 2. Mapeamento canônico

```
Sky-Forge Output                        → Surya Workspace Entity
─────────────────────────────────────────────────────────────────
brief.yaml                              → Demand (núcleo: título, intenção, origem)
consulting-brief.yaml                   → DemandContext (cliente, dor, sucesso, restrições)
proposal-scope.yaml                     → Proposal (rascunho; estado proposal_draft)
handoff-solution.yaml                   → Artifact (tipo handoff_package)
risks-and-open-questions.yaml           → RiskRegister (da demanda)
professional-validation-needed.yaml     → ValidationChecklist (itens p/ advisor externo)
acceptance-criteria.yaml                → ApprovalGate (gate handoff_acceptance)
tooling-frugality.yaml                  → ToolingStrategy (anexo da demanda)
market-benchmark.yaml                   → MarketEvidence (anexo da demanda)
assumptions.yaml                        → Artifact (tipo assumptions; citado na proposta)
delivery-boundaries.yaml                → campos limit_* da Proposal + Artifact
```

Regras de mapeamento:
- Importação é **imutável**: revisão exige novo export no Sky-Forge → nova versão no registry (o Workspace nunca edita artefato importado).
- Todo destino guarda `source: {package_id, artifact, version, sha256}`.
- Campos sem mapeamento são preservados em `raw` (forward-compatible).
- Falha em um artefato obrigatório → importação inteira falha (atômica), com diagnóstico legível.

## 3. Estrutura no repo do Workspace

```
surya-labs-workspace/
  integrations/
    sky-forge/
      adapter.ts                 # orquestra: validar → mapear → registrar
      plugin.yaml                # declaração do plugin (ver §4)
      import-sky-package.ts      # CLI/entrada: recebe pasta ou tarball do pacote
      map-to-demand.ts           # brief + consulting-brief → Demand/DemandContext
      map-to-proposal.ts         # proposal-scope + delivery-boundaries → Proposal
      map-to-artifacts.ts        # demais artefatos → Artifact/RiskRegister/etc.
      validate-sky-package.ts    # schemas + policies (pré-condição de tudo)
      README.md                  # uso, exemplos, troubleshooting
```

Notas:
- `adapter.ts` não conhece UI; é chamável por CLI e pelo Workspace.
- Templates de linguagem (proposta em pt-BR, tom da casa) vivem em `integrations/sky-forge/templates/` e são dados, não código.
- Testes de contrato: fixtures de pacote válido/inválido versionadas; CI roda contra a versão declarada em `compatibility`.

## 4. Declaração do plugin

Arquivo canônico: [`plugins/surya-labs-workspace/plugin.yaml`](../../plugins/surya-labs-workspace/plugin.yaml) (neste pacote documental; no código, vive junto do adapter). Ele declara:

- **outputs requeridos** do pacote (e os opcionais);
- **mappings** (§2) de forma declarativa;
- **templates** aplicados na tradução;
- **policies** de importação (validações da casa);
- **validações** técnicas (schemas, hashes);
- **artefatos gerados** no Workspace;
- **o que não modifica** (core, pacote de origem);
- **compatibilidade** com versões do Sky-Forge Core.

## 5. Policies da casa (aplicadas na importação)

| Policy | Regra | Falha |
|---|---|---|
| `out_of_scope_required` | proposta só nasce se `out_of_scope` não vazio | bloqueia criação de Proposal |
| `validation_items_routed` | itens `blocking` do checklist criam pendência para advisor externo | bloqueia `proposal_sent` |
| `acceptance_verifiable` | todo critério de aceite tem método de verificação | bloqueia gate de handoff |
| `language_normalized` | títulos/resumos traduzidos pt-BR via templates; original preservado | aviso (não bloqueia) |
| `hash_verified` | sha256 de cada artefato confere com o manifesto | bloqueia importação |

## 6. Fluxo de uso (operador)

```
1. sky-forge export --profile consulting-handoff → ./packages/<demanda>-v1/
2. workspace import-sky-package ./packages/<demanda>-v1/
   → valida → mapeia → registra → demanda avança para human_review
3. revisão humana no Workspace
   → ok: segue para proposal_draft
   → ajustes: novo run no Sky-Forge → export v2 → reimportar (v2 no registry)
```

## 7. O que o plugin NÃO faz

- Não altera o Sky-Forge Core nem seus schemas.
- Não calcula shares, preços ou estados de demanda (regra de negócio = Workspace).
- Não edita artefatos importados.
- Não chama serviços externos.
- Não aprova nada — gates são humanos, no Workspace.

## 8. Pendências

- Formato de entrada no MVP: pasta local (**Decisão**) — tarball/URL depois.
- Versionamento do registry (arquivo YAML por demanda vs. tabela) — decidir no PRODUCT_SPEC/ADR.
- Idempotência de reimportação da mesma versão (proposta: no-op com aviso) — confirmar em implementação.
