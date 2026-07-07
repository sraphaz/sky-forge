# Section

> destino: `design-system/components/` · o capítulo de página — unidade de ritmo do site e dos docs

## Propósito
Dar respiro e hierarquia. O luxo da casa é espaço: capítulos separados por 96–160px, nunca por caixas coloridas.

## Anatomia
Wrapper full-width (fundo `--bg-page` ou `--grad-ceu` no máximo) · conteúdo em `--container` (1200px) ou `--container-text` (760px para leitura) · cabeçalho do capítulo: eyebrow mono UPPERCASE (`--tracking-caps`, `--text-muted` ou `--accent`) → título display (`--text-3xl`/`--text-4xl`, nunca bold) → lead opcional (`--text-lg`, measure 68ch).

## Variantes
| Variante | Fundo | Uso |
|---|---|---|
| padrão | `--bg-page` | maioria |
| céu | `--grad-ceu` | 1–2 por página (hero, encerramento) |
| hairline-top | borda superior 1px `--border-hairline` | docs, listas contínuas |

## Regras
- Espaço vertical entre capítulos: `--space-24` a `--space-40` (96–160px).
- Máximo 2 fundos diferentes por página; alternância sutil, sem zebra.
- Eyebrow sempre presente em seções nomeadas (dá o ritmo mono→serif).
- Revelação ao rolar: fade-up 600ms `--ease-dawn`, reversível, respeitando `prefers-reduced-motion`.

## A11y
Um `<section>` com `aria-labelledby` do título; hierarquia de headings sem saltos.

## Exemplo
```html
<section style="padding: var(--space-32) var(--gutter);">
  <div style="max-width: var(--container); margin: 0 auto;">
    <div style="font: 400 0.75rem var(--font-mono); letter-spacing: 0.18em;
      text-transform: uppercase; color: var(--accent);">AS PEÇAS DO ECOSSISTEMA</div>
    <h2 style="font: 400 3rem/1.14 var(--font-display); color: var(--text-display);
      margin: 16px 0 24px; max-width: 34ch;">Cinco camadas, uma cadeia coerente.</h2>
  </div>
</section>
```
