# Clean Craft — referência Sky-Forge

Critérios consultivos inspirados em Robert C. Martin (Uncle Bob).  
Atribuição: princípios públicos; skill externa [uncle-bob-craft](https://github.com/sickn33/antigravity-awesome-skills/tree/main/skills/uncle-bob-craft).

## Dependency Rule (Clean Architecture)

- Dependências apontam **para dentro** — domínio não conhece infra.
- Containers externos (UI, DB, LLM) são detalhes plugáveis.

## SOLID (contextual)

| Princípio | Pergunta na revisão |
|-----------|---------------------|
| SRP | Um módulo, uma razão para mudar? |
| OCP | Extensão sem editar núcleo? |
| LSP | Contratos substituíveis? |
| ISP | Interfaces mínimas por papel? |
| DIP | Abstrações estáveis, detalhes instáveis? |

## Boundaries Sky-Forge

- **Tenant boundary** — nunca cruzar RLS/caso
- **Case folder boundary** — regra ouro (01_ vs 04_/05_)
- **IA boundary** — harness, Claim, human-in-the-loop

## Code smells (heurísticas)

- God service / módulo que faz tudo
- Feature envy entre domínios
- Leaky abstraction (LLM escrevendo em 01_)
- Anemic domain (só CRUD sem regras)

## Uso no pipeline

```
c4-modeler → clean-craft-advisor (consult) → export
```

Output: `architecture/craft-review.md` — sugestões, não bloqueio automático.
