# Classificação de dados

> Status: rascunho para revisão humana · Versão 0.1 · 2026-07-06
> Repo destino: `surya-labs-docs/security/`
> Regra de ouro: na dúvida, classifique mais restrito. Reclassificar para baixo exige decisão registrada.

## Classes

| Classe | Definição | Exemplos | Onde pode viver | Pode ir a prompt de IA? |
|---|---|---|---|---|
| `público` | publicável sem dano | site, escritos, repos open-source, schemas genéricos | qualquer lugar | sim |
| `interno` | da casa; sem dano grave se vazar, mas não é público | docs de processo, backlog, ritos, registros de rito | repos privados da casa | sim (provedor com política de não-treino) |
| `signatários` | visível só a vinculados à demanda | valores de proposta, splits, tickets individuais | repo workspace com filtro de render | só agregado/anonimizado |
| `sensível-cliente` | material do cliente sob confiança/NDA | briefs de cliente, dados de negócio, código proprietário | repo da demanda; nunca em exemplos/fixtures | **só com cláusula contratual explícita** (**Validação externa necessária**) |
| `pessoal` | dado pessoal (LGPD) | contatos, leads, RSVP, fotos | mínimo necessário; retenção definida | não, salvo base legal + necessidade real |
| `segredo` | credenciais e chaves | tokens, API keys, senhas | **nunca em repo**; vault do provedor | nunca |

## Regras operacionais

1. Todo documento novo declara classe no frontmatter (`classification:`); ausente = `interno`.
2. Fixtures e exemplos usam **sempre** dados fictícios ou da própria casa (nunca `sensível-cliente`/`pessoal` reais).
3. RSVP de ritos é efêmero: apagado após o rito (já é regra da casa).
4. Dados `pessoal`: inventário no Workspace (quem, o quê, base legal, retenção) — alimenta o item LGPD do checklist de validação externa.
5. Export/download de demanda preserva a classificação (aviso no cabeçalho do export).
6. Rebaixar classificação (ex.: case público de um projeto) exige aceite do cliente registrado no ledger.

## Mapeamento rápido por entidade do Workspace

Demand/intent: interno · DemandContext (cliente): sensível-cliente · Proposal (valores): signatários · Approval: interno (sem valores) · FinancialRecord: signatários · ValidationChecklist: interno · Person: pessoal (campos de contato) · HistoryEvent: interno (payloads seguem a classe da origem).

## Pendências
- Retenção por classe (números concretos) — definir com advisor (LGPD).
- Processo de take-down (cliente pede remoção) — rascunhar antes da primeira demanda externa.
