/**
 * Modo interativo local — lacunas com lote, sugestões recomendadas e refresh sem reload.
 */

type GapItemState = {
  id: string;
  kind: string;
  label?: string;
  dimension?: string;
  status: string;
  effect?: string | null;
};

type GapState = {
  total_count: number;
  ui_pending_count: number;
  next_action?: string | null;
  items: GapItemState[];
  ai_suggested_rfs?: { id: string; status?: string; effect?: string }[];
};

type DecideResult = {
  ok: boolean;
  error?: string;
  state?: GapState | null;
};

type BatchSelection = {
  itemId: string;
  kind: "gap_answer" | "rf_suggestion";
  decision: string;
  label?: string;
  dimension?: string;
  note?: string;
  answer_source?: string;
};

let apiBase = "";
let slug = "";
const batchSelections = new Map<string, BatchSelection>();

function toast(message: string, tone: "ok" | "error" = "ok"): void {
  const el = document.getElementById("gap-toast");
  if (!el) return;
  el.textContent = message;
  el.dataset.tone = tone;
  el.classList.add("is-visible");
  window.setTimeout(() => el.classList.remove("is-visible"), 4000);
}

async function fetchState(): Promise<GapState | null> {
  try {
    const res = await fetch(`${apiBase}/api/gaps/state?slug=${encodeURIComponent(slug)}`, {
      cache: "no-store",
    });
    if (!res.ok) return null;
    const data = (await res.json()) as GapState & { ok?: boolean };
    return data;
  } catch {
    return null;
  }
}

async function postDecision(body: Record<string, unknown>): Promise<DecideResult> {
  const res = await fetch(`${apiBase}/api/gaps/decide`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ slug, ...body }),
  });
  const data = (await res.json().catch(() => ({}))) as DecideResult;
  if (!res.ok || !data.ok) throw new Error(data.error ?? `falha (HTTP ${res.status})`);
  return data;
}

async function postBatch(decisions: BatchSelection[], dryRun = false): Promise<DecideResult> {
  const res = await fetch(`${apiBase}/api/gaps/decide-batch`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ slug, dry_run: dryRun, decisions }),
  });
  const data = (await res.json().catch(() => ({}))) as DecideResult & {
    errors?: { item_id: string; error: string }[];
  };
  if (!res.ok || !data.ok) {
    const detail = data.errors?.map((e) => e.error).join("; ");
    throw new Error(detail ?? data.error ?? `falha no lote (HTTP ${res.status})`);
  }
  return data;
}

function updateBatchBar(): void {
  const bar = document.getElementById("gap-batch-bar");
  const countEl = document.getElementById("gap-batch-count");
  const submitBtn = document.getElementById("gap-batch-submit") as HTMLButtonElement | null;
  const n = batchSelections.size;
  if (!bar || !countEl || !submitBtn) return;
  if (n > 0) {
    bar.removeAttribute("hidden");
    countEl.textContent = `${n} seleção${n !== 1 ? "ões" : ""}`;
    submitBtn.textContent = `Enviar seleções (${n})`;
  } else {
    bar.setAttribute("hidden", "");
  }
}

function syncCounts(state: GapState): void {
  const count = state.ui_pending_count ?? state.total_count;
  document.querySelectorAll("[data-gap-count]").forEach((el) => {
    el.textContent = String(count);
  });
  document.querySelectorAll(".gaps-kicker").forEach((el) => {
    el.textContent = `PRÓXIMA LACUNA · ${count} pendente${count !== 1 ? "s" : ""}`;
  });
  if (state.next_action) {
    document.querySelectorAll(".gaps-lead").forEach((el) => {
      el.textContent = state.next_action!;
    });
  }
}

const STATUS_LABELS: Record<string, string> = {
  accepted: "Aceito por você",
  rejected: "Recusado",
  skipped: "Guardado para depois",
  answered: "Resposta registrada",
};

function applyItemState(item: GapItemState): void {
  const el = document.querySelector<HTMLElement>(`[data-gap-item-id="${item.id}"]`);
  if (!el || item.status === "pending") return;

  el.dataset.gapStatus = item.status;
  el.classList.add("gap-item-decided");

  const form = el.querySelector<HTMLElement>("[data-gap-answer], [data-gap-actions]");
  if (form) {
    form.innerHTML = `<p class="gap-decided-note" role="status">${STATUS_LABELS[item.status] ?? "Decisão registrada"}.</p>`;
  }

  if (item.kind === "rf_suggestion") {
    const card = el.closest(".requirement-card");
    if (!card) return;
    card.dataset.rfStatus = item.status === "accepted" ? "accepted" : item.status === "rejected" ? "rejected" : item.status;
    const head = card.querySelector(".requirement-card-head");
    if (head && item.status === "accepted") {
      head.querySelector(".chip-gap-ai_suggested")?.remove();
      if (!head.querySelector(".chip-gap-accepted")) {
        const chip = document.createElement("span");
        chip.className = "chip chip-gap-accepted";
        chip.textContent = "Aceito por você";
        head.appendChild(chip);
      }
    } else if (head && item.status === "rejected") {
      head.querySelector(".chip-gap-ai_suggested")?.remove();
      if (!head.querySelector(".chip-gap-rejected")) {
        const chip = document.createElement("span");
        chip.className = "chip chip-gap-rejected";
        chip.textContent = "Recusado";
        head.appendChild(chip);
      }
    }
  }

  batchSelections.delete(item.id);
  const cb = el.querySelector<HTMLInputElement>("[data-batch-select]");
  if (cb) cb.checked = false;
}

async function syncFromServer(state?: GapState | null): Promise<void> {
  const s = state ?? (await fetchState());
  if (!s) return;
  syncCounts(s);
  for (const item of s.items) applyItemState(item);
  updateBatchBar();
}

async function submitSingle(body: BatchSelection): Promise<void> {
  try {
    const result = await postDecision(body);
    toast("Decisão gravada na sessão.");
    if (result.state) await syncFromServer(result.state);
    else await syncFromServer();
  } catch (err) {
    toast(err instanceof Error ? err.message : "Não foi possível gravar.", "error");
  }
}

async function submitBatch(): Promise<void> {
  if (batchSelections.size === 0) return;
  const bar = document.getElementById("gap-batch-bar");
  const submitBtn = document.getElementById("gap-batch-submit") as HTMLButtonElement | null;
  if (submitBtn) submitBtn.disabled = true;
  bar?.classList.add("is-busy");

  try {
    const decisions = [...batchSelections.values()];
    const result = await postBatch(decisions);
    toast(`${decisions.length} decisão${decisions.length !== 1 ? "ões" : ""} gravada${decisions.length !== 1 ? "s" : ""}.`);
    batchSelections.clear();
    if (result.state) await syncFromServer(result.state);
    else await syncFromServer();
  } catch (err) {
    toast(err instanceof Error ? err.message : "Falha no envio em lote.", "error");
  } finally {
    if (submitBtn) submitBtn.disabled = false;
    bar?.classList.remove("is-busy");
    updateBatchBar();
  }
}

function registerBatchSelection(sel: BatchSelection): void {
  batchSelections.set(sel.itemId, sel);
  updateBatchBar();
}

function clearBatch(): void {
  batchSelections.clear();
  document.querySelectorAll<HTMLInputElement>("[data-batch-select]:checked").forEach((cb) => {
    cb.checked = false;
  });
  document.querySelectorAll(".gap-suggestion-chip.is-selected").forEach((c) => {
    c.classList.remove("is-selected");
    c.setAttribute("aria-pressed", "false");
  });
  updateBatchBar();
}

function wireSuggestionChips(form: HTMLFormElement): void {
  const textarea = form.querySelector<HTMLTextAreaElement>("textarea");
  const itemId = form.dataset.itemId ?? "";
  const chips = form.querySelectorAll<HTMLButtonElement>("[data-suggestion]");

  chips.forEach((chip) => {
    chip.addEventListener("click", () => {
      if (!textarea) return;
      const text = chip.dataset.suggestionText ?? chip.textContent?.trim() ?? "";
      textarea.value = text;
      form.dataset.suggestionUsed = text;
      chips.forEach((c) => {
        c.setAttribute("aria-pressed", c === chip ? "true" : "false");
        c.classList.toggle("is-selected", c === chip);
      });
      const batchCb = form.closest("[data-gap-item-id]")?.querySelector<HTMLInputElement>("[data-batch-select]");
      if (batchCb) batchCb.checked = true;
      registerBatchSelection({
        itemId,
        kind: "gap_answer",
        decision: "answer",
        label: form.dataset.itemLabel,
        dimension: form.dataset.dimension,
        note: text,
        answer_source: "ai_suggested",
      });
      textarea.focus();
    });
  });

  textarea?.addEventListener("input", () => {
    const note = textarea.value.trim();
    if (!note) {
      batchSelections.delete(itemId);
      updateBatchBar();
      return;
    }
    const batchCb = form.closest("[data-gap-item-id]")?.querySelector<HTMLInputElement>("[data-batch-select]");
    if (batchCb?.checked) {
      registerBatchSelection({
        itemId,
        kind: "gap_answer",
        decision: "answer",
        label: form.dataset.itemLabel,
        dimension: form.dataset.dimension,
        note,
        answer_source: note === form.dataset.suggestionUsed ? "ai_suggested" : "user_text",
      });
    }
  });
}

function wireAnswerForms(): void {
  document.querySelectorAll<HTMLFormElement>("form[data-gap-answer]").forEach((form) => {
    wireSuggestionChips(form);

    form.querySelector<HTMLButtonElement>("[data-send-single]")?.addEventListener("click", () => {
      const textarea = form.querySelector<HTMLTextAreaElement>("textarea");
      const note = textarea?.value.trim() ?? "";
      if (!note) {
        textarea?.focus();
        toast("Escreva ou escolha uma sugestão.", "error");
        return;
      }
      void submitSingle({
        itemId: form.dataset.itemId ?? "",
        kind: "gap_answer",
        decision: "answer",
        label: form.dataset.itemLabel,
        dimension: form.dataset.dimension,
        note,
        answer_source: note === form.dataset.suggestionUsed ? "ai_suggested" : "user_text",
      });
    });

    const batchCb = form.closest("[data-gap-item-id]")?.querySelector<HTMLInputElement>("[data-batch-select]");
    batchCb?.addEventListener("change", () => {
      const itemId = form.dataset.itemId ?? "";
      if (!batchCb.checked) {
        batchSelections.delete(itemId);
        updateBatchBar();
        return;
      }
      const textarea = form.querySelector<HTMLTextAreaElement>("textarea");
      const note = textarea?.value.trim() ?? "";
      if (!note) {
        batchCb.checked = false;
        toast("Escolha uma sugestão ou escreva antes de marcar.", "error");
        return;
      }
      registerBatchSelection({
        itemId,
        kind: "gap_answer",
        decision: "answer",
        label: form.dataset.itemLabel,
        dimension: form.dataset.dimension,
        note,
        answer_source: note === form.dataset.suggestionUsed ? "ai_suggested" : "user_text",
      });
    });
  });
}

function wireRfCards(): void {
  document.querySelectorAll<HTMLElement>("[data-gap-actions]").forEach((actions) => {
    const itemId = actions.dataset.itemId ?? "";
    const label = actions.dataset.itemLabel ?? "";

    actions.querySelectorAll<HTMLButtonElement>("[data-decide]").forEach((btn) => {
      btn.addEventListener("click", () => {
        void submitSingle({
          itemId,
          kind: "rf_suggestion",
          decision: btn.dataset.decide ?? "",
          label,
        });
      });
    });

    actions.querySelectorAll<HTMLInputElement>("[data-rf-batch]").forEach((radio) => {
      radio.addEventListener("change", () => {
        const batchCb = actions.closest("[data-gap-item-id]")?.querySelector<HTMLInputElement>("[data-batch-select]");
        if (batchCb?.checked && radio.checked) {
          registerBatchSelection({
            itemId,
            kind: "rf_suggestion",
            decision: radio.value,
            label,
          });
        }
      });
    });

    const batchCb = actions.closest("[data-gap-item-id]")?.querySelector<HTMLInputElement>("[data-batch-select]");
    batchCb?.addEventListener("change", () => {
      if (!batchCb.checked) {
        batchSelections.delete(itemId);
        updateBatchBar();
        return;
      }
      const selected = actions.querySelector<HTMLInputElement>("[data-rf-batch]:checked");
      if (!selected) {
        batchCb.checked = false;
        toast("Escolha Aceitar, Recusar ou Decidir depois.", "error");
        return;
      }
      registerBatchSelection({
        itemId,
        kind: "rf_suggestion",
        decision: selected.value,
        label,
      });
    });
  });
}

function wireBatchBar(): void {
  document.getElementById("gap-batch-submit")?.addEventListener("click", () => void submitBatch());
  document.getElementById("gap-batch-clear")?.addEventListener("click", clearBatch);
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
    return;
  }

  document.querySelectorAll<HTMLElement>("[data-gap-interactive]").forEach((el) => el.removeAttribute("hidden"));
  document.querySelectorAll<HTMLElement>("[data-gap-static]").forEach((el) => el.setAttribute("hidden", ""));
  wireRfCards();
  wireAnswerForms();
  wireBatchBar();
  await syncFromServer();
}
