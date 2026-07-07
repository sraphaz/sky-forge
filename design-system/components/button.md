# Button

> destino: `design-system/components/` · consumo: humanos e agentes · tokens: `tokens/`

## Propósito
Ação. Poucos por tela; o primário é raro (idealmente um). A casa afirma, não persuade — nada de urgência visual.

## Anatomia
Label (DM Sans 500, sentence case) · padding `--space-3` × `--space-6` · raio `--radius-sm` · alvo mínimo `--touch-target` (44px).

## Variantes
| Variante | Fundo | Texto | Borda | Uso |
|---|---|---|---|---|
| primária | `--accent` | `--text-on-accent` | — | 1 por vista (CTA real) |
| secundária | transparente | `--text-display` | 1px `--border-hairline` | ações normais |
| ghost | transparente | `--text-body` | — | ações terciárias, barras |
| destrutiva | transparente | `--text-body` | 1px `--border-hairline` | raro; confirmação textual obrigatória (nunca vermelho gritante) |

## Estados
hover: primária clareia (`--accent-hover`); secundária ganha borda ativa + glow sutil (`--shadow-card-hover`) — **nunca translada** · active/press: opacidade 0.85 · focus: `--focus-shadow` sempre visível · disabled: opacidade 0.45, cursor default · loading: label mantém largura, indicador mono discreto.

## A11y
`<button>` semântico; foco visível nos dois temas; loading com `aria-busy`; ícone-só exige `aria-label` (e é raro — preferir label).

## Regras
- Nunca bold no label; nunca UPPERCASE (caps é dos eyebrows mono).
- Transição 200ms `--ease-dawn`; sem bounce.
- Proibido: gradiente no fundo, sombra preta, emoji, seta decorativa (→ é de link).

## Exemplo
```html
<button style="background: var(--accent); color: var(--text-on-accent);
  font: 500 1rem var(--font-body); padding: 12px 24px; border: none;
  border-radius: var(--radius-sm); min-height: var(--touch-target);
  transition: background 200ms var(--ease-dawn);">
  Trazer uma ideia para maturação
</button>
```
