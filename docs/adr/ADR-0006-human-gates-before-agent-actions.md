# ADR-0006 — Gates humanos antes de qualquer ação de agente

> Status: aceita · 2026-07-06 · Repo destino: `surya-labs-docs/adr/` (transversal — vale para Workspace, Sky-Forge e Harness)

## Contexto
Agentes operam em todas as camadas do ecossistema (intake, geração de artefatos, PR Steward, rascunhos). Sem uma regra dura, a conveniência empurra para autonomia crescente — e "a IA fez" não é resposta aceitável para cliente, auditor ou juiz.

## Decisão
**Nenhuma ação de agente muda estado sem aprovação humana registrada.** Concretamente:
- agentes **propõem** (diff, PR, rascunho, análise); nunca aprovam, nunca fazem merge (`can_merge`/`can_approve` são `false` imutáveis no schema de agente);
- todo gate registra **identidade humana**, timestamp e hash do documento no ledger/manifesto — CLIs e CIs não inventam aprovação;
- todo caminho do Agent Graph que termina em ação de estado passa por ≥1 aresta `approval=true` com nó humano (validador falha o CI se não);
- validações mecânicas (schema, hash, paths, DoD) são automáticas — **verificar** não é **aprovar**.

## Consequências
- (+) Responsabilidade sempre endereçável a uma pessoa; trilha completa por construção.
- (+) Adoção de agentes pode crescer sem renegociar confiança a cada passo.
- (−) Humanos são o gargalo deliberado (aceito: os gates marcam exatamente onde a casa quer atenção humana).
- (−) Custo de cerimônia em mudanças triviais — mitigado por escopos de agente bem desenhados, não por exceções à regra.

## Alternativas consideradas
Auto-merge com revisão amostral (auditoria a posteriori não reconstrói decisão — rejeitada); níveis de autonomia por confiança do agente (complexidade de política antes de existir histórico — adiada, exigiria revisão desta ADR).
