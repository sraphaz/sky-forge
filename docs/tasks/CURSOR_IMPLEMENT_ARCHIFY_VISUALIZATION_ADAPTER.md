# Demanda para o Cursor — implementar o Archify Visualization Adapter

## Missão

Implemente no Sky-Forge um adapter opcional pós-export para gerar visualizações técnicas usando `tt-a1i/archify`, preservando o core agnóstico e a arquitetura definida em:

- `docs/adr/ADR-0007-archify-post-export-visualization-adapter.md`
- `plugins/examples/archify/plugin.yaml`
- `plugins/examples/archify/README.md`
- `schemas/sky-forge/sky-architecture-ir.schema.yaml`

Não reduza a demanda a documentação. Entregue código executável, fixtures, testes, comandos e integração não obrigatória com o fluxo de export.

## Resultado esperado

Dado um pacote Sky-Forge já exportado, deve ser possível executar:

```powershell
./plugins/examples/archify/scripts/visualize.ps1 `
  -PackagePath examples/sky-forge-packages/surya-workspace-mvp `
  -OutputPath .tmp/archify/surya-workspace-mvp `
  -Views architecture,workflow,sequence `
  -Quality standard
```

Ou a interface Node equivalente:

```bash
node plugins/examples/archify/scripts/visualize.mjs \
  --package examples/sky-forge-packages/surya-workspace-mvp \
  --output .tmp/archify/surya-workspace-mvp \
  --views architecture,workflow,sequence \
  --quality standard
```

A execução deve produzir uma Sky Architecture IR validada, arquivos JSON compatíveis com Archify, HTMLs renderizados e um manifesto de proveniência.

## Restrições obrigatórias

1. Não adicionar Archify como dependência obrigatória do core.
2. Não alterar decisões arquiteturais durante a conversão.
3. Não usar o JSON do Archify como fonte canônica.
4. Não criar hooks de plugin dentro da geração.
5. Não quebrar os comandos existentes de `sky validate`, `sky export` ou `check-core-agnostic`.
6. Não editar HTML gerado manualmente.
7. Fixar a versão do Archify; não usar referência flutuante para `main`.
8. Não publicar pacote ou diagrama sem aprovação pública já existente no pacote.
9. Não inventar nodes, relações, protocolos, tecnologias ou boundaries.
10. Não silenciar falhas de validação do Archify.

## Escopo funcional

### 1. Normalizador Sky Package -> Sky Architecture IR

Crie um módulo que leia, conforme disponibilidade:

- `brief.yaml`
- `architecture.yaml`
- `sequences.yaml`
- `integrations.yaml`
- `ux-spec.yaml`
- `agentic-repo-recommendation.yaml`

O módulo deve gerar:

```text
<output>/intermediate/sky-architecture-ir.yaml
```

Cada elemento e relação deve conter:

- ID estável;
- tipo semântico;
- confidence: `confirmed`, `inferred` ou `unknown`;
- `source_refs` com JSON Pointer, YAML path ou referência equivalente;
- tags necessárias ao renderer, sem inserir campos visuais na IR.

Não trate a ausência de artefatos opcionais como erro. A ausência de `architecture.yaml` ou `brief.yaml` deve bloquear a execução com mensagem acionável.

### 2. Validação da IR

Implemente validação para o contrato em `schemas/sky-forge/sky-architecture-ir.schema.yaml`.

No mínimo, valide:

- unicidade de IDs;
- endpoints de relações existentes;
- membros de boundaries existentes;
- referências de views existentes;
- `confirmed` com ao menos um `source_ref`;
- ausência de campos específicos de layout/renderização;
- views vazias ou sem pergunta respondida.

Retorne código diferente de zero para erro bloqueante.

### 3. Mapeadores para Archify

Implemente inicialmente:

- `architecture`;
- `workflow`;
- `sequence`.

Estrutura sugerida:

```text
plugins/examples/archify/
├── plugin.yaml
├── README.md
├── scripts/
│   ├── visualize.mjs
│   └── visualize.ps1
├── src/
│   ├── load-package.mjs
│   ├── normalize-ir.mjs
│   ├── validate-ir.mjs
│   ├── manifest.mjs
│   └── mappers/
│       ├── architecture.mjs
│       ├── workflow.mjs
│       └── sequence.mjs
├── tests/
│   ├── fixtures/
│   └── *.test.mjs
└── package.json
```

A arquitetura default deve ser uma visão limitada e legível, preferencialmente entre 8 e 12 nodes primários. Elementos secundários podem ser omitidos da view, mas devem continuar presentes na IR quando existirem no pacote.

### 4. Execução do Archify

Use a CLI oficial do Archify para cada saída:

```bash
node <archify>/bin/archify.mjs validate <type> <input-json> --quality <profile> --json
node <archify>/bin/archify.mjs render <type> <input-json> <output-html>
node <archify>/bin/archify.mjs check <output-html>
```

Implemente resolução configurável da instalação, nesta ordem:

1. `ARCHIFY_HOME`;
2. caminho local versionado/cacheado documentado pelo adapter;
3. mensagem de bootstrap clara, sem download implícito silencioso.

Não faça clone ou download de dependência durante uma execução normal sem consentimento explícito.

### 5. Manifesto

Gerar:

```text
<output>/archify/manifest.yaml
```

Com:

- versão do adapter;
- versão do Archify;
- hash do pacote de origem;
- data/hora;
- views solicitadas;
- arquivos produzidos;
- hash de cada saída;
- status de `validate`, `render` e `check`;
- lista de inferências;
- lista de artefatos opcionais ausentes;
- indicador de autorização pública herdado do pacote.

### 6. Integração com Sky CLI

Implemente uma integração opcional e fina, sem mover o adapter para o core.

Forma desejada:

```powershell
./scripts/sky/sky.ps1 visualize `
  -Slug <slug> `
  -Renderer archify `
  -Views architecture,workflow,sequence `
  -Quality standard
```

Caso isso exija acoplamento indevido, implemente um wrapper em `scripts/sky/visualize.ps1` que apenas delegue ao plugin e documente o comando. O `sky.ps1` não deve falhar quando o plugin estiver ausente; deve retornar uma mensagem orientando instalação/uso opcional.

### 7. Fixtures e testes

Use como fixture inicial uma cópia mínima e estável derivada de:

```text
examples/sky-forge-packages/surya-workspace-mvp
```

Cubra obrigatoriamente:

1. pacote mínimo válido;
2. pacote completo válido;
3. ausência de `architecture.yaml`;
4. relação com endpoint inexistente;
5. elemento `confirmed` sem `source_refs`;
6. elemento `inferred` preservado e registrado no manifesto;
7. view architecture gerada;
8. workflow gerado quando houver evidência;
9. sequence omitida com warning quando não houver evidência;
10. falha da validação Archify propagada;
11. output determinístico, desconsiderando timestamp controlado;
12. remoção de `plugins/examples/archify` não quebra o core.

Use o mecanismo de testes já adotado pelo repositório quando existir. Caso não exista para Node, use `node:test` para evitar framework adicional.

## Segurança e privacidade

- respeite o estado público/privado do pacote;
- nunca copie segredos ou valores de ambiente para diagramas;
- sanitize URLs com tokens, credentials, connection strings e identificadores sensíveis;
- não inclua conteúdo integral de prompts internos como cards;
- trate HTML como output privado por padrão;
- inclua teste de sanitização.

## Observabilidade

A CLI deve exibir etapas de alto nível:

```text
[sky-archify] load package
[sky-archify] normalize IR
[sky-archify] validate IR
[sky-archify] map architecture
[sky-archify] archify validate
[sky-archify] archify render
[sky-archify] archify check
[sky-archify] write manifest
```

Em modo `--json`, retornar resumo estruturado para agentes e CI.

## Critérios de aceite

A demanda só está concluída quando:

- [ ] o comando Node funciona em Windows, Linux e macOS;
- [ ] o wrapper PowerShell funciona no Windows;
- [ ] a IR é gerada e validada;
- [ ] ao menos uma fixture produz architecture HTML válido;
- [ ] workflow é produzido a partir de evidência real;
- [ ] sequence é produzida ou omitida de maneira explicável;
- [ ] `archify validate`, `render` e `check` são executados;
- [ ] erros retornam código não zero;
- [ ] manifesto registra proveniência e hashes;
- [ ] testes automatizados passam;
- [ ] `check-core-agnostic.ps1` continua passando;
- [ ] documentação inclui bootstrap e troubleshooting;
- [ ] nenhuma dependência obrigatória foi introduzida no core;
- [ ] nenhum artefato confirmado foi criado sem evidência.

## Entrega esperada do Cursor

Ao finalizar:

1. apresente a árvore de arquivos criada/alterada;
2. liste decisões técnicas tomadas;
3. mostre comandos executados;
4. mostre resultados dos testes;
5. registre limitações ou itens para Onda 2 (`dataflow`, `lifecycle`, showcase e adapters alternativos);
6. atualize este documento marcando os critérios realmente atendidos, sem declarar sucesso para itens não verificados.

## Onda 2 — fora do escopo desta implementação

- mapper `dataflow`;
- mapper `lifecycle`;
- upload/publicação automática em showcase;
- edição WYSIWYG;
- substituição de C4 ou LikeC4;
- geração de arquitetura a partir apenas de texto livre;
- alterações na lógica de decisão dos agentes arquiteturais.
