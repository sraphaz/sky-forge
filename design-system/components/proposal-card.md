# Proposal card

> destino: `design-system/components/` · workspace: propostas da demanda · estende `card.md`

## Propósito
Uma proposta e seu estado no fluxo comercial — com disciplina de visibilidade: valores só para signatários.

## Anatomia
Card com: linha superior — id mono (`prop-001 · v1`) + selo de estado · resumo (1 linha do summary) · fases (linha mono compacta: `f1 maturação · f2 repo`) · bloco de valor — **condicional**: signatário vê `value_total` (display serif `--text-xl`); não-signatário vê `— · visível a signatários` (mono, `--text-muted`) · rodapé — enviada em / decidida em (mono).

## Estados da proposta → selo
`draft` muted · `internal_review` azul `--accent-3` · `sent` ouro `--accent` · `approved` verde `--accent-2` · `declined/expired` muted (sem vermelho — a casa não dramatiza recusa).

## Regras
- A checagem de signatário acontece no render (dado nem chega ao cliente não autorizado).
- `out_of_scope` tem presença no detalhe (nunca escondido em acordeão fechado por padrão).
- Versões: proposta v2 não apaga v1 — navegação entre versões com diff textual.
- Sem badge de urgência/validade piscante; validade é texto mono no rodapé.

## A11y
Estado com texto (não só cor); valor oculto anunciado como "restrito", não como vazio.

## Exemplo
```html
<article style="background: var(--bg-surface); box-shadow: var(--shadow-card);
  border-radius: var(--radius-md); padding: var(--space-6);">
  <div style="display: flex; justify-content: space-between; font: 400 0.6875rem var(--font-mono);">
    <span style="color: var(--text-muted);">PROP-001 · V1</span>
    <span style="color: var(--accent); text-transform: uppercase; letter-spacing: 0.12em;">sent</span>
  </div>
  <p style="font: 400 1rem/1.5 var(--font-body); color: var(--text-body); margin: 10px 0;">
    Especificação e handoff do sistema de alertas térmicos.</p>
  <div style="font: 400 1.75rem var(--font-display); color: var(--text-display);">R$ ▓▓▓▓▓
    <span style="font: 400 0.6875rem var(--font-mono); color: var(--text-muted);">VISÍVEL A SIGNATÁRIOS</span>
  </div>
</article>
```
