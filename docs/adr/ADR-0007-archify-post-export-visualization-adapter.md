# ADR-0007 — Archify como adapter de visualização pós-export

- **Status:** Proposed
- **Data:** 2026-07-21
- **Decisores:** Sky-Forge maintainers

## Contexto

O Sky-Forge já produz artefatos arquiteturais, C4, jornadas, sequências, fluxos e pacotes verificáveis. Falta, porém, uma camada padronizada para transformar esses artefatos em visualizações técnicas interativas, portáveis e adequadas a handoff, revisão e apresentação.

O projeto externo `tt-a1i/archify` gera diagramas de arquitetura, workflow, sequência, data flow e lifecycle em HTML autônomo a partir de uma representação JSON tipada, com validação e exportação visual.

O core do Sky-Forge é agnóstico de marca e seus plugins atuais são consumidores pós-export. Portanto, integrar Archify dentro da geração do core violaria o contrato de extensibilidade existente.

## Decisão

Adotar Archify como **adapter opcional de visualização pós-export**, sem alterar a fonte da verdade arquitetural e sem introduzir hooks obrigatórios no pipeline de geração.

O fluxo será:

```text
Sky package exportado
  -> Sky Architecture IR normalizada
  -> adapter Archify
  -> Archify JSON IR
  -> validate
  -> render
  -> check
  -> HTML/SVG/PNG derivados
```

### Fonte da verdade

A fonte canônica continuará sendo o pacote Sky-Forge e a `Sky Architecture IR`. O JSON e o HTML do Archify serão artefatos derivados e regeneráveis.

### Posicionamento no fluxo

O adapter roda após `sky validate`/`sky export` e antes ou durante o handoff/showcase. Ele não participa da descoberta, decisão arquitetural ou aprovação humana.

### Modos suportados inicialmente

- `architecture`
- `workflow`
- `sequence`

`dataflow` e `lifecycle` ficam previstos para a segunda onda.

### Guardrails

1. Nenhum node ou relacionamento pode ser inventado pelo adapter.
2. Todo elemento deve carregar referência de origem quando disponível.
3. Inferências devem ser explicitamente marcadas como `inferred` e nunca como `confirmed`.
4. O adapter deve falhar de forma clara quando artefatos obrigatórios estiverem ausentes.
5. O core deve continuar passando CI com o plugin removido.
6. A versão do Archify deve ser fixada e atualizada conscientemente.
7. Saídas HTML não são editadas manualmente; devem ser regeneradas.

## Consequências positivas

- visualização técnica interativa sem acoplar o core;
- handoff arquitetural mais claro;
- melhor revisão de topologia, rotas e boundaries;
- suporte a apresentações e showcase;
- possibilidade futura de adapters paralelos para LikeC4, Mermaid e PlantUML;
- redução de lock-in por meio da Sky Architecture IR.

## Consequências negativas

- novo contrato intermediário a manter;
- necessidade de testes de mapeamento e fidelidade semântica;
- possível sobreposição visual com Cloud Design e LikeC4;
- dependência operacional de Node.js e de uma versão externa fixada.

## Alternativas rejeitadas

### Incorporar Archify ao core

Rejeitada por quebrar o princípio core agnóstico e tornar a geração dependente de uma ferramenta externa.

### Usar o JSON do Archify como modelo canônico

Rejeitada por criar lock-in e misturar semântica arquitetural com decisões de renderização.

### Substituir C4/LikeC4 por Archify

Rejeitada. Archify será uma camada de comunicação; C4 e os contratos Sky continuam representando o modelo arquitetural.

## Critérios de aceite arquiteturais

- existe schema versionado da Sky Architecture IR;
- existe plugin consumidor removível;
- a conversão é determinística para o mesmo pacote e configuração;
- as saídas registram versão do adapter e versão do Archify;
- existem fixtures e testes de contrato;
- nenhum arquivo do core depende da presença do Archify para validar ou exportar pacotes.