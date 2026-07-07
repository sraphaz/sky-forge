# ADR-0003 — Contratos por arquivos antes de APIs

> Status: aceita · 2026-07-06 · Repo destino: `surya-labs-docs/adr/` (transversal)

## Contexto
Sky-Forge, Workspace e Ara Harness precisam trocar dados. Cada nível de integração (arquivos → CLI → webhooks → API HTTP) adiciona infraestrutura, versionamento e superfície de falha.

## Decisão
Os contratos entre sistemas são **conjuntos nomeados de arquivos com schema** (Sky-Forge Package, Workspace Import, Harness Install), versionados por semver no manifesto. Integração no MVP é **nível 1: arquivos em repo/pasta**, movidos por CLI humana. Webhooks/API só quando volume real justificar — e mantendo os mesmos contratos de arquivo por baixo.

## Consequências
- (+) Zero infraestrutura nova; auditável por git; testável com fixtures (`examples/`).
- (+) Consumidores validam pacotes offline (hashes sha256 no manifesto).
- (−) Latência humana entre etapas (aceitável: os gates são humanos de qualquer forma).
- Regra derivada: campos desconhecidos são preservados (forward-compatible); obrigatórios ausentes falham com diagnóstico legível.

## Alternativas consideradas
API HTTP desde o início (versionamento e auth prematuros — rejeitada); banco compartilhado entre sistemas (acoplamento máximo — rejeitada).
