# Estratégia de testes · {ProjectTitle}

**Agente:** test-architect (TEA consultivo) · **Slug:** {slug}  
`ai_suggested: true` até revisão humana

## Pirâmide de testes

| Camada | Escopo | Ferramentas |
|--------|--------|-------------|
| Unit | Domínio, guardrails, parsers | framework do stack |
| Integration | RLS, auth, APIs | DB de teste, fixtures por tenant |
| E2E | Fluxos críticos do MVP | Playwright |
| A11y | Fluxos principais WCAG AA | axe-core + Playwright |

## Matriz risco × cobertura

| Risco | RF/NFR | Teste mínimo | Gate CI |
|-------|--------|--------------|---------|
| Cross-tenant | NFR isolamento | Integration RLS | bloqueia merge |
| A11y AA | ux-spec | axe nos fluxos críticos | bloqueia merge |
| Regressão core | RFs must MVP | E2E smoke | bloqueia merge |

## Fluxos críticos (MVP)

1. {fluxo 1}
2. {fluxo 2}

## Critérios de aceite de qualidade

- [ ] Suite unitária verde
- [ ] Teste RLS / isolamento (se multi-tenant)
- [ ] axe sem violações AA nos fluxos listados
- [ ] Playwright smoke nos happy paths

## Notas

Derivar casos Given/When/Then das stories `stories/IA-*.yaml` por épico.
