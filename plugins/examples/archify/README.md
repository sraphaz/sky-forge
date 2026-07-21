# Archify Visualization Adapter

Adapter opcional que consome um pacote Sky-Forge exportado e produz diagramas técnicos interativos por meio do `tt-a1i/archify`.

## Princípio

```text
Sky package -> Sky Architecture IR -> Archify JSON -> validate -> render -> check
```

O adapter não decide arquitetura, não altera o pacote de origem e não adiciona hooks ao core.

## Dependência

Fixar uma versão explícita do Archify. Versão inicial recomendada para a implementação:

```text
tt-a1i/archify@2.11.0
```

A instalação pode ser local ao adapter, via submodule, pacote empacotado ou cache de CI. A escolha deve preservar builds reproduzíveis e permitir execução offline após bootstrap.

## Interface de linha de comando esperada

```powershell
./plugins/examples/archify/scripts/visualize.ps1 `
  -PackagePath <exported-package> `
  -OutputPath <destination> `
  -Views architecture,workflow,sequence `
  -Quality standard
```

Interface Node equivalente:

```bash
node plugins/examples/archify/scripts/visualize.mjs \
  --package <exported-package> \
  --output <destination> \
  --views architecture,workflow,sequence \
  --quality standard
```

## Etapas

1. validar a existência dos artefatos obrigatórios;
2. normalizar o pacote em `intermediate/sky-architecture-ir.yaml`;
3. validar a IR contra `schemas/sky-forge/sky-architecture-ir.schema.yaml`;
4. converter cada view selecionada para o schema correspondente do Archify;
5. executar `archify validate`;
6. executar `archify render`;
7. executar `archify check` no HTML produzido;
8. gerar `archify/manifest.yaml` com hashes, versões, fontes e resultados das validações.

## Manifesto mínimo

```yaml
adapter:
  id: archify-visualization
  version: 0.1.0
renderer:
  name: archify
  version: 2.11.0
source:
  package_slug: example
  package_hash: sha256:...
outputs:
  - view: system
    type: architecture
    json: archify/system.architecture.json
    html: archify/system.architecture.html
    validation: passed
```

## Regras de fidelidade

- `confirmed` exige `source_refs` não vazio;
- `inferred` deve ser visualmente distinguível e listado no manifesto;
- relações sem origem e destino existentes bloqueiam a geração;
- o adapter não cria tecnologias, protocolos, trust boundaries ou integrações ausentes;
- uma view pode omitir detalhes para legibilidade, mas não pode alterar o significado;
- o HTML é artefato derivado e nunca deve receber edição manual.

## Saídas iniciais

- `system.architecture.html`
- `delivery.workflow.html`
- `critical-path.sequence.html`, somente quando houver evidência suficiente

## Testes obrigatórios

- package mínimo válido;
- package completo válido;
- artefato obrigatório ausente;
- endpoint de relacionamento inexistente;
- elemento confirmado sem evidência;
- elemento inferido corretamente sinalizado;
- execução determinística;
- ausência do diretório do plugin não quebra o core;
- falha do Archify retorna código diferente de zero e mensagem acionável.
