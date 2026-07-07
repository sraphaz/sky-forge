<!-- TEMPLATE do plugin — registro de gate de aprovação (uma página por gate).
     Gera o documento que evidencia a passagem; o registro canônico é o approval-ledger. -->

REGISTRO DE GATE · SURYA LABS
{{ approval.id }} · {{ demand.id }}

# Gate: {{ approval.gate_name }}

| Campo | Valor |
|---|---|
| Demanda | {{ demand.title }} ({{ demand.id }}) |
| Gate | `{{ approval.gate }}` |
| O que este gate libera | {{ approval.unblocks }} |
| Documento exigido | {{ approval.document_ref }} |
| Hash do documento | `{{ approval.document_sha256 }}` |
| Decidido por | {{ approval.approved_by }} ({{ approval.role_at_time }}) |
| Data | {{ approval.at }} |
| Status | {{ approval.status }} |

## O que foi conferido

{{#each approval.checks}}
- [x] {{ this }}
{{/each}}

## Notas da decisão

{{ approval.notes }}

<!-- Bloco fixo — não remover -->
Regras deste registro:
- Aprovação é sempre de identidade humana; agentes não aprovam.
- Este registro é append-only no ledger — correção gera novo registro com `supersedes`.
- `waived` exige justificativa escrita e aparece como exceção no histórico da demanda.

Registrado no approval-ledger da demanda em {{ approval.recorded_at }}.
