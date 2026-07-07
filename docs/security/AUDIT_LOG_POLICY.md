# Política de log de auditoria

> Status: rascunho para revisão humana · Versão 0.1 · 2026-07-06
> Repo destino: `surya-labs-docs/security/`
> Objeto: o histórico append-only do Workspace (HistoryEvent) e os registros de aprovação (approval-ledger). Princípio: **a trilha reconstrói qualquer decisão sem depender de memória**.

## O que é registrado (sempre)

- transições de estado de demanda (quem, de→para, quando, gate);
- aprovações/gates (identidade, documento, hash) — no ledger;
- importações de pacote (package_id, hashes, resultado);
- ações de agente: proposta feita, análise publicada, aprovação humana correspondente;
- alistamentos/desalistamentos; entrada e saída de pessoas;
- registros financeiros e liberações (com refs de nota/termo);
- mudanças de regra da casa (PR + merge em `conhecimento/`).

## O que NÃO entra no log

- conteúdo de segredos (nunca); dados pessoais além do necessário (identidade do ator sim; contatos não);
- valores financeiros em eventos de classe `interno` — evento aponta para o registro `signatários`.

## Propriedades

| Propriedade | Implementação |
|---|---|
| append-only | escrita só por adição; CI compara com versão anterior e falha em reescrita |
| integridade | hash encadeado (`prev_hash` → `hash`) por evento; algoritmo e âncora externa: **Pendência** técnica (q-02) |
| atribuição | todo evento tem `actor` (person_id, agent_id ou system) — agentes nunca mascarados de humanos |
| correção | erro não se apaga: novo evento/registro com `supersedes` |
| reconstrução | projeções (board, feed "o que aconteceu") derivam do log — nunca o contrário |

## Acesso e retenção

- Leitura: colaboradores ativos (classe `interno`); eventos que referenciam valores seguem `signatários`.
- Retenção: histórico da casa não expira (é a memória institucional); dados pessoais dentro de eventos seguem a retenção da classe `pessoal` (**Validação externa necessária** — LGPD: minimização vs. integridade do log; estratégia candidata: pseudonimizar ator após saída, mantendo hash).
- Export: log completo acompanha o export da demanda (RF15).

## Verificação

- teste automatizado: reconstruir a demanda fixture do zero só pelo log (critério de aceite nº 6 do PRODUCT_SPEC);
- verificação de cadeia de hash no CI do repo workspace;
- amostragem trimestral no rito da roda: escolher 1 demanda e reconstituir uma decisão.
