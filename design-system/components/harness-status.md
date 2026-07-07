# Harness status

> destino: `design-system/components/` · workspace: status de governança do repo vinculado

## Propósito
Mostrar a saúde da governança de um repositório: profile, versão e veredito do doctor — derivado do repo real, nunca um checkbox manual.

## Anatomia
Linha/bloco compacto: ponto de status (8px, cor semântica) + `PROFILE @ VERSÃO` (mono) + veredito (`ok · drift · failing · unknown`) + última sincronização (`sync 2h atrás`, mono muted) + link para o relatório do doctor quando houver.

## Veredito → tratamento
| doctor | Ponto | Texto | Comportamento |
|---|---|---|---|
| ok | `--accent-2` (verde) | `OK` | quieto — não pede atenção |
| drift | `--accent` (ouro) | `DRIFT` | lista resumida do que divergiu; ação "ver relatório" |
| failing | `--accent` + texto `--text-display` | `FAILING` | destaca o primeiro erro; bloqueia transição harness_installed |
| unknown | `--text-muted` | `SEM LEITURA` | mostra última sync; ação "sincronizar" |

## Regras
- Sempre derivado do `harness-profile.yaml` + doctor do repo (schema harness-installation); se a leitura falha, é `unknown` — nunca "verde por padrão".
- `sync > 7 dias` acrescenta aviso mono `LEITURA ANTIGA`.
- Sem gauge/velocímetro; três palavras dizem tudo.
- No card do repo e no detalhe da demanda usa a MESMA linha (consistência).

## A11y
Cor nunca sozinha (texto do veredito sempre); ponto é `aria-hidden`; bloco com `aria-label` completo ("governança: consulting 0.1.0, ok, sincronizado há 2 horas").

## Exemplo
```html
<div aria-label="governança: consulting 0.1.0, ok, sync há 2h" style="display: flex;
  align-items: center; gap: 10px; font: 400 0.75rem var(--font-mono); letter-spacing: 0.06em;">
  <span aria-hidden="true" style="width: 8px; height: 8px; border-radius: 999px;
    background: var(--accent-2);"></span>
  <span style="color: var(--text-display);">CONSULTING @ 0.1.0</span>
  <span style="color: var(--accent-2);">OK</span>
  <span style="color: var(--text-muted);">SYNC 2H</span>
</div>
```
