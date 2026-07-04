let mermaidReady: Promise<typeof import("mermaid").default> | null = null;

function loadMermaid() {
  if (!mermaidReady) {
    mermaidReady = import("mermaid").then((mod) => {
      mod.default.initialize({
        startOnLoad: false,
        theme: "neutral",
        securityLevel: "loose",
        fontFamily: "Mulish, system-ui, sans-serif",
      });
      return mod.default;
    });
  }
  return mermaidReady;
}

async function renderNode(node: HTMLElement, mermaid: typeof import("mermaid").default) {
  if (node.dataset.rendered === "true") return;
  const source = node.textContent?.trim();
  if (!source) return;

  node.dataset.rendered = "pending";
  node.classList.add("mermaid-loading");

  const id = `mmd-${node.getAttribute("data-mermaid")}-${Math.random().toString(36).slice(2, 8)}`;
  try {
    const { svg } = await mermaid.render(id, source);
    const wrap = document.createElement("div");
    wrap.className = "mermaid-diagram";
    wrap.innerHTML = svg;
    node.replaceWith(wrap);
  } catch (err) {
    const errEl = document.createElement("pre");
    errEl.className = "artifact-fallback artifact-mermaid-error";
    errEl.textContent = `Diagrama Mermaid: ${err instanceof Error ? err.message : "erro ao renderizar"}\n\n${source}`;
    node.replaceWith(errEl);
  }
}

export async function initLazyMermaid(root: ParentNode = document, immediate = false) {
  const nodes = root.querySelectorAll<HTMLElement>(
    ".mermaid-source[data-mermaid]:not([data-rendered='true'])",
  );
  if (nodes.length === 0) return;

  const mermaid = await loadMermaid();

  if (immediate) {
    for (const node of nodes) {
      await renderNode(node, mermaid);
    }
    return;
  }

  const observer = new IntersectionObserver(
    (entries) => {
      void (async () => {
        for (const entry of entries) {
          if (!entry.isIntersecting) continue;
          observer.unobserve(entry.target);
          await renderNode(entry.target as HTMLElement, mermaid);
        }
      })();
    },
    { rootMargin: "160px", threshold: 0.05 },
  );

  for (const node of nodes) {
    if (node.dataset.rendered !== "true") observer.observe(node);
  }
}
