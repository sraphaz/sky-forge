# Plugin / adapter examples — Sky-Forge

Plugins **não** rodam dentro da geração do core. Consumidores externos (ex.: workspace de consultoria) importam pacotes exportados.

## Regras

1. Core compila e passa CI **sem** `plugins/examples/`.
2. Nenhuma referência obrigatória a marca específica no core.
3. Contratos em `schemas/sky-forge/plugin.schema.yaml`.

## Exemplos

| Pasta | Descrição |
|-------|-----------|
| `examples/surya-labs-workspace/` | Adapter opcional — mapeia `consulting-handoff` → entidades de workspace |
| `examples/archify/` | Adapter opcional pós-export — Sky Architecture IR → Archify HTML |
| `examples/sky-forge-host/` | Plugin host — Sky-Forge opera dentro do repo brownfield (`sky attach`) |

Remova `plugins/examples/` para validar que o core permanece agnóstico.
