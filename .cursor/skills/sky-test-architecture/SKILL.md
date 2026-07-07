# Sky Test Architecture — Cursor skill (TEA consultivo)

Use após NFRs e ux-spec definidos, ou no step `05-test-strategy` do sky-plan.

## Agente

`test-architect` — **consult only**, nunca side effects.

## Antes de produzir

1. `.sky/sessions/{slug}/nfr.yaml`
2. `.sky/sessions/{slug}/ux-spec.yaml` — `accessibility_target: WCAG_AA`
3. RFs must confirmados do MVP

## Output

`testing/test-strategy.md` — pirâmide de testes, matriz risco×cobertura, gates CI.

## Gates típicos (quando ux-spec pede AA)

- axe-core + Playwright nos fluxos críticos
- Violação AA bloqueia merge
- Testes de contrato para APIs multi-tenant / RLS

## Comando

Invocado via sky-plan step 05 ou manualmente no Cursor após especificar.

Persistir em `.sky/sessions/{slug}/testing/` antes do export.
