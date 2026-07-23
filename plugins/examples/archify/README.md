# Archify Visualization Adapter

Adapter opcional que consome um pacote Sky-Forge exportado e produz diagramas técnicos interativos por meio do `tt-a1i/archify`.

## Princípio

```text
Sky package -> Sky Architecture IR -> Archify JSON -> validate -> render -> check
```

O adapter não decide arquitetura, não altera o pacote de origem e não adiciona hooks ao core.

## Dependência (versão fixada)

```text
tt-a1i/archify@2.11.0
commit: ed0efcc763d358b78df845182b5ed24a9d165a1c
```

Pin em `ARCHIFY.lock.json`. O runtime fica em `.vendor/` (gitignored) após bootstrap explícito.

```powershell
cd plugins/examples/archify
npm install
node scripts/bootstrap-archify.mjs
```

Resolução em runtime:

1. `ARCHIFY_HOME` (diretório skill com `bin/archify.mjs`)
2. `plugins/examples/archify/.vendor/archify/archify`
3. erro acionável pedindo bootstrap — sem download silencioso

## Interface

```powershell
./plugins/examples/archify/scripts/visualize.ps1 `
  -PackagePath <exported-package> `
  -OutputPath <destination> `
  -Views architecture,workflow,sequence `
  -Quality standard
```

```bash
node plugins/examples/archify/scripts/visualize.mjs \
  --package <exported-package> \
  --output <destination> \
  --views architecture,workflow,sequence \
  --quality standard
```

Integração opcional Sky CLI:

```powershell
./scripts/sky/sky.ps1 visualize `
  -PackagePath examples/sky-forge-packages/surya-workspace-mvp `
  -Renderer archify `
  -Views architecture,workflow,sequence
```

Se o plugin estiver ausente, `sky visualize` orienta a instalação e **não** quebra o core.

## Etapas

1. validar artefatos obrigatórios (`brief.yaml`, `architecture.yaml`);
2. normalizar `intermediate/sky-architecture-ir.yaml`;
3. validar a IR;
4. mapear views selecionadas para JSON Archify;
5. `archify validate` / `render` / `check`;
6. gerar `archify/manifest.yaml`.

Nota: Archify 2.11.0 **não** expõe `--quality`. O perfil `standard|showcase` é gravado na IR/manifesto e não é passado à CLI externa.

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
  public_authorized: false
outputs:
  - view: system
    type: architecture
    json: archify/system.architecture.json
    html: archify/system.architecture.html
    validation: passed
```

## Regras de fidelidade

- `confirmed` exige `source_refs` não vazio;
- `inferred` é listado no manifesto e marcado no diagrama (`tag: inferred` / edges dashed);
- relações sem endpoints existentes bloqueiam a geração;
- o adapter não inventa tecnologias, protocolos, trust boundaries ou integrações;
- layout Archify (grid `row`/`col`) existe só no JSON derivado, nunca na IR;
- HTML é derivado e não deve ser editado manualmente.

## Saídas iniciais

- `system.architecture.html`
- `delivery.workflow.html` (quando houver gates/milestones)
- `critical-path.sequence.html` (quando houver `sequences.yaml`)

## Testes

```powershell
cd plugins/examples/archify
npm test
```

## Troubleshooting

| Sintoma | Ação |
|---------|------|
| `Archify runtime not found` | Rodar `node scripts/bootstrap-archify.mjs` ou exportar `ARCHIFY_HOME` |
| `Missing required artifacts` | Garantir `brief.yaml` + `architecture.yaml` no pacote |
| `sequence omitted` | Adicionar `sequences.yaml` com participants + steps |
| `workflow omitted` | Incluir `package.yaml` gates e/ou milestones em `handoff-solution.yaml` |
| `archify validate` ≠ 0 | Corrigir o JSON derivado regenerando; não editar HTML |
| Plugin ausente e `sky visualize` | Esperado — mensagem de orientação, exit 0 |

## Remoção

Apagar `plugins/examples/archify` não deve quebrar `sky validate`, `sky export` nem `check-core-agnostic.ps1`.
