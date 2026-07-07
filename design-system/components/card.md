# Card

> destino: `design-system/components/` · base de demand-card, artifact-card, proposal-card

## Propósito
Agrupar um objeto ou tema. Superfície calma: hairline + fundo de superfície; a luz só aparece em hover/destaque.

## Anatomia
Contêiner `--bg-surface` · borda `--shadow-card` (hairline via box-shadow) · raio `--radius-md` (12px) · padding `--space-6` a `--space-8` · slots: eyebrow mono (opcional) → título (display ou body 500) → corpo → meta/rodapé mono.

## Variantes
| Variante | Diferença | Uso |
|---|---|---|
| padrão | como acima | listas, grids |
| interativo | hover: `--shadow-card-hover` (borda + glow) | card-link inteiro clicável |
| elevado | `--bg-raised` | destaque dentro de outra superfície |
| quieto | sem borda, só `--bg-surface` | agrupamento suave em página densa |

## Estados
hover (interativo): glow, **sem translação/escala** · focus-within: `--focus-shadow` · selecionado: borda `--border-active`.

## A11y
Card clicável = um único `<a>`/`<button>` envolvendo (não onClick em div); título é heading do nível correto; meta não transmite informação apenas por cor.

## Regras
- Um card = um objeto; sem cards dentro de cards (usar seção).
- Cantos 12px sempre; sem faixa lateral colorida de acento (anti-slop) — papel/estado entram como ponto (`RoleDot`) ou selo mono.
- Densidade: mínimo `--space-6` de padding; respiro entre cards `--space-4`+.

## Exemplo
```html
<article style="background: var(--bg-surface); box-shadow: var(--shadow-card);
  border-radius: var(--radius-md); padding: var(--space-6);">
  <div style="font: 400 0.75rem var(--font-mono); letter-spacing: 0.18em;
    text-transform: uppercase; color: var(--text-muted);">PROJETO</div>
  <h3 style="font: 400 1.75rem var(--font-display); color: var(--text-display);
    margin: 8px 0;">Sky-Forge</h3>
  <p style="font: 400 1rem/1.65 var(--font-body); color: var(--text-body);">
    Motor genérico de maturação: da conversa a artefatos.</p>
</article>
```
