# Atribuição — swarm-planner (padrões)

**Upstream:** https://github.com/Gabrielasu/swarm-planner  
**Licença upstream:** não declarada (2026-07-04) — **nenhum código copiado**

## Padrões reimplementados

| Padrão | Nossa implementação |
|--------|---------------------|
| Task graph DAG | `outputs/{slug}/tasks/graph.json` |
| Self-contained prompt packets | `outputs/{slug}/tasks/task-*.md` |
| Human review checkpoint | `forge-approve` + step 7 equivalente em cada stage |
| Stateful plan | `maturity.yaml` + discoveries (futuro) |

## Diferenças

- Intake conversacional **antes** do pipeline batch
- Output também para humanos (brief, Cloud Design) — não só agent consumption
