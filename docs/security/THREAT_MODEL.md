# Threat model — ecossistema Surya Labs

> Status: rascunho para revisão humana · Versão 0.1 · 2026-07-06
> Repo destino: `surya-labs-docs/security/` · Método: STRIDE-lite por superfície
> Escopo: Workspace (repo + UI), pacotes Sky-Forge, repos governados, agentes. Fora de escopo: infraestrutura de terceiros (GitHub, Vercel) além da configuração que controlamos.

## Superfícies e ameaças

### S1 — Repo de conteúdo do Workspace (fonte de verdade)
| Ameaça (STRIDE) | Cenário | Mitigação |
|---|---|---|
| Tampering | edição de ledger/histórico para alterar aprovação | append-only + hash encadeado + verificação no CI; correção só via `supersedes` |
| Spoofing | commit se passando por outra pessoa | auth pela org do provider; commits assinados quando disponível; ações via UI carregam identidade da sessão |
| Repudiation | "eu não aprovei isso" | gate exige identidade + timestamp + hash do documento (ADR-0006) |
| Info disclosure | valores de proposta visíveis a não-signatários | campo `visibility: signatarios`; render da UI filtra por vínculo; repo privado |
| Elevation | colaborador altera regra da casa silenciosamente | mudanças de `conhecimento/` só por PR revisado |

### S2 — Pacotes Sky-Forge (fronteira de importação)
| Ameaça | Cenário | Mitigação |
|---|---|---|
| Tampering | artefato alterado entre export e import | sha256 por artefato no manifesto; import falha em divergência |
| Spoofing | pacote forjado "com gates passados" | gates carregam identidade humana; steward confere na revisão (humano no laço); assinatura de pacote é pendência (ver ARQUITETURA §7) |
| DoS | pacote gigante/malformado trava import | validação por schema antes de mapear; importação atômica com timeout |

### S3 — Agentes (todas as camadas)
| Ameaça | Cenário | Mitigação |
|---|---|---|
| Elevation | agente age fora do escopo | `allowed_paths`/`max_diff_lines` validados mecanicamente pelo PR Steward/CI |
| Tampering | prompt injection via conteúdo importado (e-mail, benchmark) | agentes só propõem — humano revisa todo diff; conteúdo externo tratado como não-confiável |
| Info disclosure | agente vaza dado sensível para provedor de modelo | política de dados por classificação (DATA_CLASSIFICATION); dados `sensível-cliente` não vão a prompt sem cláusula com o cliente (**Validação externa necessária**) |
| Repudiation | "foi o agente" | toda ação de agente vira proposta auditável; aprovação é humana e registrada |

### S4 — Repos governados de clientes
| Ameaça | Cenário | Mitigação |
|---|---|---|
| Info disclosure | segredo commitado | check `no-secrets` (block); profile enterprise: deep scan com histórico |
| Tampering | bypass do harness (push direto) | branch protection + `no-direct-main`; doctor acusa drift |
| Elevation | acesso da casa além do combinado | `ownership` + `access_notes` no RepositoryLink; escopo mínimo de tokens |

### S5 — Site + esteira (superfície pública)
| Ameaça | Cenário | Mitigação |
|---|---|---|
| DoS/spam | flood na esteira | rate limit no endpoint; honeypot field (sem captcha invasivo) |
| Info disclosure | vazamento de leads | dados de lead classificados `interno`; retenção mínima (LGPD — **Validação externa necessária**) |

## Riscos aceitos (nesta fase)
- Sem assinatura criptográfica de pacotes (volume baixo, revisão humana cobre) — revisar quando houver troca entre organizações.
- Sem SSO/2FA próprio — herdado do provider (exigir 2FA na org).

## Revisão
A cada release maior do Workspace ou novo tipo de integração; registrar mudanças aqui com data.
