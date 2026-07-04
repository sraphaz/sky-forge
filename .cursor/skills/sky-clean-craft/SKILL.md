# Sky Clean Craft — Cursor skill

Consultivo — critérios Uncle Bob para arquitetura e scaffold. **Não** substitui linter.

## Agente

`clean-craft-advisor` (domínio, `consult_only`)

## Inspiração

[uncle-bob-craft](https://github.com/sickn33/antigravity-awesome-skills/tree/main/skills/uncle-bob-craft) — Clean Code, Clean Architecture, SOLID, boundaries, code smells.

## Quando usar

- Após C4 L2/L3 produzidos
- Antes de export / handoff ao `repo-scaffolder`
- Revisão de `scaffold/AGENTS.md`

## Output

`architecture/craft-review.md`:

1. **Dependency Rule** — direção das dependências entre camadas/containers
2. **SOLID** — aplicação contextual (não dogmática)
3. **Boundaries** — onde traçar interfaces (tenant, case, IA)
4. **Smells** — acoplamento, god modules, vazamento de domínio
5. **Sugestões** — concretas, priorizadas (must/should/could)

## Limites

- Sem prescrever stack (delegar `stack-curator`)
- Sem override de linter/formatter
- `ai_suggested: true` até confirmação do criador

## Referência interna

`docs/_meta/CLEAN_CRAFT.md`
