# ADR-0004 — Extrair o Ara Harness do Arah como produto independente

> Status: aceita · 2026-07-06 · Repo destino: `arah-harness/docs/adr/`

## Contexto
O Arah acumulou prática real de repositório governado (specs, agentes com escopo, PR Steward, CI, DoD, ADRs). A Surya Labs precisa instalar essa governança em cada repo de demanda. Manter isso dentro do Arah acopla governança genérica a domínio territorial.

## Decisão
Extrair a mecânica de governança para um repo próprio, **`arah-harness`**, composto de templates + schemas + profiles + scripts. Critério de triagem: *se remover a palavra "território/Arah" do item e ele continuar fazendo sentido para um repo qualquer → harness; senão → permanece no Arah.* O Arah torna-se o primeiro consumidor (dogfooding), migrando via `install-harness` com profile `product`.

## Consequências
- (+) Governança instalável em qualquer repo (Surya, clientes, terceiros) — vira inclusive oferta comercial (Oferta 4).
- (+) Melhorias de governança fluem do uso em vários repos de volta ao harness.
- (−) Um repo a mais para manter; janela curta de congelamento no Arah durante a extração.
- Guardas anti-drift: blocos gerenciados com marcadores + `doctor-harness` acusando divergência.
- Pendência registrada: licença do harness (recomendação MIT/Apache-2.0) — ADR própria no novo repo.

## Alternativas consideradas
Copiar arquivos manualmente entre repos (drift garantido — rejeitada); template de repositório GitHub (sem atualização nem validação contínuas — rejeitada).
