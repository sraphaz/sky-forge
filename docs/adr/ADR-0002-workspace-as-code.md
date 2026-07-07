# ADR-0002 — Workspace-as-code: repo git como fonte de verdade

> Status: aceita · 2026-07-06 · Repo destino: `surya-labs-workspace/docs/adr/`

## Contexto
O Workspace precisa registrar demandas, propostas, aprovações e histórico de forma auditável, exportável e legível por humanos **e agentes** — com custo ~zero e sem lock-in (princípios de autonomia operacional da casa).

## Decisão
A fonte de verdade do Workspace é um **repositório git de conteúdo** (markdown + YAML frontmatter). A UI é uma janela sobre o repo; escritas viram commits; agentes propõem mudanças como diffs/PRs; qualquer índice (ex.: SQLite para busca) é derivado e reconstruível a partir dos arquivos — nunca fonte.

## Consequências
- (+) Auditoria por git; export trivial; agentes leem/escrevem o mesmo formato que humanos.
- (+) Custo zero de banco; backup = clone.
- (−) Concorrência de escrita exige cuidado (lock otimista por arquivo; aceitável no volume do MVP — assumption a-01 do pacote).
- (−) Consultas complexas pedem índice derivado (decisão adiada — open question q-01).
- Regra derivada: conflito com espelhos externos (GitHub Projects, Jira) → **o repo vence**, evento no log.

## Alternativas consideradas
Postgres como fonte (auditoria e export piores, custo e lock-in — rejeitada); SaaS de PSA (contradiz autonomia operacional — rejeitada).
