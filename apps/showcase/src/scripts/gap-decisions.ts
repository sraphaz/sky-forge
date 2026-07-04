/**
 * Modo interativo local — decisões de lacunas direto no site.
 *
 * Sonda `GET {base}/api/health` (existe apenas no dev server, via integração
 * sky-local-api). Se responder, revela os controles `[data-gap-interactive]`
 * e envia decisões para `POST {base}/api/gaps/decide`. No deploy estático a
 * sonda falha silenciosamente e a página mantém só os CTAs de copiar.
 */

type DecideResponse = {
  ok: boolean;
  error?: string;
  preview_refreshed?: boolean;
};

let apiBase = "";
let slug = "";

function toast(message: string, tone: "ok" | "error" = "ok"): void {
  const el = document.getElementById("gap-toast");
  if (!el) return;
  el.textContent = message;
  el.dataset.tone = tone;
  el.classList.add("is-visible");
  window.setTimeout(() => el.classList.remove("is-visible"), 4000);
}

async function postDecision(body: Record<string, unknown>): Promise<DecideResponse> {
  const res = await fetch(`${apiBase}/api/gaps/decide`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ slug, ...body }),
  });
  const data = (await res.json().catch(() => ({}))) as DecideResponse;
  if (!res.ok || !data.ok) {
    throw new Error(data.error ?? `falha ao gravar (HTTP ${res.status})`);
  }
  return data;
}

function setBusy(container: HTMLElement, busy: boolean): void {
  container
    .querySelectorAll<HTMLButtonElement>("button")
    .forEach((b) => (b.disabled = busy));
  container.classList.toggle("is-busy", busy);
}

function markDecided(container: HTMLElement, decision: string): void {
  const labels: Record<string, string> = {
    confirm: "Aceito — entra no escopo",
    reject: "Recusado — fica documentado",
    skip: "Guardado para decidir depois",
    answer: "Resposta registrada",
  };
  container.innerHTML = `<p class="gap-decided-note" role="status">${labels[decision] ?? "Decisão registrada"}. Atualizando…</p>`;
}

async function decide(
  container: HTMLElement,
  body: Record<string, unknown>,
  decision: string,
): Promise<void> {
  setBusy(container, true);
  try {
    await postDecision(body);
    markDecided(container, decision);
    toast("Decisão gravada na sessão — recarregando a página.");
    window.setTimeout(() => window.location.reload(), 1200);
  } catch (err) {
    setBusy(container, false);
    toast(err instanceof Error ? err.message : "Não foi possível gravar a decisão.", "error");
  }
}

function wireRfCards(): void {
  document.querySelectorAll<HTMLElement>("[data-gap-actions]").forEach((actions) => {
    const itemId = actions.dataset.itemId ?? "";
    const label = actions.dataset.itemLabel ?? "";
    actions.querySelectorAll<HTMLButtonElement>("[data-decide]").forEach((btn) => {
      btn.addEventListener("click", () => {
        void decide(
          actions,
          { item_id: itemId, label, decision: btn.dataset.decide },
          btn.dataset.decide ?? "",
        );
      });
    });
  });
}

function wireAnswerForms(): void {
  document.querySelectorAll<HTMLFormElement>("form[data-gap-answer]").forEach((form) => {
    form.addEventListener("submit", (event) => {
      event.preventDefault();
      const textarea = form.querySelector<HTMLTextAreaElement>("textarea");
      const note = textarea?.value.trim() ?? "";
      if (!note) {
        textarea?.focus();
        toast("Escreva a resposta antes de enviar.", "error");
        return;
      }
      void decide(
        form,
        {
          item_id: form.dataset.itemId,
          label: form.dataset.itemLabel,
          dimension: form.dataset.dimension,
          decision: "answer",
          note,
        },
        "answer",
      );
    });
  });
}

export async function initGapDecisions(): Promise<void> {
  const config = document.getElementById("gap-decisions-config");
  if (!config) return;
  slug = config.dataset.slug ?? "";
  apiBase = (config.dataset.base ?? "").replace(/\/$/, "");
  if (!slug) return;

  try {
    const res = await fetch(`${apiBase}/api/health`, { cache: "no-store" });
    if (!res.ok) return;
    const health = (await res.json()) as { ok?: boolean; service?: string };
    if (health.ok !== true || health.service !== "sky-local-api") return;
  } catch {
    return; // deploy estático — mantém fallback de copiar comando/prompt
  }

  document
    .querySelectorAll<HTMLElement>("[data-gap-interactive]")
    .forEach((el) => el.removeAttribute("hidden"));
  wireRfCards();
  wireAnswerForms();
}
