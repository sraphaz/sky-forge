# Política de segredos e credenciais

> Status: rascunho para revisão humana · Versão 0.1 · 2026-07-06
> Repo destino: `surya-labs-docs/security/`

## Regras duras

1. **Segredo nunca entra em repo** — nem em código, nem em doc, nem em fixture, nem em histórico. O check `no-secrets` (harness) é bloqueante em todos os profiles.
2. **Um segredo por finalidade:** cada agente, integração e ambiente tem credencial própria (nunca compartilhada), com dono humano e escopo mínimo.
3. **Onde vivem:** vault do provedor (GitHub Actions secrets / Vercel env) no MVP; `.env` local fora do controle de versão (`.gitignore` instalado pelo harness).
4. **Fixtures e exemplos** usam valores obviamente falsos (`fixture:`, `example-key-not-real`).
5. **Logs não contêm segredos:** redação automática nos wrappers de integração; revisar em code review.

## Ciclo de vida

| Etapa | Regra |
|---|---|
| criação | registrada no inventário (`security/tokens-inventory.yaml`, repo privado da casa): id, finalidade, escopo, dono, criado_em, expira_em |
| uso | só via vault/env; nunca em argumento de CLI logável |
| rotação | na saída de pessoa com acesso (bon voyage), na suspeita de exposição, e no máximo a cada 12 meses |
| revogação | checklist do bon voyage + revisão trimestral de tokens órfãos |

## Incidente: segredo exposto

1. **Rotacionar imediatamente** (revogar + reemitir) — antes de investigar.
2. Remover do histórico se commitado (rebase/filter) **e ainda assim tratar como comprometido**.
3. Registrar no log da casa: o quê, onde, janela de exposição, ação tomada.
4. Se tocar dado de cliente: avaliar comunicação com advisor (**Validação externa necessária** — obrigações LGPD).

## Verificação

- CI: scan de segredos em todo PR (block); profile enterprise adiciona varredura de histórico.
- Doctor do harness confere presença do `.gitignore` gerenciado e do workflow de scan.
