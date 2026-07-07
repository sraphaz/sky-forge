# Demand card

> destino: `design-system/components/` · workspace: board de demandas · estende `card.md`

## Propósito
Uma demanda no board: estado, origem e quem está alistado — de relance, sem ansiedade de dashboard.

## Anatomia
Card interativo (raio 12, hairline) com: linha superior — id mono (`dem-2026-014`, `--text-muted`) + selo de estado (mono 11px UPPERCASE, cor semântica) · título (body 500, 2 linhas máx, ellipsis) · linha de contexto — cliente/projeto (`--text-sm`, `--text-muted`) · rodapé — origem (mono: `ESTEIRA|EMAIL|INDICAÇÃO|INTERNA`) + AvatarStack dos alistados (fotos circulares 24px com anel hairline) + idade da demanda (mono, ex.: `9D`).

## Estados da demanda → cor do selo
`received/triage` `--text-muted` · `skyforge_intake/artifacts_generated` `--accent-3` (azul) · `human_review/proposal_*` `--accent` (ouro) · `approved→handoff_ready` `--accent-2` (verde) · `closed` `--text-muted` com ✓ · `paused` outline muted · `rejected` `--text-muted` riscado.

## Estados do componente
hover: `--shadow-card-hover` · focus: `--focus-shadow` · dragging (se board permitir): opacidade 0.85 (sem rotação).

## Regras
- Selo de estado usa a máquina canônica; o ciclo narrativo aparece só em tooltip/detalhe.
- Sem barra de progresso (estado não é percentual); sem contadores decorativos.
- Valores financeiros NUNCA no card (classe signatários — só no detalhe autorizado).
- Cor nunca é o único canal do estado (texto do selo sempre presente).

## Exemplo
```html
<article tabindex="0" style="background: var(--bg-surface); box-shadow: var(--shadow-card);
  border-radius: var(--radius-md); padding: var(--space-4) var(--space-6); cursor: pointer;">
  <div style="display: flex; justify-content: space-between; font: 400 0.6875rem var(--font-mono);
    letter-spacing: 0.12em;">
    <span style="color: var(--text-muted);">DEM-2026-014</span>
    <span style="color: var(--accent); text-transform: uppercase;">human_review</span>
  </div>
  <h4 style="font: 500 1rem/1.4 var(--font-body); color: var(--text-display); margin: 8px 0;">
    Monitoramento de estufas — AgroVale</h4>
  <div style="display: flex; justify-content: space-between; align-items: center;
    font: 400 0.6875rem var(--font-mono); color: var(--text-muted);">
    <span>ESTEIRA</span><span>9D</span>
  </div>
</article>
```
