# Estratégia RAG

**Versão**: 1.0 | **Data**: 2026-07-04 | **Status**: planejado (PR 4)

## Quando usar

| Fase | RAG |
|------|-----|
| PR 1–3 | Não — corpus em markdown/yaml; leitura direta |
| PR 4+ | Sim — quando `docs/patterns/` + `docs/outcomes/` > ~50 docs |

## Corpus indexável

```
docs/patterns/**
docs/anti-patterns/**
docs/outcomes/**/learnings.md
docs/tiers/**
docs/integrations/catalog.yaml
docs/attribution/**  (opcional)
```

**Não indexar:** `.sky/sessions/*/transcript*`, secrets, PII.

## Metadata por chunk

```yaml
source: docs/patterns/community-app-with-map.md
dimension: technical
app_types: [community, territorial]
tier: [mvp-free, growth]
tags: [maps, flutter, supabase]
confidence: learned_from_outcome | curated
```

## Store (PR 4)

- Local: `.sky/rag/index/` (sqlite-vec ou LanceDB)
- Skills: `forge-rag-index`, `forge-rag-query`
- Spec: [forge-rag.spec.yaml](../specs/forge-rag.spec.yaml)

## Híbrido market-scout

```
RAG (interno, aprendizado) + web search (atual) → research.md
```

Re-ingestão em `docs/outcomes/` após revisão humana.
