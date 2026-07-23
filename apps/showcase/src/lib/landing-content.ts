/** Conteúdo de marketing alinhado ao funil real (USER_JOURNEY + AGENTS.md).
 *  Paisagem de soluções = visão High Premium em roadmap — não produto entregue. */

export const landingPrinciples = [
  {
    num: "01",
    title: "Energia que organiza",
    body: "Entropia dissipa; sintropia concentra. Cada intake converte intenção difusa em estrutura viva: brief, requisitos, arquitetura, pacote verificável. O sistema termina cada ciclo mais ordenado do que começou.",
  },
  {
    num: "02",
    title: "Consciência do que se produz",
    body: "Todo software ocupa atenção humana. O Sky-Forge mede o que essa atenção gera — dignidade, clareza, benefício coletivo — antes da primeira linha de código.",
  },
  {
    num: "03",
    title: "Prosperidade como métrica",
    body: "SPI, HCE, GAP, CWB e UXD tornam mensurável o que costuma ficar no discurso. Elevação é sugerida, nunca imposta: o criador confirma cada conexão.",
  },
];

/** Passos do funil entregue hoje — espelha USER_JOURNEY.md */
export const landingSteps: {
  num: string;
  title: string;
  body: string;
  lift: number;
  op: number;
  status?: "live" | "roadmap";
}[] = [
  {
    num: "01",
    title: "Intenção",
    body: "Uma ideia em linguagem natural. sky-host recebe e oferece o próximo passo — sem formulário.",
    lift: 0,
    op: 0.35,
    status: "live",
  },
  {
    num: "02",
    title: "Intake conversacional",
    body: "intake-conductor conduz a conversa e mapeia maturidade nas 6 dimensões (negócio, produto, UX, técnico, sustentação, elevação).",
    lift: 18,
    op: 0.42,
    status: "live",
  },
  {
    num: "03",
    title: "Elevação & UX",
    body: "sky-elevator e ux-design-specialist: índices SKY, humanity_connections e UX digna — sempre com confirmação do criador.",
    lift: 36,
    op: 0.52,
    status: "live",
  },
  {
    num: "04",
    title: "Mercado & pesquisa",
    body: "market-scout (stack/mercado) e market-benchmark (MPI, fontes, lacunas ai_suggested). Gate: sky approve -Stage research.",
    lift: 54,
    op: 0.62,
    status: "live",
  },
  {
    num: "05",
    title: "Arquitetura",
    body: "solutions-architect + c4-modeler + jornadas: C4, domínios, ADRs. Gate humano antes de avançar (approve -Stage architecture).",
    lift: 72,
    op: 0.74,
    status: "live",
  },
  {
    num: "06",
    title: "Entregar & apresentar",
    body: "delivery-steward exporta o pacote; showcase-curator publica preview sanitizado só com opt-in (-Public).",
    lift: 90,
    op: 0.86,
    status: "live",
  },
  {
    num: "07",
    title: "Implementar",
    body: "repo-scaffolder e prompt-assembler no repo do app; ARAH Harness quando a avaliação recomenda.",
    lift: 108,
    op: 1,
    status: "live",
  },
];

/** Visão High Premium — ainda não é agente/artefato no core */
export const landscapeRoadmap = {
  title: "Paisagem de soluções",
  badge: "Roadmap",
  summary:
    "Visão do Claude Design High Premium: seis lentes, 2–5 opções compostas e gate de decisão explícito antes da arquitetura. Hoje o equivalente entregue é market-scout + market-benchmark; a Paisagem unificada ainda não existe como agente nem como YAML.",
  todayEquivalent: [
    { id: "market-scout", role: "Pesquisa de mercado e stack" },
    { id: "market-benchmark", role: "MPI, fontes e lacunas ai_suggested" },
    { id: "sky approve -Stage research", role: "Gate humano de pesquisa" },
  ],
  plannedArtifacts: [
    "solution-landscape.yaml",
    "solution-options.yaml",
    "solution-decision.md",
  ],
};

export const landingIndices = [
  { sigla: "SPI", weight: "0.25", name: "Sky Prosperity Impact", desc: "Contribuição para prosperidade material e dignidade: acesso, renda local, autonomia." },
  { sigla: "HCE", weight: "0.20", name: "Human Consciousness Expansion", desc: "Amplia consciência, educação, reflexão e conexão significativa — sem manipulação." },
  { sigla: "GAP", weight: "0.20", name: "Global Alignment Potential", desc: "Alinhamento com desafios planetários urgentes, via catálogo neutro." },
  { sigla: "CWB", weight: "0.20", name: "Collective Wellbeing", desc: "Bem-estar coletivo, saúde comunitária, cuidado e coesão social." },
  { sigla: "UXD", weight: "0.15", name: "UX Dignity Score", desc: "Acessibilidade, calma e clareza: WCAG AA, mobile-first, baixa excitação." },
];

/** Fora do SKY_SCORE composto (espec v1.2) — já entregue via market-benchmark */
export const landingMpiNote = {
  sigla: "MPI",
  name: "Market Positioning Index",
  desc: "Novidade e diferenciação frente a mercado e open source. Publicado ao lado do SKY_SCORE; não entra na fórmula composta sem RFC.",
};

export const landingLevels = [
  { name: "Ground", range: "0–39", h: 70, op: 0.35, desc: "Foco local válido; elevação opcional." },
  { name: "Rise", range: "40–59", h: 130, op: 0.55, desc: "Conexões moderadas com o bem coletivo." },
  { name: "Horizon", range: "60–79", h: 190, op: 0.78, desc: "Proposta explicitamente alinhada a impacto ampliado." },
  { name: "Sky", range: "80–100", h: 250, op: 1, desc: "Prosperidade humana como eixo co-criador do produto." },
];

/** Gates humanos reais — scripts/sky approve -Stage */
export const produtoApproveStages = [
  "brief",
  "research",
  "architecture",
  "elevation",
  "package",
  "public_showcase",
];

/** Prévia roadmap da Paisagem (design High Premium — não implementada) */
export const produtoLenses = [
  {
    num: "L1",
    title: "Soluções de referência",
    chips: ["Open Food Network", "Karrot", "marketplaces hiperlocais", "apps de doação"],
    note: "Produtos, serviços e projetos open source que já circulam excedente alimentar — com contexto de onde funcionam e onde falham.",
  },
  {
    num: "L2",
    title: "Padrões arquiteturais",
    chips: ["monólito modular", "eventos", "workflows"],
    note: "Reserva e expiração de excedente pedem eventos; o restante cabe num monólito modular — microsserviços seriam prematuro.",
  },
  {
    num: "L3",
    title: "Modelos de solução",
    chips: ["marketplace", "plataforma comunitária", "PWA mobile-first"],
    note: "Marketplace de dois lados (horta publica, cozinha reserva), operado como plataforma de bairro, não como app de consumo.",
  },
  {
    num: "L4",
    title: "Estratégias de implementação",
    chips: ["buy", "adopt", "extend", "build", "hybrid"],
    note: "As quatro opções abaixo compõem estas estratégias; nenhuma foi descartada sem evidência registrada.",
  },
  {
    num: "L5",
    title: "Modelos operacionais",
    chips: ["federado por bairro", "repo-first", "operação compartilhada"],
    note: "Cada bairro opera sua rede; o dossiê e as decisões vivem no repositório, auditáveis por diff.",
  },
  {
    num: "L6",
    title: "Modelos computacionais e IA",
    chips: ["busca + geo", "regras de matching", "previsão de excedente"],
    note: "Matching determinístico (regras + geolocalização) resolve o MVP; previsão de excedente é hipótese para spike, não requisito.",
  },
];

export const produtoOptions = [
  {
    letter: "A",
    strategy: "buy",
    title: "Comprar plataforma de marketplace",
    desc: "SaaS de marketplace local pronto, integrado via API. Rápido para validar, mas dados ficam fora e a reserva não é nativa.",
    reco: false,
    evidence: "3 evidências · confiança média",
  },
  {
    letter: "B",
    strategy: "adopt + extend",
    title: "Adotar Open Food Network e estender",
    desc: "OSS maduro para redes alimentares; extensão própria para reserva de excedente e prestação de contas por bairro.",
    reco: false,
    evidence: "5 evidências · confiança média-alta",
  },
  {
    letter: "C",
    strategy: "build repo-first",
    title: "Construir domínio próprio",
    desc: "Solução própria via Sky-Forge + ARAH Harness: domínio sob medida, custo maior de tempo e sustentação.",
    reco: false,
    evidence: "2 evidências · exige spike",
  },
  {
    letter: "D",
    strategy: "hybrid",
    title: "Serviços gerenciados + OSS + domínio próprio",
    desc: "Auth e mapas gerenciados, catálogo open source, e só o domínio de reserva/expiração construído — o núcleo que diferencia.",
    reco: true,
    evidence: "4 evidências · confiança alta · aguarda decisão humana",
  },
];

export type MarketingNavId = "landing" | "produto" | "galeria" | "design" | "evolucao";

export const marketingNav: { id: MarketingNavId; href: string; label: string }[] = [
  { id: "landing", href: "/", label: "Landing" },
  { id: "produto", href: "/produto/", label: "Produto" },
  { id: "galeria", href: "/galeria/", label: "Showcase" },
  { id: "design", href: "/design-system/", label: "Design System" },
  { id: "evolucao", href: "/evolucao/", label: "Evolução" },
];
