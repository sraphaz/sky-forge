# Artifact card

> destino: `design-system/components/` · workspace: registry de artefatos da demanda · estende `card.md`

## Propósito
Um artefato registrado: o que é, de onde veio, qual versão — e a garantia visível de imutabilidade.

## Anatomia
Card compacto (padding `--space-4`) com: tipo em eyebrow mono (`HANDOFF_PACKAGE`, `ASSUMPTIONS`…) · nome do artefato (body 500) · linha de origem — `pkg-id · v1 · sha256 curto` (mono, `--text-muted`, hash truncado a 8 chars com title completo) · selo de imutabilidade quando `immutable: true` — mono `IMUTÁVEL` com ponto verde (`--accent-2`) · se superseded: selo `v1 → v2` e link para a vigente.

## Variantes
| Variante | Uso |
|---|---|
| importado | selo imutável; origem completa (pacote) |
| gerado | sem selo; origem = template/ação que gerou |
| superseded | opacidade 0.6; banner fino "substituído por vN" |

## Estados
hover: glow; clique abre o artefato (render md/yaml) · focus visível.

## Regras
- Hash sempre presente (mesmo truncado) — é a promessa de auditoria.
- Artefato importado não tem botão de editar (não existe a ação; ADR-0005). "Revisar" = link "solicitar novo export".
- Ícones: nenhum além de ponto de estado; o tipo em mono já identifica.

## Exemplo
```html
<article style="background: var(--bg-surface); box-shadow: var(--shadow-card);
  border-radius: var(--radius-md); padding: var(--space-4);">
  <div style="font: 400 0.6875rem var(--font-mono); letter-spacing: 0.14em;
    color: var(--text-muted); text-transform: uppercase;">HANDOFF_PACKAGE</div>
  <div style="font: 500 0.9375rem var(--font-body); color: var(--text-display);
    margin: 6px 0;">handoff-solution.yaml</div>
  <div style="display: flex; gap: 12px; font: 400 0.6875rem var(--font-mono);
    color: var(--text-muted);">
    <span>pkg-…mvp-v1 · v1 · a3f9c21e</span>
    <span style="color: var(--accent-2);">● IMUTÁVEL</span>
  </div>
</article>
```
