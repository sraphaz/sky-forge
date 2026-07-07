# Approval gate

> destino: `design-system/components/` · workspace: gates no detalhe da demanda

## Propósito
Tornar o gate físico na interface: o que está travado, qual documento libera, quem passou e quando. O bloqueio é informativo, nunca punitivo.

## Anatomia
Bloco de largura total (não card solto): linha 1 — nome do gate (body 500) + selo de status · linha 2 — "libera: …" e "exige: documento X" (`--text-sm`, `--text-muted`; documento é link quando existe) · linha 3 (quando passed) — `passado por NOME · DATA · hash` (mono) · ação — botão secundário "Registrar passagem" (habilita só com o documento presente; tooltip explica o que falta).

## Status → tratamento
| Status | Selo | Comportamento |
|---|---|---|
| pending | outline muted `PENDENTE` | ação desabilitada com explicação do que falta |
| ready | ouro `PRONTO PARA REGISTRO` | documento presente; ação habilitada |
| passed | verde `--accent-2` `PASSADO` + ✓ | mostra identidade/data/hash; imutável |
| waived | ouro-escuro `DISPENSADO` | justificativa SEMPRE visível inline |

## Regras
- Agente nunca aparece como aprovador (o campo nem aceita).
- O gate mostra a REGRA ("contrato assinado por todos os alistados"), não só o status.
- Encadeamento visível: gates em coluna na ordem do fluxo, linha hairline conectando.
- Sem cadeado como ícone (clichê); o texto é o cadeado.

## A11y
`role="group"` com `aria-label` do gate; mudança de status anunciada (`aria-live="polite"`).

## Exemplo
```html
<div role="group" style="border-top: 1px solid var(--border-hairline); padding: var(--space-4) 0;
  display: grid; gap: 6px;">
  <div style="display: flex; justify-content: space-between;">
    <span style="font: 500 1rem var(--font-body); color: var(--text-display);">Aprovação da proposta pelo cliente</span>
    <span style="font: 400 0.6875rem var(--font-mono); letter-spacing: 0.12em; color: var(--accent-2);">✓ PASSADO</span>
  </div>
  <span style="font: 400 0.875rem var(--font-body); color: var(--text-muted);">Libera: vínculo de repositório · Exige: aceite registrado no ledger</span>
  <span style="font: 400 0.6875rem var(--font-mono); color: var(--text-muted);">raphael · 2026-07-04 · a3f9c21e</span>
</div>
```
