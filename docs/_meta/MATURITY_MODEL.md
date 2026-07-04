# Modelo de maturidade — Sky-Forge

**Versão**: 1.1 | **Data**: 2026-07-04

## Dimensões

| Dimensão | Níveis | Artefatos |
|----------|--------|-----------|
| **business** | 0–4 | brief-draft.yaml |
| **product** | 0–4 | functional-requirements.yaml |
| **ux_design** | 0–4 | ux-spec.yaml, UXD em sky-merits |
| **technical** | 0–4 | nfr.yaml, integrations.yaml |
| **sustainability** | 0–4 | ops, CI/CD, scaffold |
| **elevation** | 0–4 | sky-merits.yaml, humanity_connections |

## Pesos padrão

| Dimensão | Peso |
|----------|------|
| business | 0.22 |
| product | 0.18 |
| ux_design | 0.15 |
| technical | 0.18 |
| sustainability | 0.12 |
| elevation | 0.15 |

## Pipeline unlock

| Estágio | Requer |
|---------|--------|
| `market_research` | business ≥ 0.70 |
| `sky_elevation` | business ≥ 0.65, product ≥ 0.50 |
| `ux_review` | product ≥ 0.55 |
| `architecture` | business ≥ 0.80, product ≥ 0.60, ux_design ≥ 0.40 |
| `cloud_design_export` | product ≥ 0.80, technical ≥ 0.60, elevation ≥ 0.35 |
| `full_package` | overall ≥ 0.85 |

## Índices SKY (paralelo)

Não substituem `overall_readiness` — complementam em `sky-merits.yaml`.
Ver [SKY_MERIT_INDICES.md](SKY_MERIT_INDICES.md).

## Export parcial

`completeness: partial` — overall ≥ 0.55, business ≥ 0.80.
