# Política de controle de acesso

> Status: rascunho para revisão humana · Versão 0.1 · 2026-07-06
> Repo destino: `surya-labs-docs/security/`
> Princípios: horizontalidade entre humanos; distinção dura humano × agente; visibilidade por vínculo (signatários); menor privilégio para máquinas.

## Identidade

- **Humanos:** identidade = conta na org do provider (GitHub). Org exige 2FA. Entrada/saída de pessoas segue gates da casa (onboarding assinado → acessos; bon voyage → revogação).
- **Agentes:** identidade própria (app/token dedicado por agente), nunca conta pessoal emprestada. Todo agente tem `human_owner` responsável.
- **Clientes:** sem login no MVP; recebem exportações. Acesso futuro = decisão de produto + termos (**Pendência**).

## Matriz de acesso (MVP)

| Recurso | Colaborador ativo | Steward | Agente | Advisor externo |
|---|---|---|---|---|
| repo workspace (ler) | ✓ | ✓ | ✓ (escopo declarado) | — (recebe exportações) |
| criar demanda / alistar-se | ✓ | ✓ | — | — |
| passar gates da demanda | ✓ (técnicos) | ✓ (todos, incl. comerciais) | **nunca** | — |
| ver valores/splits | só signatário | ✓ | — | sob demanda, por item roteado |
| editar `conhecimento/` (regras) | via PR revisado | via PR revisado | propõe PR | — |
| merge em `main` | via PR aprovado | via PR aprovado | **nunca** | — |
| configurar integrações/segredos | — | ✓ | — | — |
| repos de cliente | conforme alistamento | ✓ | escopo por repo (.agents/) | — |

## Regras

1. **Nenhum acesso sem gate documental:** conta só existe após onboarding assinado; morre no bon voyage (checklist de revogação: org, repos, vault, e-mail).
2. **Menor privilégio para tokens:** cada integração/agente tem token próprio com escopo mínimo e dono humano; inventário em `security/tokens-inventory.yaml` (fora do repo público).
3. **Acessos de cliente a repos:** definidos no RepositoryLink (`ownership`, `access_notes`); revisados no encerramento da demanda.
4. **Revisão trimestral** (rito da roda): quem tem acesso a quê; tokens órfãos revogados.
5. **Exceções** são registradas no ledger (gate `other`) com prazo de expiração.

## Pendências
- Ferramenta de vault definitiva (provider secrets vs. gerenciador dedicado) — decidir em ADR.
- Formalizar responsabilidade de acesso em contrato de colaboração (**Validação externa necessária**).
