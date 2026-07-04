# Atribuição — GitHub Spec Kit

**Upstream:** https://github.com/github/spec-kit  
**Licença:** MIT

## Padrões adotados

- Ciclo specify → plan → tasks → implement
- Specs YAML como contrato de aceite
- Harness reproduzível em PR

## Mapeamento

| Spec Kit | Blueprint Forge |
|----------|-----------------|
| `/specify` | `forge-intake` + brief |
| `/plan` | `forge-plan` architecture |
| `/tasks` | task graph |
| `/implement` | export + scaffold (fora deste repo) |
