# Índices SKY de mérito

**Versão**: 1.0 | **Data**: 2026-07-04  
**Marca**: Sky-Forge — elevar o que está sendo proposto

Os **Índices SKY** são métricas proprietárias que medem como uma aplicação pode
contribuir para a **prosperidade humana no planeta**, além do valor de negócio
imediato. Não são greenwashing automático: são sugestões conscientes, opcionais
e sempre submetidas à aprovação do criador (`user_confirmed`).

---

## Filosofia

Sky-Forge não só especifica software — **eleva** a proposta conectando-a, quando
faz sentido, a problemas globais que precisam ser endereçados e a formas de
ampliar benefício coletivo sem distorcer o escopo do cliente.

```
Solução da pessoa  +  problemas atuais do planeta  →  oportunidades de elevação
```

O agente **sky-elevator** e o especialista **ux-design-specialist** trabalham
juntos: um na dimensão de impacto/consciência, outro na experiência humana
digna, acessível e de baixa excitação manipulativa.

---

## Os cinco índices (0–100 cada)

| Sigla | Nome | O que mede |
|-------|------|------------|
| **SPI** | Sky Prosperity Impact | Contribuição para prosperidade material e dignidade (acesso, renda local, autonomia) |
| **HCE** | Human Consciousness Expansion | Amplia consciência, educação, reflexão, conexão significativa — sem manipulação |
| **GAP** | Global Alignment Potential | Alinhamento com desafios planetários urgentes (ver catálogo `docs/humanity/`) |
| **CWB** | Collective Wellbeing Contribution | Bem-estar coletivo, saúde comunitária, cuidado, coesão social |
| **UXD** | UX Dignity Score | Qualidade de experiência: acessibilidade, calma, clareza, WCAG, mobile-first |

### Score composto

```
SKY_SCORE = 0.25×SPI + 0.20×HCE + 0.20×GAP + 0.20×CWB + 0.15×UXD
```

Pesos ajustáveis por sessão em `sky-merits.yaml` → `weights`.

---

## Níveis de elevação sugerida

| Nível | SKY_SCORE | Significado |
|-------|-----------|-------------|
| **Ground** | 0–39 | Foco local válido; elevação opcional |
| **Rise** | 40–59 | Conexões moderadas com bem coletivo |
| **Horizon** | 60–79 | Proposta explicitamente alinhada a impacto ampliado |
| **Sky** | 80–100 | Produto desenhado com prosperidade humana como eixo co-criador |

---

## Artefato de sessão

` .sky/sessions/{slug}/sky-merits.yaml` — ver [sky-merits.schema.yaml](../schemas/sky-merits.schema.yaml)

Campos principais:

- `indices` — SPI, HCE, GAP, CWB, UXD com score e rationale
- `elevation_suggestions[]` — sugestões da IA (`ai_suggested: true`)
- `humanity_connections[]` — ligação explícita problema global ↔ feature do produto
- `policies.open_to_elevation` — cliente aceita sugestões de expansão?

---

## Guardrails

- Sugestões de elevação **nunca** viram RF `must` sem confirmação.
- Respeitar `policies.open_to_elevation: false` — só documentar, não insistir.
- GAP usa catálogo neutro (`challenges-catalog.yaml`), não agenda partidária.
- UXD segue: mobile-first, WCAG AA, baixa excitação, tokens (sem cores hardcoded).

---

## Agentes responsáveis

| Agente | Papel |
|--------|-------|
| `sky-elevator` | Consultivo — índices, conexões humanidade, expansão de consciência |
| `ux-design-specialist` | Operacional — UX spec, acessibilidade, design calmo |
| `intake-conductor` | Coreografa quando convidar elevação na conversa |

## Referências

- [challenges-catalog.yaml](../humanity/challenges-catalog.yaml)
- [INTAKE_PROTOCOL.md](INTAKE_PROTOCOL.md) — Nível 2b Elevação & UX
