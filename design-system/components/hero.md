# Hero

> destino: `design-system/components/` · abertura editorial de página

## Propósito
Afirmar, não vender. Uma frase-alma em serif grande, ar generoso, no máximo uma luminescência lenta.

## Anatomia
Eyebrow mono UPPERCASE (`--text-xs`, tracking 0.18em) → H1 display (`--text-hero` 84px na home; `--text-4xl` em páginas internas; leading 1.14; measure `--measure-narrow` 34ch; palavra-alma em itálico `--accent`) → lead (`--text-lg`, `--text-body`) → meta/rodapé mono opcional (UPPERCASE, `--text-muted`) → CTA opcional (1, no máximo 2).

## Variantes
| Variante | Uso |
|---|---|
| editorial | só texto — páginas internas e docs |
| céu | fundo `--grad-ceu` + luminescência lenta (partículas/onda 18s) — home, página Surya Labs |
| doc | versão compacta (`--text-3xl`) para cabeçalho de documento |

## Regras
- H1 único; itálico dourado em UMA palavra/expressão (a palavra-alma).
- Sem imagem de banco; sem ilustração decorativa; o céu É o fundo.
- Animação de entrada: drift 1600ms `--ease-dawn`; ambiente respira em 9–18s; congelar com `prefers-reduced-motion`.
- Meta em mono traz FATOS (links reais, local, data) — nunca slogans.

## A11y
Contraste AA do itálico dourado sobre o fundo verificado nos dois temas; luminescência é `aria-hidden`.

## Exemplo
```html
<header style="padding: var(--space-40) var(--gutter) var(--space-32);">
  <div style="max-width: var(--container); margin: 0 auto;">
    <div style="font: 400 0.75rem var(--font-mono); letter-spacing: 0.18em;
      text-transform: uppercase; color: var(--text-muted);">SURYA LABS · CONSULTORIA NASCENDO</div>
    <h1 style="font: 400 4rem/1.14 var(--font-display); color: var(--text-display);
      max-width: 34ch; margin: 20px 0;">Antes de construir,
      <em style="color: var(--accent);">maturar.</em></h1>
  </div>
</header>
```
