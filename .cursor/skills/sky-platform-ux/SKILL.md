# Sky Platform UX — Cursor skill

Use quando alterar identidade visual, showcase, tokens ou arquitetura de informação do **Sky-Forge como produto** (não UX de projetos intake).

## Antes de editar

1. Ler [SKY_APP_UX.md](../../docs/_meta/SKY_APP_UX.md)
2. Ler [templates/platform/ux-spec.yaml](../../templates/platform/ux-spec.yaml)
3. Tokens em `apps/showcase/src/styles/global.css` — **sem cores hardcoded**

## Identidade

| Elemento | Valor |
|----------|-------|
| Nome | Sky-Forge |
| Tagline | Estúdio de elevação de ideias |
| Tom | Calmo, digno, baixa excitação |
| Tipografia | Cormorant (títulos) + Mulish (corpo) |
| Gradiente | Apenas no header — `--color-sky-deep` → `--color-sky-mid` |

## Componentes compartilhados

| Componente | Uso |
|------------|-----|
| `HubHeader.astro` | Nav Projetos · Agentes · Método · Sobre |
| `SiteFooter.astro` | Rodapé em todas as páginas |
| `MaturityBar.astro` | Barra de maturidade (hero/card) |
| `ProjectCtaPanel.astro` | CTAs numerados 1–3 no projeto |

## Regras invioláveis

- Máximo **4 opções** por turno (sky-host)
- **Nunca** export + publish no mesmo passo na UI
- `prefers-reduced-motion` respeitado
- Contraste WCAG AA; piso tipográfico 11.5px
- Modo browser: export/Git → link para instalação local

## Agente

Consulte `ux-design-specialist` para revisão UXD do showcase.
Atualize `templates/platform/ux-spec.yaml` quando mudar telas ou tokens.

## Comandos

```powershell
cd apps/showcase && pnpm build
./scripts/sky/sky.ps1 showcase
./scripts/sky/sky.ps1 publish -Slug <slug> -Public
```
