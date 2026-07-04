# Método dos Índices SKY — rubricas, evidência e governança

**Espec SKY**: v1.2 | **Data**: 2026-07-04 | **Licença da espec**: CC BY-SA 4.0
**Princípio**: abrir antes de prometer · evidenciar antes de pontuar · verificar antes de celebrar

Este documento é a **régua aberta** do Sky-Forge. Sem rubrica, um score é opinião
com casas decimais. Aqui está o que separa um 60 de um 80 em cada índice, que
evidências são aceitas, como a confiança é declarada e como a espec evolui.

Complementa [SKY_MERIT_INDICES.md](SKY_MERIT_INDICES.md) (visão geral e filosofia).

---

## 1. Nomes — português primeiro

| Sigla | Nome (PT) | Nome na espec (EN, para citação) | Peso |
|-------|-----------|----------------------------------|------|
| **SPI** | Prosperidade | Sky Prosperity Impact | 0.25 |
| **HCE** | Consciência | Human Consciousness Expansion | 0.20 |
| **GAP** | Alinhamento planetário | Global Alignment Potential | 0.20 |
| **CWB** | Bem-estar coletivo | Collective Wellbeing | 0.20 |
| **UXD** | Dignidade UX | UX Dignity Score | 0.15 |
| **MPI** | Posicionamento de mercado | Market Positioning Index | fora do composto |

```
SKY_SCORE = 0.25×SPI + 0.20×HCE + 0.20×GAP + 0.20×CWB + 0.15×UXD
```

### Por que cada peso

- **SPI 0.25** — prosperidade material é a promessa central da marca; recebe o maior peso.
- **HCE / GAP / CWB 0.20** — três lentes complementares de benefício coletivo, sem hierarquia entre si.
- **UXD 0.15** — condição de dignidade, não de impacto: um produto pode ser digno sem ser transformador. É o índice mais auditável e o piso de qualidade.
- **MPI fora do composto** — adicionado na v1.2; incluí-lo na fórmula invalidaria scores medidos sob v1.0/v1.1 (§6). É publicado ao lado do SKY_SCORE como lente de consciência de mercado. Um RFC futuro pode propor sua entrada no composto com recalibração dos benchmarks.

Pesos por sessão podem ser ajustados em `sky-merits.yaml → weights`, mas o dossiê
publicado **sempre declara** a versão da espec e os pesos usados.

---

## 2. Rubricas ancoradas (0–100)

Cinco faixas por índice. Um score só pode ficar numa faixa se **todos** os
descritores da faixa anterior estiverem atendidos com evidência.

### SPI — Prosperidade

| Faixa | Descritor | Contra-exemplo (não basta) |
|-------|-----------|----------------------------|
| 0–19 | Sem mecanismo identificável de prosperidade material; valor concentrado no operador. | "Gera empregos indiretos" sem mecanismo no produto. |
| 20–39 | Benefício material plausível mas não desenhado — efeito colateral, não feature. | App de vendas que "pode aumentar renda" de quem já vende. |
| 40–59 | ≥ 1 feature confirmada cujo objetivo declarado é renda, acesso ou autonomia de um grupo definido. | Feature em backlog sem confirmação do criador. |
| 60–79 | Mecanismo de prosperidade no fluxo principal + população-alvo nomeada no brief + métrica de acompanhamento definida. | Métrica "número de usuários" — não mede prosperidade. |
| 80–100 | Prosperidade é eixo co-criador: modelo de negócio distribui valor; existe checkpoint de impacto previsto vs. observado. | Doação de % do lucro — filantropia não é desenho. |

### HCE — Consciência

| Faixa | Descritor | Contra-exemplo |
|-------|-----------|----------------|
| 0–19 | Padrões de captura de atenção; opacidade sobre uso de IA/dados. | — |
| 20–39 | Neutro: não manipula, mas nada amplia reflexão, aprendizado ou conexão significativa. | "Conteúdo educativo" genérico em blog anexo. |
| 40–59 | ≥ 1 mecanismo confirmado de reflexão/educação no uso do produto (não em material paralelo). | Tooltip explicativo sem intenção pedagógica. |
| 60–79 | Separação explícita fato/inferência quando há IA; usuário entende o que o sistema faz e por quê. | Disclaimer jurídico em letra pequena. |
| 80–100 | Produto amplia agência: usuário sai mais capaz e mais consciente do que entrou; sem métricas de vício. | Gamificação de streaks — engajamento não é consciência. |

### GAP — Alinhamento planetário

| Faixa | Descritor | Contra-exemplo |
|-------|-----------|----------------|
| 0–19 | Sem relação com o catálogo de desafios ou relação negativa. | — |
| 20–39 | Conexão narrativa com ≥ 1 desafio do catálogo, sem feature associada. | Citação de ODS no pitch. |
| 40–59 | `humanity_connections` com feature real ligada a desafio do catálogo, `ai_suggested` confirmado. | Conexão sugerida pela IA e nunca confirmada. |
| 60–79 | ≥ 2 conexões confirmadas + frugalidade operacional considerada (dados mínimos, funciona em rede lenta/aparelho modesto). | Data center "verde" com app que exige flagship. |
| 80–100 | Desafio planetário é requisito de produto com critério de aceite; pegada operacional medida (tokens/sessão, minimização de dados). | Compensação de carbono comprada. |

O catálogo é neutro ([challenges-catalog.yaml](../humanity/challenges-catalog.yaml)) —
alinhamento não é agenda partidária. A **frugalidade regenerativa** (custo
energético por sessão, acessibilidade em hardware antigo) pontua dentro do GAP e
alimenta o SPI via acesso.

### CWB — Bem-estar coletivo

| Faixa | Descritor | Contra-exemplo |
|-------|-----------|----------------|
| 0–19 | Dinâmicas de competição predatória, polarização ou isolamento. | — |
| 20–39 | Individual: resolve bem para uma pessoa, sem dimensão coletiva. | "Comunidade" = seção de comentários. |
| 40–59 | ≥ 1 mecanismo confirmado de cooperação, cuidado ou coesão entre usuários. | Leaderboard — ranking não é coesão. |
| 60–79 | Grupo/território beneficiado nomeado; produto fortalece vínculo existente (não substitui por mediação da plataforma). | Marketplace que desintermedia relações locais. |
| 80–100 | Bem-estar coletivo tem métrica própria acompanhada; existe caminho de saída digno (dados portáveis, sem lock-in social). | — |

### UXD — Dignidade UX

O índice mais auditável — critérios binários verificáveis no artefato:

| Faixa | Descritor |
|-------|-----------|
| 0–19 | Dark patterns presentes; contraste abaixo de AA em fluxo principal. |
| 20–39 | Sem dark patterns, mas: cores hardcoded, sem mobile, excitação alta (urgência artificial, badges pulsantes). |
| 40–59 | Tokens de design definidos; mobile-first declarado; alvo WCAG AA registrado no `ux-spec.yaml`. |
| 60–79 | Verificado: contraste AA nos fluxos principais, `prefers-reduced-motion` respeitado, foco visível de teclado, estados (vazio, carregando, erro) especificados. |
| 80–100 | Auditoria de acessibilidade executada (ferramenta + manual); baixa excitação comprovada; tipografia mínima ≥ 11.5px em texto informativo. |

Checklist binário da faixa 60+: `contraste AA` · `reduced-motion` · `focus-visible` ·
`estados especificados` · `sem dark patterns` · `tokens sem hardcode`.

### MPI — Posicionamento de mercado

Mede **consciência de posicionamento**, não ineditismo. Três eixos: novidade
vs. soluções existentes (comerciais e open-source), qualidade da diferenciação
declarada e cobertura consciente das lacunas do segmento. A evidência primária
é o artefato `market-benchmark.yaml` (agente `market-benchmark`), com fontes
citadas (`external`) e vereditos por eixo funcional (novo / melhor / paridade).

| Faixa | Descritor | Contra-exemplo (não basta) |
|-------|-----------|----------------------------|
| 0–19 | Nenhum levantamento de mercado; proposta duplica solução existente sem saber. | "Não tem concorrente" declarado sem pesquisa. |
| 20–39 | Concorrentes citados de memória, sem fontes; diferenciação declarada mas não comparada eixo a eixo. | Lista de nomes sem URL nem nota de sobreposição. |
| 40–59 | Benchmark com fontes citadas (≥ 3 iniciativas, incluindo ≥ 1 open-source); veredito novo/melhor/paridade por eixo funcional principal. | Comparar só com players comerciais ignorando open-source. |
| 60–79 | Benchmark cobre comercial + open-source + adjacentes; lacunas do segmento identificadas e registradas como sugestões `ai_suggested`; diferenciação sustentada por evidência (não adjetivo). | Lacunas identificadas mas não registradas como sugestão rastreável. |
| 80–100 | Posicionamento revisitado por ciclo (espiral §7); lacunas decididas pelo criador (aceitas ou recusadas com registro); diferencial validado externamente (usuários, mercado, tração). | Benchmark feito uma vez e nunca reavaliado. |

Guardrails próprios do MPI:

- Veredito "paridade" **não é demérito** — paridade consciente pontua mais que "novidade" ignorante.
- Sugestões de lacuna seguem a trilha `ai_suggested → user_confirmed → evidenced` (§4); registrar a lacuna **não** altera o escopo nem pressiona o criador.
- Fontes sempre citadas; benchmark sem fonte é opinião, não evidência.

---

## 3. Evidência e confiança

### Tipos de evidência aceitos

| Tipo | Exemplo | Peso relativo |
|------|---------|---------------|
| `intake` | Trecho da conversa em que o criador confirma | médio |
| `artifact` | Campo em brief/RF/ux-spec/nfr com `user_confirmed` | alto |
| `external` | Documento, pesquisa ou dado de mercado citado | médio |
| `verified` | Medição pós-lançamento (checkpoint 90/180 dias) | máximo |

### Banda de confiança

Todo score publicado declara origem e incerteza: **"SPI 81 ±9 · 6 evidências"**.

| Confiança | Critério | Exibição |
|-----------|----------|----------|
| `high` | ≥ 4 evidências, ≥ 2 do tipo `artifact` | score exato ± banda |
| `medium` | 2–3 evidências | score ± banda alargada |
| `low` | 0–1 evidência | **faixa provável** (ex.: "40–59"), nunca número exato |

Um intake de quatro mensagens **não** produz SKY_SCORE exato — produz faixa.

### Score de intenção vs. impacto verificado

Todo índice publicado antes do lançamento é **score de intenção**. O dossiê
público deve rotular assim. Após checkpoints de 90/180 dias (previsto vs.
observado), scores reavaliados com evidência `verified` ganham o selo
**impacto verificado**. As rubricas são recalibradas com esses dados.

---

## 4. Elevação sem atalho de pontos

Aceitar uma sugestão de elevação **não credita pontos**. A trilha completa é:

```
ai_suggested → user_confirmed → evidenced
```

1. `ai_suggested` — a IA propõe; nada muda no score.
2. `user_confirmed` — vira **requisito rastreado** (RF ou item de roadmap); score ainda não sobe.
3. `evidenced` — a evidência aparece no artefato (feature especificada com critério de aceite); só então o índice reflete o ganho.

Cada decisão (confirmado, só documentado, recusado) entra no **ledger da sessão**
(`approvals.yaml` + `.sky/audit/{slug}/events.jsonl`): o quê, quem, quando, com
que resposta. A permissão é evidência, não rodapé.

---

## 5. Dimensão de sustentação — rubrica dupla

A dimensão `sustainability` do modelo de maturidade avalia **duas coisas distintas**,
sempre com a evidência que gerou a nota:

| Lente | O que avalia |
|-------|--------------|
| **Negócio** | Unit economics plausíveis, dependências críticas nomeadas, concentração de receita, escada de valor definida (ver `docs/tiers/`) |
| **Operação** | Custo por sessão (inferência, infra), resiliência a falha de provedor, frugalidade (tokens/sessão, dados mínimos) |

Nota sem critério publicado não entra em dossiê público.

---

## 6. Governança da espec

Mudanças silenciosas invalidariam todos os scores anteriores. Regras:

1. **Versionamento** — a espec tem versão (`SKY v1.1`); todo `sky-merits.yaml` e todo dossiê publicado carimbam `spec_version`.
2. **Mudança por RFC** — alterar rubrica, peso ou fórmula requer proposta registrada (issue/PR pública com racional), nunca edição silenciosa.
3. **Changelog da espec** — cada versão lista o que mudou e por quê (seção abaixo).
4. **Casos-benchmark** — sessões de calibração (`templates/sessions/`) mantêm scores esperados; uma mudança de espec que altere um benchmark exige justificativa no RFC.
5. **Reprodutibilidade** — o harness (`scripts/sky/validate-*.ps1`) é open source: qualquer terceiro pode reproduzir a verificação de um pacote.

A fronteira aberto/comercial: a **régua** (espec, rubricas, harness, schemas) é
aberta; a **execução** (agentes completos, export Cloud Design, hosting,
white-label) é o que se comercializa.

### Changelog da espec SKY

| Versão | Data | Mudança |
|--------|------|---------|
| v1.0 | 2026-07-04 | Cinco índices, pesos, níveis Ground/Rise/Horizon/Sky. |
| v1.1 | 2026-07-04 | Rubricas ancoradas por índice; tipos de evidência e bandas de confiança; trilha `ai_suggested → user_confirmed → evidenced`; rubrica dupla de sustentação; nomes PT-primeiro; governança por RFC. |
| v1.2 | 2026-07-04 | Índice **MPI** (Market Positioning Index) com rubrica ancorada — novidade vs. mercado/open-source, diferenciação e cobertura de lacunas; agente `market-benchmark` e artefato `market-benchmark.yaml`; MPI fica **fora do SKY_SCORE** para não invalidar scores v1.0/v1.1 (entrada no composto exigiria RFC com recalibração de benchmarks). |

---

## 7. Espiral, não esteira

O funil não termina no export. O ciclo se fecha:

```
intenção → intake → elevação → especificação → export → realidade
   ↑                                                        │
   └────────────── re-intake (o que mudou?) ────────────────┘
```

- Cada sessão mantém **linha do tempo de ciclos** com delta de score ("SKY 58 → 72").
- **Checkpoints de impacto** aos 90 e 180 dias pós-lançamento: previsto vs. observado.
- O showcase distingue score de intenção de impacto verificado.
- `learn-from-outcome` retroalimenta rubricas e benchmarks.

---

## Referências

- [SKY_MERIT_INDICES.md](SKY_MERIT_INDICES.md) — visão geral e filosofia
- [MATURITY_MODEL.md](MATURITY_MODEL.md) — dimensões e pipeline unlock
- [sky-merits.schema.yaml](../schemas/sky-merits.schema.yaml) — schema com evidência e confiança
- [EVOLUTION_AUDIT.md](EVOLUTION_AUDIT.md) — os 23 achados que originaram a v1.1
