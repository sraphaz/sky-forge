# Changelog — Sky-Forge

## [1.6.0] — 2026-07-04

### Sugestões de IA de um clique nas lacunas (showcase local)

- **Respostas plausíveis por lacuna** — cada lacuna de dimensão em `/projects/{slug}/lacunas/` agora oferece 2–3 sugestões geradas pela IA a partir do contexto da sessão (brief, RFs, NFRs, ux-spec, benchmark); um toque preenche a textarea (editável) — o criador ainda decide e envia
- **Fonte regenerável** — `.sky/sessions/{slug}/gaps-suggestions.yaml` (`ai_suggested: true`, espelhado no pacote exportado); `publish-preview.ps1` publica como `gaps.gap_suggestions` no preview sanitizado; próximos intakes podem regenerar o arquivo
- **Auditoria da origem** — resposta enviada tal e qual a sugestão grava `answer_source: ai_suggested` em `decisions-inbox.yaml` (e no evento `gap.decide`); texto editado ou próprio grava `answer_source: user_text`
- **A11y** — chips são botões reais com `aria-pressed`, foco visível, contraste AA e `prefers-reduced-motion`; rótulo explícito "Sugestões da IA"
- **iautos** — 11 lacunas com 24 sugestões autoradas do contexto real da sessão

## [1.5.0] — 2026-07-04

### Decisão interativa de lacunas no showcase local

- **Modo interativo local** — rodando `sky.ps1 showcase` (ou `astro dev`), a página `/projects/{slug}/lacunas/` ganha controles de decisão: **Aceitar / Recusar / Decidir depois** para requisitos `ai_suggested` e **textarea + Responder** para lacunas de maturidade; no deploy estático (GitHub Pages) os controles não aparecem e permanecem os CTAs de copiar comando/prompt
- **Integração `sky-local-api`** ([apps/showcase/integrations/sky-local-api.mjs](../apps/showcase/integrations/sky-local-api.mjs)) — endpoints apenas no dev server (sem adapter, build estático intacto): `GET /api/health` (sonda de capacidade) e `POST /api/gaps/decide` (`{slug, item_id, decision: confirm|reject|skip|answer, note?, dry_run?}`)
- **Persistência com trilha** — confirm/reject grava `user_confirmed: true|false` no RF em `.sky/sessions/{slug}/functional-requirements.yaml` (edição textual que preserva comentários); toda decisão vai para `.sky/sessions/{slug}/decisions-inbox.yaml` (consumido pelo intake-conductor); evento `gap.decide` na auditoria (`record-agent-event.ps1`); preview regenerado via `publish-preview.ps1` — a página recarrega refletindo o novo estado
- **Sugestões decididas saem da contagem de lacunas** — `publish-preview.ps1` lê `user_confirmed` e publica `status: pending|accepted|rejected` por RF sugerido; o showcase mostra chips "Aceito por você" / "Recusado"
- Guardrails preservados: nada muda sem decisão explícita do criador (`ai_suggested` até confirmação), auditoria de cada escrita, WCAG AA (toast `aria-live`, foco visível, `prefers-reduced-motion`)

## [1.4.0] — 2026-07-04

### Consciência de mercado — agente market-benchmark e índice MPI

- **Espec SKY v1.2** — novo índice **MPI (Market Positioning Index)** com rubrica ancorada 0–100 ([SKY_INDICES_METHOD.md](_meta/SKY_INDICES_METHOD.md) §2): novidade vs. soluções existentes (comerciais + open-source), qualidade de diferenciação e cobertura consciente das lacunas do segmento; **fora do SKY_SCORE composto** para não invalidar scores v1.0/v1.1 (governança §6)
- **Agente `market-benchmark`** (consultivo) — benchmark real com fontes, veredito por eixo (novo/melhor/paridade/atrás), sugestões de lacuna sempre `ai_suggested`; regra [sky-benchmark.mdc](../.cursor/rules/sky-benchmark.mdc); separado do `market-scout` (research de stack) por ter output e momento distintos — paridade consciente > novidade ignorante
- **CLI** — `sky.ps1 benchmark -Slug <slug>`: explica o agente, valida presença do artefato e registra evento de auditoria
- **Pipeline** — `publish-preview.ps1` lê `market-benchmark.yaml` e publica resumo sanitizado (MPI + nomes/URLs + vereditos, sem notas internas); showcase ganha painel "Posicionamento de mercado" na página do projeto e MPI na seção de índices
- **iautos** — benchmark executado: 15 iniciativas (Astrea, ADVBOX, Projuris, EasyJur, Locus.IA, OpenSpecter, Judicex, LexNebulis…), MPI 66 ±8 (medium), 6 lacunas de mercado registradas como RF-014..RF-019 (`ai_suggested`, aguardando decisão do criador)

## [1.3.0] — 2026-07-04

### Roadmap consolidado, export para IA e trilha de evidências

- **Roadmap público** — [ROADMAP.md](_meta/ROADMAP.md): itens 🗺️ da auditoria + fases B–D da spec de UX em três horizontes (agora / próximo / horizonte), cada um com origem e critério de aceite; referenciado nas páginas `/metodo/` e `/sobre/` do showcase
- **Export para IA com escopos** — `sky.ps1 export -Slug x -ForAI -Scope essential|spec|full` ([export-for-ai.ps1](../scripts/sky/export-for-ai.ps1)): gera `SKY_AI_CONTEXT.md` sanitizado (paths absolutos → `<repo>`/`<outputs>`/`<home>`; `.dc.html` proprietários viram referência) em `{outputs}/{slug}/ai-export/`, pronto para colar em Cursor/Claude/ChatGPT
- **Trilha de evidência nos templates** — `demo-sky`, benchmark `example-horta` e `new-session.ps1` agora nascem com `spec_version`, `score_kind`, `weights`, evidência tipada, `confidence`/`band` e `evidenced: false` nas sugestões de elevação; confiança `low` com 0 evidências → faixa provável, nunca número exato

## [1.2.0] — 2026-07-04

### Do discurso ao método (auditoria "Sky Forge High Premium", 23 achados)

- **Espec SKY v1.1 aberta** — [SKY_INDICES_METHOD.md](_meta/SKY_INDICES_METHOD.md): rubricas ancoradas 0–100 por índice, tipos de evidência, bandas de confiança, governança por RFC (CC BY-SA)
- Índices SKY passam a ser descritos como **abertos e versionados** (a extensão Cloud Design segue proprietária — régua aberta, execução comercial)
- Schema `sky-merits`: `spec_version`, `score_kind` (intent/verified), `confidence`, `band`, evidência tipada, trilha `evidenced`/`requirement_id`, `cycles` (espiral) e `impact_checkpoints` (90/180 dias)
- Rubrica dupla da dimensão sustentação (negócio + operação) e frugalidade regenerativa dentro do GAP
- Showcase: página `/metodo/` com as rubricas; índices com nome PT, evidências e link para o método; tokens `--color-on-accent`, movimento nomeado e `prefers-reduced-motion`
- `publish-preview.ps1` carimba `spec_version` e contagem de evidências por índice
- Rastreabilidade completa dos achados: [EVOLUTION_AUDIT.md](_meta/EVOLUTION_AUDIT.md)

## [1.1.0] — 2026-07-04

### Rebrand & Elevação

- **Sky-Forge** — renomeação de Blueprint Forge (elevar o que está sendo proposto)
- Agentes: `ux-design-specialist`, `sky-elevator`
- Skill: `sky-elevate`
- Índices SKY proprietários: SPI, HCE, GAP, CWB, UXD — [SKY_MERIT_INDICES.md](_meta/SKY_MERIT_INDICES.md)
- Catálogo `docs/humanity/challenges-catalog.yaml`
- Dimensões maturity: `ux_design`, `elevation`
- Sessões: `.sky/sessions/` (antes `.forge/`)
- CLI: `scripts/sky/sky.ps1` (+ comando `elevate`)
- Extensão: `extensions/sky-cloud-design/`
- Spec: `sky-package.spec.yaml`

## [1.0.0] — 2026-07-04

### Added (PR 1 — esqueleto)

- Repositório `blueprint-forge` com AGENTS.md, orchestrator e 5 agentes operacionais
- 4 agentes de domínio consultivos
- Skills: forge-intake, forge-approve, forge-plan, forge-validate, forge-export, learn-from-outcome
- Stubs RAG: forge-rag-index, forge-rag-query (spec draft)
- Schemas: brief, maturity, RF, NFR, integrations, alternatives
- Modelo de maturidade 4 dimensões + pipeline_unlock
- Protocolo de intake conversacional (INTAKE_PROTOCOL.md)
- CLI `scripts/forge/forge.ps1`
- Sessão exemplo `templates/sessions/example-horta/`
- Extensão proprietária stub `extensions/forge-cloud-design/`
- Specs: forge-package (active), forge-rag (draft)
- Tiers MVP/Growth/Enterprise e catálogo de integrações
- Atribuições em NOTICE e docs/attribution/
- Cursor rules: forge-core, forge-intake
