# Jornada do usuário Sky-Forge

**Versão**: 1.1 | **Data**: 2026-07-04

Mapa de experiência para **sky-host** e agentes especializados. O usuário nunca deve adivinhar o próximo passo.

## Princípios de UX

1. **Lacunas primeiro** — home e projeto mostram "próxima lacuna" antes de visão longa; rota `/projects/{slug}/lacunas/`.
2. **Uma decisão por vez** — nunca export + publish + showcase no mesmo turno.
3. **Progresso visível** — sempre mostrar fase atual e % de maturidade.
4. **Linguagem humana primeiro** — YAML e comandos só depois da explicação.
5. **Privacidade por padrão** — pacotes externos; publicação é opt-in explícito.
6. **Celebrar sem hype** — tom calmo, baixa excitação (alinhado a UXD).
7. **Sempre oferecer saída** — "posso voltar depois", "manter privado", "só exportar".

## Fases da jornada

```
┌─────────┐   ┌─────────┐   ┌──────────┐   ┌────────────┐   ┌─────────┐   ┌───────────┐   ┌─────────────┐
│ Chegada │ → │  Shape  │ → │ Elevar   │ → │ Especificar│ → │ Entregar│ → │ Apresentar│ → │ Implementar │
│ sky-host│   │ intake  │   │ SKY + UX │   │ arquitetura│   │ delivery│   │ showcase  │   │ repo-scaff. │
└─────────┘   └─────────┘   └──────────┘   └────────────┘   └─────────┘   └───────────┘   └─────────────┘
```

| Fase | ID | Agente principal | Gatilho de entrada |
|------|-----|------------------|-------------------|
| Chegada | `arrival` | sky-host | Qualquer mensagem sem slug |
| Dar forma | `shape` | intake-conductor | Nova ideia / zip / brownfield |
| Elevar | `elevate` | sky-elevator + ux-design-specialist | business ≥ 0.65, product ≥ 0.50 |
| Especificar | `specify` | solutions-architect + market-scout | product ≥ 0.70 |
| Entregar | `deliver` | delivery-steward | readiness ≥ 0.55 (partial) |
| Apresentar | `showcase` | showcase-curator | Após export OU pedido explícito |
| Implementar | `implement` | repo-scaffolder + prompt-assembler | Pacote exportado |

## Mensagem tipo do sky-host (chegada)

```
Bem-vindo ao Sky-Forge.

Onde você está:
  · Sessão: iautos
  · Maturidade: 78%
  · Fase: Entregar → você pode exportar o pacote agora

O que posso fazer por você agora (escolha uma):
  1) Preencher lacuna — benchmark RF-014 (prazos processuais)
  2) Exportar pacote para pasta externa (privado)
  3) Ver todas as lacunas no showcase (/projects/iautos/lacunas/)
  4) Publicar preview visual no showcase (opt-in)

Responda com o número ou descreva em suas palavras.
```

## Handoffs entre agentes

| De | Para | Quando |
|----|------|--------|
| sky-host | intake-conductor | Ideia nova, lacunas de maturidade, brownfield |
| intake-conductor | sky-elevator | Fase elevate; `open_to_elevation: true` |
| intake-conductor | delivery-steward | `overall_readiness ≥ 0.55` e usuário quer pacote |
| delivery-steward | showcase-curator | Export concluído; usuário quer visão pública |
| delivery-steward | repo-scaffolder | Usuário quer começar código |
| showcase-curator | sky-host | Após publish; retomar jornada |

## Privacidade (delivery-steward + showcase-curator)

Perguntar **antes** de `publish -Public`:

1. "O brief contém dados de clientes ou segredo profissional?"
2. "Quer que apareça no site público do Sky-Forge ou só na sua máquina?"
3. Se sensível → recomendar `SKY_OUTPUTS_DIR` externo **sem** `-Public`.

## Arquivo de jornada por sessão

`.sky/sessions/{slug}/journey.yaml` — estado UX (atualizado por sky-host ou especialista ativo).

## Comandos por fase

| Fase | Comando |
|------|---------|
| deliver | `./scripts/sky/sky.ps1 export -Slug <slug> -Completeness partial` |
| showcase | `./scripts/sky/sky.ps1 publish -Slug <slug> -Public` |
| showcase | `./scripts/sky/sky.ps1 showcase` |
| status | `./scripts/sky/sky.ps1 status -Slug <slug>` |

## Retomar sessão

1. sky-host lê `journey.yaml` + `maturity.yaml`
2. Resume em 3 linhas: o que é, onde parou, 2–3 opções numeradas
3. Não reexplicar o funil inteiro
