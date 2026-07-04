import type { FunctionalRequirement, ProjectPreview } from "./registry";
import { dimensionLabel } from "./registry";

export type GapKind = "maturity" | "ai_suggested" | "pipeline" | "unconfirmed";

export type GapItem = {
  id: string;
  label: string;
  kind: GapKind;
  dimension?: string;
  detail?: string;
};

export type ProjectGapsSummary = {
  total_count: number;
  top: GapItem[];
  next_action: string;
  intake_command: string;
  cursor_prompt: string;
};

const AI_SUGGESTED_RF_IDS = new Set(["RF-014", "RF-015", "RF-016", "RF-017", "RF-018", "RF-019"]);

function isAiSuggestedRf(rf: FunctionalRequirement): boolean {
  if (rf.ai_suggested === true) return true;
  return AI_SUGGESTED_RF_IDS.has(rf.id);
}

function buildCursorPrompt(slug: string, top: GapItem[]): string {
  const lines = top.slice(0, 3).map((g, i) => `${i + 1}) ${g.label}`);
  return [
    `Continuar intake Sky-Forge — projeto ${slug}.`,
    "Lacunas prioritárias:",
    ...lines,
    "",
    "Quero preencher a próxima lacuna. Guie-me passo a passo.",
  ].join("\n");
}

export function extractGaps(project: ProjectPreview): ProjectGapsSummary {
  const slug = project.slug;
  const intakeCommand = `./scripts/sky/sky.ps1 intake -Slug ${slug}`;

  if (project.gaps?.top?.length) {
    const top = project.gaps.top;
    return {
      total_count: project.gaps.total_count ?? top.length,
      top: top.slice(0, 3),
      next_action:
        project.gaps.next_action ??
        "Continue o intake no Cursor para fechar a próxima lacuna.",
      intake_command: intakeCommand,
      cursor_prompt: buildCursorPrompt(slug, top),
    };
  }

  const items: GapItem[] = [];

  const dimGaps = project.gaps?.dimension_gaps ?? project.dimension_gaps;
  if (dimGaps) {
    for (const [dim, gapList] of Object.entries(dimGaps)) {
      for (const g of gapList) {
        items.push({
          id: `dim-${dim}-${g.slice(0, 24).replace(/\s+/g, "-").toLowerCase()}`,
          label: g,
          kind: "maturity",
          dimension: dim,
        });
      }
    }
  }

  if (project.dimensions) {
    const sorted = Object.entries(project.dimensions)
      .filter(([, score]) => score < 0.85)
      .sort(([, a], [, b]) => a - b);
    for (const [dim, score] of sorted) {
      const existing = items.some((i) => i.dimension === dim);
      if (!existing && score < 0.7) {
        items.push({
          id: `dim-low-${dim}`,
          label: `${dimensionLabel(dim)} abaixo do ideal (${Math.round(score * 100)}%)`,
          kind: "maturity",
          dimension: dim,
        });
      }
    }
  }

  const functional = project.requirements?.functional ?? [];
  const pendingSuggestions = functional.filter(
    (rf) => isAiSuggestedRf(rf) && rf.user_confirmed == null,
  );
  for (const rf of pendingSuggestions) {
    items.push({
      id: rf.id,
      label: rf.title,
      kind: "ai_suggested",
      dimension: "product",
      detail: "Sugerido pelo benchmark de mercado — aguarda sua confirmação",
    });
  }

  const pipeline = project.pipeline?.filter((p) => !p.approved) ?? [];
  for (const stage of pipeline) {
    items.push({
      id: `pipe-${stage.stage}`,
      label: `Pipeline: ${stage.stage.replace(/_/g, " ")}`,
      kind: "pipeline",
    });
  }

  const priority: Record<GapKind, number> = {
    maturity: 0,
    ai_suggested: 1,
    unconfirmed: 2,
    pipeline: 3,
  };
  items.sort((a, b) => priority[a.kind] - priority[b.kind]);

  const top = items.slice(0, 3);
  const total = project.gaps?.total_count ?? items.length;

  let nextAction = "Continue o intake no Cursor para fechar a próxima lacuna.";
  if (top[0]?.kind === "ai_suggested") {
    nextAction =
      "Confirme ou descarte requisitos sugeridos pelo benchmark — nada entra no escopo sem você.";
  } else if (top[0]?.kind === "maturity") {
    nextAction = `Preencha a lacuna em ${dimensionLabel(top[0].dimension ?? "negócio")} conversando com o sky-host.`;
  }

  return {
    total_count: total,
    top,
    next_action: nextAction,
    intake_command: intakeCommand,
    cursor_prompt: buildCursorPrompt(slug, top.length ? top : items),
  };
}

export function gapCountForIndex(project: ProjectPreview): number {
  if (project.gaps?.total_count != null) return project.gaps.total_count;
  return extractGaps(project).total_count;
}
