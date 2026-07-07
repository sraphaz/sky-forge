# Design system agent-ready — Raphael Silva · Surya Labs

> Status: rascunho para revisão humana · Versão 0.1 · 2026-07-06
> Repo destino: `design-system` (este projeto de design é a origem; o repo recebe a exportação)
> Objetivo: tornar o design system consumível por humanos **e agentes** (Claude Code, Cursor, Sky-Forge), com tokens canônicos, regras de geração e validação de saída.

---

## 1. Decisões canônicas (resolvem inconsistências conhecidas)

| Tema | Decisão canônica | Nota |
|---|---|---|
| Fonte display | **Cormorant Garamond** 400/500 — nunca bold; a escala é a ênfase | `readme.md` cita "Instrument Serif" em um trecho — **legado a corrigir**; `tokens/typography.css` e o brief técnico usam Cormorant Garamond |
| Fonte corpo/UI | **DM Sans** (400 corpo, 500 UI, 600 raríssimo) | |
| Fonte mono | **JetBrains Mono** (eyebrows UPPERCASE tracking 0.18em, datas, tags, código) | |
| Tokens canônicos | `tokens/*.css` deste projeto (colors, typography, spacing, effects, motion, fonts) | JSON espelhado é derivado (§4); CSS é a fonte |
| Tema escuro | **Noite** (default; `color-scheme: dark`) | fundo `#0a0e14`, superfícies `#121820/#1a2332` |
| Tema claro | **Dia** via `[data-theme="light"]` | papel `#f6f1e7`, ouro-tinta `#9c7f3e` (AA) |
| Alto contraste | **Pendência** — variante `[data-theme="hc"]` planejada; até lá, AA garantido nos dois temas e foco visível obrigatório | não inventar em geração |
| Acento primário | Ouro `#c9a962` lidera; verde `#4a7c59` e azul `#3d6b8e` servem | saturação sempre baixa |
| Cores de papel (workspace) | Comercial `#c9a962` · Portfólio `#8ba7c7` · Arquitetura `#63a695` · Eng. IA `#a08cc0` · Design·Mídia `#c08f9a` · Testes `#7fae8e` · Liderança `#d19a5b` · Admin `#9a9590` | |
| Legenda de diagramas do ecossistema | AZUL=Sky-Forge · OURO=Surya · VERDE=Ara Harness · IVORY=Raphael · MUDO=cliente | constante em todo material |

## 2. Fundamentos (síntese normativa)

- **Conceito:** *a noite clara* — profundidade contemplativa; luz quente do sol como acento.
- **Luz, não sombra (Noite):** elevação por glow dourado sutil e hairlines 1px; Dia usa sombras quentes suaves.
- **Forma:** raios 6/12/20px; hairlines em vez de sombras; **círculo reservado ao sol e fotos**.
- **Espaço:** base 4px; capítulos com 96–160px de respiro; container 1200px; texto 760px/68ch.
- **Movimento:** contemplativo — respira, deriva, amanhece; ciclos 9–18s; hover 200ms; revelação 600ms `--ease-dawn`; `prefers-reduced-motion` congela.
- **Tom de copy:** sentence case; UPPERCASE só em rótulos mono; zero hype; sem emoji.
- **A11y:** WCAG 2.1 AA nos dois temas; foco visível `--focus-ring`; alvo tátil ≥44px.

## 3. Estrutura de exportação

```
design-system/
  tokens/
    colors.json        # espelho de tokens/colors.css (noite + dia + papéis)
    typography.json    # famílias, escala, leading, tracking, measures
    spacing.json       # base 4px, escala, containers
    radius.json        # 6/12/20
    shadows.json       # glows (noite) + sombras (dia) — nomeados por intenção
    motion.json        # durações, easings (--ease-dawn), ciclos
  components/          # especificação conceitual, um md por componente
    button.md          # variantes, estados, tokens usados, a11y, exemplos
    card.md            # card padrão: hairline, elevação por glow, raio 12
    section.md         # capítulo de página: eyebrow mono + título serif + respiro
    hero.md            # hero editorial (84px, measure narrow)
    project-card.md    # projeto: nome serif, meta mono, hover glow
    demand-card.md     # workspace: estado, origem, alistados (cores de papel)
    artifact-card.md   # workspace: tipo, versão, hash curto, imutável (selo)
    proposal-card.md   # workspace: estado, valor (só signatários), fases
    approval-gate.md   # gate: documento exigido, status, quem passou, quando
    harness-status.md  # repo: profile, versão, doctor ok/drift/failing
  guidelines/          # já existem como cards HTML neste projeto (13 arquivos)
  rules/
    AGENT_RULES.md     # regras de geração (§5) — instalável como skill/rule
```

**Pendência:** gerar os `*.json` a partir dos CSS por script (1 fonte, 2 formatos) — nunca manter à mão os dois.

## 4. Consumo por agentes

- **Claude/Cursor:** instalar `SKILL.md` + `rules/AGENT_RULES.md` no repo alvo (via Ara Harness, template `.cursor/rules/design-system.md`).
- **Sky-Forge:** `design-tokens.json` entra como artefato opcional do pacote (`ux-spec` referencia componentes pelo nome canônico daqui).
- **Web:** importar `tokens/*.css` direto; Tailwind preset gerado dos JSON (brief técnico §3).

## 5. Regras de geração para agentes

**Obrigatório:**
1. Cores **somente via tokens** — hex hardcoded é falha de review.
2. Três vozes tipográficas, nunca outras fontes; display nunca bold.
3. Tema Noite default; toda tela funciona nos dois temas.
4. Eyebrow mono UPPERCASE 0.18em antes de títulos de seção.
5. Hairlines 1px para divisão; elevação por glow (Noite) — nunca `box-shadow` preto.
6. Texto mínimo 16px UI / 24px em slides 1920×1080; alvo tátil ≥44px.
7. Link externo com `↗` + `aria-label`.

**Proibido:**
- emoji; mandala overlay; neon; gradientes saturados; stock corporate;
- ícones preenchidos/coloridos (Lucide stroke 1.5 apenas, `--text-muted`/`--accent`);
- círculos decorativos (círculo = sol e fotos);
- animação que salta/pisca; ciclos <9s em ambient motion;
- tom de marketing, urgência, "revolucionário/10x/disruptivo".

## 6. Validação de saída visual

Checklist mecanizável (CI do repo de design ou revisão de PR):
1. grep de hex fora de `tokens/` → falha;
2. fontes carregadas ⊆ {Cormorant Garamond, DM Sans, JetBrains Mono} → senão falha;
3. contraste AA nos dois temas (axe/pa11y) → falha bloqueante;
4. `prefers-reduced-motion` testado (snapshot com e sem);
5. inspeção humana: aderência ao conceito (luz, respiro, sobriedade) — não automatizável.

## 7. Exportar para HTML/CSS/React

- **HTML/CSS:** `tokens/*.css` + classes utilitárias mínimas; exemplos canônicos em `guidelines/*.html`.
- **React/Next:** preset Tailwind gerado dos JSON; primitives conforme brief técnico (`Button, Chip, Card, SegmentedToggle, Avatar, DateBadge, RoleDot, Timeline, DocPage`).
- **Regra:** gerar do token, nunca copiar valores; PR que reescreve valor de token exige ADR.
