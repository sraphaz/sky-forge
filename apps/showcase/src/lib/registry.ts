import index from "../../../../showcase/registry/index.json";

export type ProjectIndexEntry = {
  slug: string;
  title: string;
  excerpt?: string;
  tier?: string;
  sky_score?: number;
  readiness?: number;
  elevation_level?: string;
  tags?: string[];
  preview_file: string;
  agents_file?: string;
  public?: boolean;
};

export type AgentEvent = {
  ts: string;
  agent_id: string;
  action: string;
  outcome: string;
  autonomy_level?: string;
  human_gate?: string | null;
  details?: string;
};

export type AgentsView = {
  slug: string;
  published_at?: string;
  journey_phase?: string;
  metrics?: {
    total_events?: number;
    last_agent?: string;
    last_action?: string;
    last_outcome?: string;
  };
  choreography?: {
    matched_rules?: string[];
    readiness?: number;
    operational?: {
      id: string;
      type?: string;
      max_autonomy?: string;
      skills?: string[];
      requires_gate?: string[];
    }[];
    domain_consults?: string[];
    skills?: string[];
    gates_required?: string[];
  };
  gates?: { id: string; approved: boolean }[];
  autonomy_levels?: { id: string; rank: number; label: string }[];
  events?: AgentEvent[];
  event_counts?: { ok: number; blocked: number; other: number };
};

export type ProjectVision = {
  problem?: string;
  motivation?: string;
  value_proposition?: string;
  primary_users?: string[];
  mvp_scope?: string;
  out_of_scope?: string[];
  reference_tenant?: string;
};

export type FunctionalRequirement = {
  id: string;
  title: string;
  epic?: string;
  priority?: string;
  mvp?: boolean;
};

export type NonFunctionalRequirement = {
  id: string;
  category?: string;
  statement?: string;
};

export type IntegrationChoice = {
  id: string;
  type?: string;
  provider?: string;
  required?: boolean;
  reason?: string;
};

export type ProjectPreview = ProjectIndexEntry & {
  vision?: ProjectVision;
  requirements?: {
    functional?: FunctionalRequirement[];
    non_functional?: NonFunctionalRequirement[];
  };
  architecture?: {
    integrations?: IntegrationChoice[];
    ux?: {
      principles?: string[];
      key_screens?: { id: string; title: string }[];
    };
  };
  indices?: Record<string, number>;
  dimensions?: Record<string, number>;
  phases?: { id: string; title: string; status: string }[];
  pipeline?: { stage: string; approved: boolean }[];
  artifacts?: { label: string; type: string; path: string }[];
  published_at?: string;
  outputs_dir?: string;
};

export function loadIndex(): { version: string; projects: ProjectIndexEntry[] } {
  return index as { version: string; projects: ProjectIndexEntry[] };
}

const previewModules = import.meta.glob("../../../../showcase/registry/*.preview.json", {
  eager: true,
  import: "default",
}) as Record<string, ProjectPreview>;

export async function loadPreview(slug: string): Promise<ProjectPreview | null> {
  const entry = loadIndex().projects.find((p) => p.slug === slug);
  if (!entry) return null;
  const key = `../../../../showcase/registry/${entry.preview_file}`;
  return previewModules[key] ?? null;
}

export function formatPercent(value: number | undefined): string {
  if (value == null) return "—";
  return `${Math.round(value * 100)}%`;
}

const dimensionLabels: Record<string, string> = {
  business: "Negócio",
  product: "Produto",
  ux_design: "UX",
  technical: "Técnico",
  sustainability: "Sustentação",
  elevation: "Elevação",
};

export function dimensionLabel(key: string): string {
  return dimensionLabels[key] ?? key;
}

const indexLabels: Record<string, string> = {
  SPI: "Prosperidade inclusiva",
  HCE: "Consciência humana",
  GAP: "Alinhamento planetário",
  CWB: "Bem-estar coletivo",
  UXD: "UX digna",
};

export function indexLabel(key: string): string {
  return indexLabels[key] ?? key;
}

const phaseStatusClass: Record<string, string> = {
  next: "phase-next",
  pending: "phase-pending",
  post_mvp: "phase-post",
  done: "phase-done",
};

export function phaseClass(status: string): string {
  return phaseStatusClass[status] ?? "phase-pending";
}

const pipelineLabels: Record<string, string> = {
  market_research: "Pesquisa de mercado",
  sky_elevation: "Elevação SKY",
  ux_review: "Revisão UX",
  architecture: "Arquitetura",
  roadmap: "Roadmap",
  prompt_compile: "Compilação de prompts",
  cloud_design_export: "Cloud Design",
  full_package: "Pacote completo",
};

export function pipelineLabel(stage: string): string {
  return pipelineLabels[stage] ?? stage.replace(/_/g, " ");
}

const agentsModules = import.meta.glob("../../../../showcase/registry/*.agents.json", {
  eager: true,
  import: "default",
}) as Record<string, AgentsView>;

export async function loadAgentsView(slug: string): Promise<AgentsView | null> {
  const entry = loadIndex().projects.find((p) => p.slug === slug);
  if (!entry?.agents_file) return null;
  const key = `../../../../showcase/registry/${entry.agents_file}`;
  return agentsModules[key] ?? null;
}

export function outcomeClass(outcome: string): string {
  if (outcome === "ok") return "outcome-ok";
  if (outcome === "blocked") return "outcome-blocked";
  return "outcome-other";
}

export function autonomyLabel(id: string): string {
  const labels: Record<string, string> = {
    observe: "Observar",
    consult: "Consultar",
    route: "Rotear",
    activate: "Ativar",
    invoke_skill: "Skill",
    side_effect: "Externo",
    public: "Público",
  };
  return labels[id] ?? id;
}

export function gateLabel(id: string): string {
  const labels: Record<string, string> = {
    brief: "Brief aprovado",
    elevation: "Elevação",
    package: "Pacote exportável",
    public_showcase: "Showcase público",
  };
  return labels[id] ?? id;
}

export function formatTime(iso: string): string {
  try {
    return new Date(iso).toLocaleString("pt-BR", { dateStyle: "short", timeStyle: "short" });
  } catch {
    return iso;
  }
}
