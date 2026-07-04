# Roadmap — Sky-Forge

**Versão**: 1.0 | **Data**: 2026-07-04
**Fontes**: [EVOLUTION_AUDIT.md](EVOLUTION_AUDIT.md) (achados 🗺️) · [SKY_APP_UX.md](SKY_APP_UX.md) (fases A→D)

Três horizontes, mesmo princípio da auditoria: cada item deve deixar o Sky-Forge
mais **aberto**, mais **evidenciado** ou mais **verificado**. Um item só sai do
roadmap quando o critério de aceite está atendido — nunca por edição silenciosa.

Referências entre parênteses: `A-03` = achado 03 da auditoria; `UX-B` = fase B da
spec de UX do produto.

---

## Agora — em curso neste ciclo

| Item | Origem | Critério de aceite | Status |
|------|--------|--------------------|--------|
| **Export para IA com escopos** | UX-C (parcial) | `sky.ps1 export -Slug x -ForAI -Scope essential\|spec\|full` gera `SKY_AI_CONTEXT.md` sanitizado (sem paths absolutos, sem `.dc.html`) pronto para colar em Cursor/Claude/ChatGPT | ✅ entregue — CLI; wizard visual fica em UX-C |
| **Trilha de evidência nos templates** | A-02/A-04 | Toda sessão nova nasce com `spec_version`, `score_kind`, evidência tipada e `confidence` por índice; benchmark `example-horta` atualizado | ✅ entregue |
| **Roadmap público** | — | Este documento existe, é referenciado no showcase e na auditoria | ✅ entregue |
| **Decisão interativa de lacunas no showcase local** | UX-B (parcial) | Em `sky showcase` / `astro dev`, `/projects/{slug}/lacunas/` permite aceitar/recusar RFs `ai_suggested` e responder lacunas; escrita em `.sky/sessions/{slug}/` com auditoria e preview regenerado; deploy estático degrada para copy-prompt sem botões quebrados | ✅ entregue — 1.5.0 |

## Próximo ciclo — confiança

| Item | Origem | Critério de aceite |
|------|--------|--------------------|
| **Hub local lê sessões + outputs** | UX-B | `sky showcase` em dev lista sessões de `.sky/sessions/` com badge **Privado**; projetos locais nunca aparecem em deploy público (`data_source: registry` em produção) |
| **Conexão Git local-first** | UX-C | `.sky/sessions/{slug}/git.yaml` (workspace_path, remote opcional, sync_mode); detecção automática de `.git/`; nenhum token em plaintext — credencial só via keychain do SO |
| **Caso Ground no showcase** | A-18 | ≥ 1 dossiê publicado com `elevation_level: ground` e opt-in explícito do criador — a vitrine mostra o que o funil recusou ou o que ficou no chão. *Bloqueio atual: requer caso real; o suporte técnico já existe.* |
| **RFC em prática** | A-06 | Template de RFC público + primeira mudança de rubrica/peso tramitada por RFC com racional e impacto nos benchmarks |
| **Wizard export-para-IA** | UX-C | Fluxo visual dos 5 passos (escopo → sanitização → formato → destino → confirmação) sobre o CLI já entregue; checklist de sensibilidade bloqueia escopo `full` com dados de clientes |

## Horizonte — verdade

| Item | Origem | Critério de aceite |
|------|--------|--------------------|
| **Impacto verificado (medição real)** | A-03 | ≥ 1 projeto lançado com checkpoint 90/180 dias preenchido (previsto vs. observado) e `score_kind: verified`; showcase exibe o selo. *Bloqueio: requer projetos em produção — o schema (`impact_checkpoints`) já existe.* |
| **Modo local / runtime agnóstico** | A-07 | Intake roda com modelo local (sem dados saindo da máquina); dossiê carimba procedência (modelo + versão usados em cada índice). *Bloqueio: exige mudança de runtime dos agentes.* |
| **CLI npm multiplataforma** | A-08 | `npx sky` com paridade de comandos; `sky.ps1` vira wrapper fino. *Mitigação atual: PowerShell Core roda em macOS/Linux (documentado).* |
| **Funil como protocolo — MCP/API** | A-10 | Terceiros conduzem intake e consultam índices via MCP server ou API pública; alinhado com sky-rag (PR 4) |
| **PWA read-only + OAuth opcional** | UX-D | Showcase instalável com cache offline dos previews publicados; OAuth GitHub/GitLab apenas como extensão opt-in — nunca requisito |
| **Calibração contínua das rubricas** | A-03/A-06 | Dados de `impact_checkpoints` retroalimentam rubricas via RFC; benchmarks re-medidos a cada versão da espec |

---

## Regras de manutenção

1. Item novo entra com origem e critério de aceite — sem critério, não entra.
2. Item concluído migra para o [CHANGELOG](../CHANGELOG.md) com a versão que o entregou.
3. Itens bloqueados declaram o bloqueio (ex.: "requer caso real") em vez de fingir progresso.
4. Mudanças de prioridade seguem a governança da espec ([SKY_INDICES_METHOD.md](SKY_INDICES_METHOD.md) §6).
