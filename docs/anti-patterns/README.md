# Anti-patterns

Erros recorrentes a evitar nas recomendações do intake.

## AP-001 — K8s em MVP free

**Não recomendar** Kubernetes para tier mvp-free sem requisito explícito de ops.

## AP-002 — RF inferido como must

Nunca marcar `priority: must` com apenas `ai_suggested: true` sem `user_confirmed: true`.

## AP-003 — Perguntar stack antes do problema

Violar ordem do INTAKE_PROTOCOL nível 1.

## AP-004 — Indexar transcript no RAG

Violar guardrail de privacidade; só learnings anonimizados.
