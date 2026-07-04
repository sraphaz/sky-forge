import { marked } from "marked";
import { initLazyMermaid } from "./mermaid-lazy";

export type ArtifactPayload = {
  content?: string;
  contentHtml?: string;
  label?: string;
  likec4View?: string;
  cloudDesign?: boolean;
  cloudDesignChild?: { label: string; filename?: string; description?: string };
};

type Block = { kind: "html" | "mermaid"; value: string };

/** Escapa chaves em mensagens de sequenceDiagram (ex.: GET /cases/{id}). */
function sanitizeMermaidSource(source: string): string {
  const trimmed = source.trimStart();
  if (!trimmed.startsWith("sequenceDiagram")) return source;

  return source
    .split(/\r?\n/)
    .map((line) => {
      const arrow = line.match(/^(\s*\S+\s*[-=]+>>?\s*\S+\s*:\s*)(.*)$/);
      if (!arrow) return line;
      const prefix = arrow[1];
      let msg = arrow[2].trim();
      if (!msg || msg.startsWith('"')) return line;
      if (msg.includes("{") || msg.includes("}")) {
        msg = msg.replace(/\{/g, "(").replace(/\}/g, ")");
      }
      return `${prefix}"${msg.replace(/"/g, '\\"')}"`;
    })
    .join("\n");
}

function splitMarkdownBlocks(md: string): Block[] {
  const blocks: Block[] = [];
  const re = /```mermaid\r?\n([\s\S]*?)```/g;
  let last = 0;
  let match: RegExpExecArray | null;
  while ((match = re.exec(md)) !== null) {
    if (match.index > last) {
      const chunk = md.slice(last, match.index);
      if (chunk.trim()) {
        blocks.push({ kind: "html", value: marked.parse(chunk, { async: false }) as string });
      }
    }
    blocks.push({ kind: "mermaid", value: match[1].trim() });
    last = match.index + match[0].length;
  }
  if (last < md.length) {
    const tail = md.slice(last);
    if (tail.trim()) {
      blocks.push({ kind: "html", value: marked.parse(tail, { async: false }) as string });
    }
  }
  if (blocks.length === 0 && md.trim()) {
    blocks.push({ kind: "html", value: marked.parse(md, { async: false }) as string });
  }
  return blocks;
}

function stripMermaidFences(md: string): string {
  return md.replace(/```mermaid[\s\S]*?```/g, "").trim();
}

function resolveBaseUrl(): string {
  const viewer = document.getElementById("artifact-viewer");
  const base = viewer?.getAttribute("data-base") ?? "/";
  return base.replace(/\/$/, "");
}

function resolveSlug(): string {
  return document.getElementById("artifact-viewer")?.getAttribute("data-slug") ?? "iautos";
}

function renderCloudDesignPanel(container: HTMLElement, data: ArtifactPayload) {
  const child = data.cloudDesignChild;
  const wrap = document.createElement("div");
  wrap.className = "cloud-design-explainer";

  wrap.innerHTML = `
    <p class="cloud-design-badge">Sky Cloud Design · extensão Sky-Forge</p>
    <h3 class="cloud-design-title">${child?.label ?? data.label ?? "Protótipos visuais"}</h3>
    <p class="cloud-design-lead">
      <strong>Não é Claude/Anthropic.</strong>
      Cloud Design é a extensão proprietária do Sky-Forge que exporta protótipos navegáveis
      (<code>.dc.html</code>) — mockups da aplicação, site institucional e handoffs visuais.
    </p>
    <p>
      O objetivo é permitir que stakeholders <em>vejam e naveguem</em> a experiência proposta
      antes da implementação, dentro do pacote completo em <code>outputs/</code>.
    </p>
    ${
      child?.filename
        ? `<p class="cloud-design-file-ref">Arquivo no pacote: <code>cloud-design/${child.filename}</code></p>`
        : ""
    }
    ${
      child?.description
        ? `<p class="cloud-design-desc">${child.description}</p>`
        : `<ul class="cloud-design-list-inline">
            <li><strong>aplicacao-mockup.dc.html</strong> — mockup navegável do app advogado</li>
            <li><strong>site-bonomi.dc.html</strong> — site institucional white-label (referência)</li>
            <li><strong>arquitetura.dc.html</strong> — visão arquitetural interativa</li>
            <li><strong>handoff*.dc.html</strong> — handoff para desenvolvimento</li>
          </ul>`
    }
    <p class="panel-hint cloud-design-privacy">
      No preview público do showcase, o HTML interativo <strong>não é redistribuído</strong>
      (requer runtime proprietário). Abra o pacote exportado localmente para a experiência completa.
    </p>
  `;
  container.appendChild(wrap);
}

function renderLikeC4Diagram(container: HTMLElement, viewId: string) {
  const slug = resolveSlug();
  const base = resolveBaseUrl();
  const wrap = document.createElement("div");
  wrap.className = "likec4-viewer";

  const img = document.createElement("img");
  img.className = "likec4-diagram-img";
  img.alt = `Diagrama C4 — ${viewId}`;
  img.src = `${base}/diagrams/${slug}/${viewId}.png`;
  img.loading = "eager";

  const fallback = document.createElement("p");
  fallback.className = "panel-hint";
  fallback.hidden = true;
  fallback.textContent = "Diagrama LikeC4 indisponível — rode pnpm export:diagrams no showcase.";

  img.addEventListener("error", () => {
    img.hidden = true;
    fallback.hidden = false;
  });

  wrap.appendChild(img);
  wrap.appendChild(fallback);
  container.appendChild(wrap);
}

export async function renderArtifactInto(container: HTMLElement, data: ArtifactPayload) {
  container.innerHTML = "";

  if (data.cloudDesign) {
    renderCloudDesignPanel(container, data);
    return;
  }

  if (data.likec4View) {
    renderLikeC4Diagram(container, data.likec4View);
    const prose = data.content ? stripMermaidFences(data.content) : "";
    if (prose.trim()) {
      const div = document.createElement("div");
      div.className = "markdown-body artifact-prose-below";
      div.innerHTML = marked.parse(prose, { async: false }) as string;
      container.appendChild(div);
    }
    return;
  }

  if (data.contentHtml) {
    const wrap = document.createElement("div");
    wrap.className = "artifact-render artifact-render-viewer";
    const iframe = document.createElement("iframe");
    iframe.className = "artifact-preview-frame";
    iframe.title = data.label ?? "Preview visual";
    iframe.srcdoc = data.contentHtml;
    iframe.setAttribute("sandbox", "allow-same-origin");
    wrap.appendChild(iframe);
    container.appendChild(wrap);
    return;
  }

  if (!data.content?.trim()) {
    const empty = document.createElement("p");
    empty.className = "panel-hint";
    empty.textContent = "Conteúdo indisponível neste preview.";
    container.appendChild(empty);
    return;
  }

  const wrap = document.createElement("div");
  wrap.className = "artifact-render artifact-body artifact-render-viewer";
  const blocks = splitMarkdownBlocks(data.content);
  blocks.forEach((block, i) => {
    if (block.kind === "mermaid") {
      const pre = document.createElement("pre");
      pre.className = "mermaid-source";
      pre.dataset.mermaid = String(i);
      pre.textContent = sanitizeMermaidSource(block.value);
      wrap.appendChild(pre);
    } else {
      const div = document.createElement("div");
      div.className = "markdown-body";
      div.innerHTML = block.value;
      wrap.appendChild(div);
    }
  });
  container.appendChild(wrap);
  await initLazyMermaid(container, true);
}

export type ViewerCatalog = Record<
  string,
  ArtifactPayload & { label: string; path: string }
>;

export function readViewerCatalog(): ViewerCatalog {
  const el = document.getElementById("artifact-viewer-catalog");
  if (!el?.textContent?.trim()) {
    console.warn("[artifact-viewer] catálogo vazio ou script não parseável");
    return {};
  }
  try {
    return JSON.parse(el.textContent) as ViewerCatalog;
  } catch (err) {
    console.error("[artifact-viewer] falha ao parsear catálogo JSON", err);
    return {};
  }
}
