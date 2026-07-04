# Auditoria de evolução — "Do discurso ao método"

**Versão**: 1.0 | **Data**: 2026-07-04
**Fonte**: material externo "Sky Forge High Premium" (auditoria em Cloud Design, 23 achados).
Os arquivos `.dc.html` de origem são proprietários e **não** entram neste repo — este
documento resume e rastreia cada achado.

**Princípio da proposta** — toda mudança deve deixar o Sky-Forge mais aberto, mais
evidenciado ou mais verificado. Sintropia aplicada a si mesmo.

Severidade: 🔴 crítico · 🔵 estrutural · ⚪ refinamento
Status: ✅ implementado · 🔨 parcial · 🗺️ roadmap · 📖 já existia

---

## A · Método e profundidade — medir de verdade

| # | Sev | Achado | Proposta | Status |
|---|-----|--------|----------|--------|
| 01 | 🔴 | Rubricas públicas por índice — sem rubrica, SKY_SCORE é opinião com casas decimais | Página Método: rubrica ancorada 0–100 por índice, tipos de evidência, razão de cada peso | ✅ [SKY_INDICES_METHOD.md](SKY_INDICES_METHOD.md) + página `/metodo/` no showcase |
| 02 | 🔴 | Score sem evidência nem incerteza declarada | Score carrega evidências vinculadas + banda de confiança ("SPI 81 ±9 · 6 evidências"); abaixo da confiança mínima, faixa em vez de número | ✅ schema (`evidence`, `confidence`) + método §3; exibição de contagem no showcase |
| 03 | 🔵 | Impacto verificado, não só previsto — o funil termina no export | Checkpoints 90/180 dias previsto vs. observado; showcase distingue intenção de impacto verificado | 🔨 schema (`impact_checkpoints`) + método §3/§7; medição real é 🗺️ (requer projetos lançados) |
| 04 | 🔵 | Elevação sem atalho de pontos — "+6 SPI" no ato do aceite | Trilha `ai_suggested → user_confirmed → evidenced`; índice só sobe com evidência no artefato | ✅ schema (`evidenced`, `requirement_id`) + método §4 |

## B · Modelo aberto — abrir a régua, cobrar pela forja

| # | Sev | Achado | Proposta | Status |
|---|-----|--------|----------|--------|
| 05 | 🔴 | Régua fechada ("índices proprietários") — ninguém audita, ninguém confia por mérito | Espec SKY aberta e versionada (CC BY-SA) + harness open source; comercial é a execução | ✅ método publicado sob CC BY-SA; harness já era MIT; linguagem corrigida (achado 16) |
| 06 | 🔵 | Governança dos índices — sem processo para mudar peso/rubrica | RFCs públicos, changelog da espec, benchmarks de calibração, `spec_version` carimbada em cada dossiê | ✅ método §6 + `spec_version` no schema e no preview |
| 07 | 🔵 | Runtime agnóstico e modo local para intake privado | Agentes agnósticos de modelo; procedência (modelo/versão) no dossiê | 🗺️ roadmap — exige mudança de runtime; procedência entra como campo futuro |

## C · Ferramentas — do script ao protocolo

| # | Sev | Achado | Proposta | Status |
|---|-----|--------|----------|--------|
| 08 | 🔵 | CLI multiplataforma (hoje só PowerShell) | CLI `sky` via npm/brew; `.ps1` vira wrapper | 🗺️ roadmap — PowerShell Core já roda em macOS/Linux (documentado); port npm é projeto próprio |
| 09 | 🔵 | Dossiê git-friendly — diff entre ciclos como auditoria | Todo dossiê em texto versionável (YAML/MD/Mermaid) | 📖 já existia — sessões e outputs são YAML/MD; reforçado no método §6 |
| 10 | 🔵 | Funil como protocolo — MCP e API pública | Terceiros conduzem intake e consultam índices | 🗺️ roadmap (PR futuro) — alinhado com sky-rag (PR 4) |

## D · Concepção — do funil à espiral

| # | Sev | Achado | Proposta | Status |
|---|-----|--------|----------|--------|
| 11 | 🔴 | Funil linear contradiz a tese sintrópica — sem retorno não há ciclo | Espiral: export abre re-intake; linha do tempo de ciclos com delta de score | ✅ schema (`cycles`) + método §7; jornada documenta re-intake |
| 12 | 🔵 | Ledger de decisões — consentimento sem rastro verificável | Registro imutável: o quê, quem, quando, resposta | 📖 já existia parcialmente (`approvals.yaml`, `.sky/audit/events.jsonl`); formalizado no método §4 |

## E · Sustentabilidade — quem sustenta o sistema

| # | Sev | Achado | Proposta | Status |
|---|-----|--------|----------|--------|
| 13 | 🔵 | Dimensão "sustent." vira nota sem critério publicado | Rubrica dupla: negócio (unit economics) e operação (custo/sessão, resiliência) | ✅ método §5 |
| 14 | 🔵 | Pegada regenerativa — sistema sintrópico não mede a própria energia | Frugalidade dentro do GAP: tokens/sessão, dados mínimos, hardware antigo | ✅ incorporado à rubrica GAP (faixas 60+) |
| 15 | ⚪ | Escada de valor explícita — o que paga a conta | Três degraus públicos: aberto / pro / enterprise | 📖 já existia (`docs/tiers/`); referenciado no método §5 |

## F · Narrativa — uma história que se sustenta

| # | Sev | Achado | Proposta | Status |
|---|-----|--------|----------|--------|
| 16 | 🔵 | "Proprietários" na régua soa como aviso, não valor | "5 índices abertos e versionados" | ✅ README, CHANGELOG, SKY_MERIT_INDICES, showcase |
| 17 | ⚪ | Índices em inglês distanciam a apropriação | Nome PT na frente; EN na espec para citação | ✅ método §1 + labels do showcase (já eram PT) |
| 18 | 🔵 | Um caso Ground no showcase — vitrine sem contraexemplo parece marketing | Publicar caso que o funil recusou ou que ficou no chão | 🗺️ roadmap — requer caso real; suporte a `elevation_level: ground` já existe |

## G · UX — dignidade aplicada a si mesma

| # | Sev | Achado | Proposta | Status |
|---|-----|--------|----------|--------|
| 19 | 🔴 | Contradições com o UXD no próprio material (reduced-motion, min-width, tipografia < AA) | Fallback estático, responsivo, mínimo 11.5px, contraste AA | ✅ no showcase deste repo: `prefers-reduced-motion`, foco visível, mobile-first já aplicados; mínimos tipográficos revisados |
| 20 | 🔵 | Estados ausentes (foco, vazio, carregando, erro) | Spec de estados + aria-live para mudanças de score | 🔨 foco/vazio já existem no showcase; estados restantes documentados no método (UXD 60+) |
| 21 | 🔵 | O porquê de cada número — barras pedem confiança sem justificativa | Índice expande para critérios, evidências e "o que elevaria este número" | ✅ showcase: link de cada índice para `/metodo/` + contagem de evidências |
| 22 | 🔵 | Token para texto sobre gradiente — guardrail violado pelo próprio sistema | Token `--color-on-accent` nos dois temas; varredura de hardcodes | ✅ `global.css` |
| 23 | 🔵 | Vocabulário que falta ao design system (atenção, tooltip, movimento, breakpoints) | `--warn`, tokens de movimento nomeados, breakpoints | ✅ tokens de movimento e atenção em `global.css` |

---

## Priorização (três horizontes)

- **Agora — coerência**: 01, 05, 16, 19, 22 ✅ concluídos · 08 documentado
- **Próximo ciclo — confiança**: 02, 04, 11, 12, 13 ✅ · 09 📖 · 18, 20, 21, 23 🔨/✅
- **Horizonte — verdade**: 03 (medição real), 06 (RFCs em prática), 07, 10, 14 (medição), 15, 17 ✅

Todos os itens 🗺️ estão consolidados, com critérios de aceite e bloqueios declarados,
em [ROADMAP.md](ROADMAP.md).

## Guardrails respeitados

Nenhum achado conflita com os guardrails do AGENTS.md. Dois pontos de atenção:

- **Achado 05** não torna a extensão `sky-cloud-design` aberta — a fronteira é: régua aberta, execução comercial. A extensão permanece proprietária.
- **Achado 18** (caso Ground) só será publicado com opt-in explícito do criador do caso, como qualquer dossiê.
