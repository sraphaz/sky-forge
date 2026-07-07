# ADR-0005 — Artefatos importados são imutáveis

> Status: aceita · 2026-07-06 · Repo destino: `surya-labs-workspace/docs/adr/`

## Contexto
Pacotes do Sky-Forge chegam ao Workspace com gates humanos passados e hashes registrados. Se o Workspace pudesse editar um artefato importado, a trilha de auditoria quebraria: o que o cliente aprovou deixaria de ser o que está no sistema.

## Decisão
Todo artefato importado é **imutável** no Workspace (`immutable: true` no registry, com sha256). Revisão de conteúdo = novo run/export no Sky-Forge → nova versão importada → novo registro com `supersedes`. O mesmo vale para o ledger de aprovações: append-only; correção é novo registro que supersede o anterior, nunca edição.

## Consequências
- (+) Qualquer aprovação referencia um hash que sempre corresponde ao conteúdo aprovado.
- (+) Diff entre versões de pacote é informação de primeira classe (o que mudou entre v1 e v2).
- (−) Iteração tem cerimônia: ajustes voltam ao Sky-Forge (aceito: é o custo da auditabilidade; ciclos curtos mitigam).
- Regra derivada: reimportar a mesma versão é no-op com aviso (idempotência).

## Alternativas consideradas
Edição com histórico git "resolve" (hash do aprovado divergiria do vigente sem trilha explícita — rejeitada); artefatos mutáveis com trava pós-aprovação (janela de inconsistência antes da trava — rejeitada).
