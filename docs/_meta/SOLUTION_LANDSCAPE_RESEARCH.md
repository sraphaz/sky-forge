# Solution Landscape Research — Sky-Forge

**Versão:** 0.1  
**Status:** proposta operacional  
**Objetivo:** transformar pesquisa externa em evidência arquitetural antes da proposição da solução.

## 1. Problema que esta etapa resolve

O benchmark de mercado responde **quem já resolve** e **como a proposta se posiciona**. A pesquisa de paisagem de soluções responde uma pergunta diferente:

> Quais classes de solução, padrões, modelos operacionais e componentes já provaram resolver este tipo de problema — e em quais condições cada alternativa é adequada?

A etapa evita três falhas recorrentes:

1. desenhar arquitetura cedo demais a partir da primeira ideia disponível;
2. tratar produto concorrente, padrão arquitetural e modelo operacional como se fossem a mesma coisa;
3. recomendar tecnologia sem explicitar contexto, evidência, limites e trade-offs.

## 2. Posição no método

A etapa é executada depois que o problema e os requisitos essenciais estão claros, e antes da arquitetura-alvo.

```text
intake
  → problem framing
  → elevation + UX discovery
  → market benchmark
  → solution landscape research
  → option framing + decision gate
  → architecture proposition
  → delivery planning
```

Ela é um **gate metodológico obrigatório** para propostas classificadas como `growth`, `enterprise`, `regulated`, `high-uncertainty` ou `novel-domain`. Para MVPs simples, pode operar em modo `light`, mas nunca ser omitida silenciosamente.

## 3. Escopo da pesquisa

A pesquisa deve procurar e separar evidências em seis lentes:

1. **Soluções de referência** — produtos comerciais, serviços, plataformas e projetos open-source.
2. **Padrões arquiteturais** — monólito modular, eventos, workflows, agentes, RAG, regras, otimização, streaming, edge, entre outros aplicáveis.
3. **Modelos de solução** — SaaS, self-hosted, managed service, marketplace, human-in-the-loop, copilot, automation-first, API-first e outros.
4. **Modelos de implementação** — build, buy, adopt, extend, integrate, partner ou combinação.
5. **Modelos operacionais** — centralizado, federado, platform team, product teams, repo-first, control plane/data plane e equivalentes.
6. **Modelos de IA e computação** — classes de modelos, ferramentas, algoritmos ou técnicas adequadas ao problema, sem confundir modelo fundacional com solução completa.

## 4. Perguntas obrigatórias

A pesquisa deve responder:

- Qual é a taxonomia real do problema?
- Quais abordagens já são usadas para essa classe de problema?
- Em quais contextos cada abordagem funciona ou falha?
- Quais são os requisitos que discriminam uma alternativa da outra?
- O que pode ser comprado, adotado, integrado ou precisa ser construído?
- Quais dependências, lock-ins, riscos e custos de mudança existem?
- Quais modelos de IA, algoritmos ou mecanismos são plausíveis e por quê?
- Quais hipóteses ainda precisam de experimento, spike ou prova de conceito?
- Quais alternativas devem seguir para decisão arquitetural?

## 5. Artefatos

### `solution-landscape.yaml`

Contrato mínimo:

```yaml
spec_version: "0.1"
problem_taxonomy:
  primary_class: ""
  adjacent_classes: []
  discriminating_requirements: []

research_scope:
  mode: light | standard | deep
  searched_at: ""
  freshness_window_days: 180
  sources: []

solution_archetypes:
  - id: ""
    name: ""
    description: ""
    suitable_when: []
    unsuitable_when: []
    strengths: []
    tradeoffs: []
    evidence_refs: []

implementation_models:
  - model: build | buy | adopt | extend | integrate | partner | hybrid
    candidate: ""
    fit: low | medium | high
    rationale: ""
    constraints: []
    evidence_refs: []

computational_models:
  - class: ""
    examples: []
    problem_fit: ""
    prerequisites: []
    limitations: []
    evaluation_needed: []
    evidence_refs: []

shortlist:
  - option_id: ""
    composition: []
    why_shortlisted: ""
    key_tradeoffs: []
    validation_required: []

research_gaps: []
confidence: low | medium | high
```

### `solution-options.yaml`

Contém de duas a cinco alternativas compostas, prontas para decisão. Cada opção deve declarar:

- escopo e fronteiras;
- componentes principais;
- modelo build/buy/adopt;
- modelo operacional;
- custo e complexidade relativos;
- riscos e reversibilidade;
- requisitos atendidos e não atendidos;
- experimentos necessários;
- fontes e confiança.

### `solution-decision.md`

Registro humano da decisão, incluindo alternativa escolhida, alternativas rejeitadas, critérios, trade-offs aceitos e condições para reavaliar.

## 6. Relação com agentes existentes

| Agente | Responsabilidade |
|---|---|
| `market-scout` | coleta sinais de mercado e stack |
| `market-benchmark` | posicionamento competitivo e MPI |
| `solution-landscape-researcher` | taxonomia do problema, arquétipos, modelos e evidências técnicas |
| `solutions-architect` | compõe opções e propõe arquitetura-alvo após o gate |
| `cost-tier-advisor` | custos relativos e tier |
| `security-compliance` | restrições regulatórias e de segurança |
| `test-architect` | estratégia de validação, spikes e testes de decisão |

O novo agente pode reutilizar fontes dos agentes de mercado, mas não deve transformar popularidade em adequação técnica.

## 7. Gate de decisão

A arquitetura não deve avançar para estado `proposed` enquanto não houver:

- taxonomia do problema;
- pelo menos duas alternativas viáveis, salvo impossibilidade documentada;
- evidência citada;
- trade-offs e condições de falha;
- decisão humana ou política explícita de autonomia;
- gaps convertidos em pesquisa, spike, ADR ou requisito.

Estados sugeridos:

```text
not_started → researching → options_ready → decision_pending → decided → superseded
```

## 8. Qualidade e guardrails

- Fonte citada ou a afirmação permanece hipótese.
- Evidência primária e documentação oficial têm precedência.
- Recência deve ser registrada; tecnologia descontinuada não pode aparecer como recomendação atual sem alerta.
- Ranking absoluto é proibido: adequação depende de contexto.
- A pesquisa deve incluir alternativas não baseadas em IA quando forem melhores.
- Modelo de IA não é arquitetura completa.
- Build não é a opção padrão; buy não é a opção padrão.
- Lock-in, privacidade, soberania, operação e reversibilidade devem ser explícitos.
- Toda recomendação deve distinguir fato, inferência e hipótese.

## 9. Modos de execução

### Light

Para MVP de baixo risco: taxonomia, três arquétipos, shortlist e gaps. Pesquisa rápida, mas citada.

### Standard

Para produto real: todas as lentes, matriz de decisão, riscos, custos relativos e spikes.

### Deep

Para domínios regulados, alto investimento ou alta novidade: literatura técnica, padrões de indústria, análise de fornecedores, TCO preliminar, segurança, governança e experimentos comparativos.

## 10. Critérios de aceite da primeira implementação

1. Novo agente e regra operacional versionados.
2. `sky plan` posiciona a etapa antes de `solutions-architect`.
3. Pacote exportado contém `solution-landscape.yaml`, `solution-options.yaml` e `solution-decision.md` quando aplicável.
4. Validador bloqueia arquitetura sem decisão ou waiver documentado.
5. Showcase exibe alternativas, evidências, decisão e gaps sem expor dados sensíveis.
6. Pelo menos uma fixture demonstra `build`, `buy` e `hybrid`.
7. Roadmap e documentação do fluxo refletem o novo gate.
