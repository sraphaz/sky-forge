/**
 * sky-local-api — modo interativo local do showcase.
 *
 * Endpoints (dev server only, sob base /sky-forge):
 *   GET  /api/health
 *   GET  /api/gaps/state?slug=
 *   POST /api/gaps/decide
 *   POST /api/gaps/decide-batch
 */
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const execFileAsync = promisify(execFile);

const REPO_ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..", "..", "..");
const SESSIONS_DIR = path.join(REPO_ROOT, ".sky", "sessions");
const REGISTRY_DIR = path.join(REPO_ROOT, "showcase", "registry");
const SCRIPTS_DIR = path.join(REPO_ROOT, "scripts", "sky");

const SLUG_RE = /^[a-z0-9][a-z0-9-]{0,63}$/;
const ITEM_ID_RE = /^[A-Za-z0-9._-]{1,64}$/;
const RF_ID_RE = /^RF-\d{3}$/;
const DECISIONS = new Set(["confirm", "reject", "skip", "answer"]);

function getOutputsDir() {
  if (process.env.SKY_OUTPUTS_DIR) {
    return path.isAbsolute(process.env.SKY_OUTPUTS_DIR)
      ? process.env.SKY_OUTPUTS_DIR
      : path.join(REPO_ROOT, process.env.SKY_OUTPUTS_DIR);
  }
  let dir = "outputs";
  try {
    const raw = fs.readFileSync(path.join(REPO_ROOT, "sky.config.yaml"), "utf8");
    const m = raw.match(/^outputs:\s*\r?\n(?:[^\r\n]+\r?\n)*?\s+dir:\s*(.+)$/m);
    if (m) dir = m[1].trim().replace(/^["']|["']$/g, "");
  } catch {
    /* default */
  }
  return path.isAbsolute(dir) ? dir : path.join(REPO_ROOT, dir);
}

function sendJson(res, status, body) {
  res.statusCode = status;
  res.setHeader("Content-Type", "application/json; charset=utf-8");
  res.setHeader("Cache-Control", "no-store");
  res.end(JSON.stringify(body));
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    let size = 0;
    req.on("data", (chunk) => {
      size += chunk.length;
      if (size > 256 * 1024) {
        reject(new Error("body too large"));
        req.destroy();
        return;
      }
      chunks.push(chunk);
    });
    req.on("end", () => resolve(Buffer.concat(chunks).toString("utf8")));
    req.on("error", reject);
  });
}

function detectEol(text) {
  return text.includes("\r\n") ? "\r\n" : "\n";
}

function setUserConfirmed(yamlText, rfId, value) {
  const eol = detectEol(yamlText);
  const lines = yamlText.split(/\r?\n/);
  const startRe = new RegExp(`^\\s*- id:\\s*${rfId}\\s*$`);
  const start = lines.findIndex((l) => startRe.test(l));
  if (start === -1) return null;

  let end = lines.length;
  for (let i = start + 1; i < lines.length; i++) {
    if (/^\s*- id:\s/.test(lines[i]) || /^\S/.test(lines[i])) {
      end = i;
      break;
    }
  }

  let replaced = false;
  for (let i = start + 1; i < end; i++) {
    if (/^\s+user_confirmed:/.test(lines[i])) {
      const indent = lines[i].match(/^\s+/)[0];
      lines[i] = `${indent}user_confirmed: ${value}`;
      replaced = true;
      break;
    }
  }
  if (!replaced) {
    const idIndent = lines[start].match(/^(\s*)-/)[1];
    lines.splice(start + 1, 0, `${idIndent}  user_confirmed: ${value}`);
  }
  return lines.join(eol);
}

function yamlQuote(text) {
  return `"${String(text).replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/\r?\n/g, " ")}"`;
}

function appendToDecisionsInbox(sessionDir, slug, entry) {
  const inboxPath = path.join(sessionDir, "decisions-inbox.yaml");
  const eol = "\n";
  const lines = [
    `  - at: ${yamlQuote(entry.at)}`,
    `    item_id: ${yamlQuote(entry.item_id)}`,
    `    kind: ${entry.kind}`,
    `    decision: ${entry.decision}`,
  ];
  if (entry.dimension) lines.push(`    dimension: ${entry.dimension}`);
  if (entry.label) lines.push(`    label: ${yamlQuote(entry.label)}`);
  if (entry.note) lines.push(`    note: ${yamlQuote(entry.note)}`);
  if (entry.answer_source) lines.push(`    answer_source: ${entry.answer_source}`);
  lines.push(`    source: showcase-local`);

  if (!fs.existsSync(inboxPath)) {
    const header = [
      "# Decisões tomadas no showcase local — consumir no próximo intake",
      'version: "1.0"',
      `slug: ${slug}`,
      "decisions:",
      "",
    ].join(eol);
    fs.writeFileSync(inboxPath, header, "utf8");
  }
  fs.appendFileSync(inboxPath, lines.join(eol) + eol, "utf8");
  return inboxPath;
}

function readDecisionsInbox(sessionDir) {
  const inboxPath = path.join(sessionDir, "decisions-inbox.yaml");
  if (!fs.existsSync(inboxPath)) return [];
  const raw = fs.readFileSync(inboxPath, "utf8");
  const entries = [];
  const blocks = raw.split(/\r?\n(?=  - at:)/);
  for (const block of blocks) {
    const itemM = block.match(/item_id:\s*"([^"]+)"/);
    const decisionM = block.match(/decision:\s*(\w+)/);
    if (itemM && decisionM) {
      entries.push({ item_id: itemM[1], decision: decisionM[1] });
    }
  }
  return entries;
}

function readPreview(slug) {
  const previewPath = path.join(REGISTRY_DIR, `${slug}.preview.json`);
  if (!fs.existsSync(previewPath)) return null;
  const raw = fs.readFileSync(previewPath, "utf8").replace(/^\uFEFF/, "");
  return JSON.parse(raw);
}

/** Normaliza path da requisição (base /sky-forge, trailing slash). */
function normalizeApiPath(fullUrl, base) {
  let url = (fullUrl ?? "").split("?")[0];
  const prefix = (base ?? "/").replace(/\/$/, "");
  if (prefix && (url === prefix || url.startsWith(`${prefix}/`))) {
    url = url.slice(prefix.length) || "/";
  }
  if (!url.startsWith("/")) url = `/${url}`;
  return url.replace(/\/+$/, "") || "/";
}

async function runPowerShell(scriptPath, args) {
  await execFileAsync(
    "powershell.exe",
    ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", scriptPath, ...args],
    { cwd: REPO_ROOT, timeout: 120_000, windowsHide: true },
  );
}

async function recordAudit(slug, itemId, decision, dryRun, extra = "") {
  const script = path.join(SCRIPTS_DIR, "record-agent-event.ps1");
  if (!fs.existsSync(script) || dryRun) return false;
  try {
    await runPowerShell(script, [
      "-Slug", slug,
      "-AgentId", "sky-host",
      "-Action", "gap.decide",
      "-Outcome", "ok",
      "-AutonomyLevel", "activate",
      "-Details", `${itemId} ${decision}${extra} via showcase local`,
    ]);
    return true;
  } catch {
    return false;
  }
}

async function syncShowcase(slug, opts = {}) {
  const script = path.join(SCRIPTS_DIR, "sync-showcase.ps1");
  if (!fs.existsSync(script)) return refreshPreview(slug);
  const args = ["-Slug", slug];
  if (opts.public === true) args.push("-Public");
  if (opts.noPublic === true) args.push("-NoPublic");
  if (opts.skipExport === true) args.push("-SkipExport");
  if (opts.skipZip === true) args.push("-SkipZip");
  try {
    await runPowerShell(script, args);
    return true;
  } catch {
    return false;
  }
}

async function refreshPreview(slug) {
  const script = path.join(SCRIPTS_DIR, "publish-preview.ps1");
  if (!fs.existsSync(script)) return false;
  try {
    await runPowerShell(script, ["-Slug", slug]);
    return true;
  } catch {
    return false;
  }
}

function buildGapsState(slug) {
  const preview = readPreview(slug);
  const sessionDir = path.join(SESSIONS_DIR, slug);
  const inbox = readDecisionsInbox(sessionDir);
  const inboxById = new Map(inbox.map((e) => [e.item_id, e]));

  const gaps = preview?.gaps ?? {};
  const totalCount = gaps.total_count ?? 0;
  const items = [];

  if (gaps.ai_suggested_rfs) {
    for (const rf of gaps.ai_suggested_rfs) {
      const inboxEntry = inboxById.get(rf.id);
      let status = rf.status ?? "pending";
      if (inboxEntry?.decision === "confirm") status = "accepted";
      else if (inboxEntry?.decision === "reject") status = "rejected";
      else if (inboxEntry?.decision === "skip") status = "skipped";
      items.push({
        id: rf.id,
        kind: "rf_suggestion",
        label: rf.title,
        status,
        effect: rf.effect ?? null,
      });
    }
  }

  const dimGaps = gaps.dimension_gaps ?? preview?.dimension_gaps ?? {};
  for (const [dim, list] of Object.entries(dimGaps)) {
    list.forEach((label, idx) => {
      const id = `dim-${dim}-${idx + 1}`;
      const inboxEntry = inboxById.get(id);
      const status = inboxEntry?.decision === "answer" ? "answered" : "pending";
      items.push({ id, kind: "gap_answer", label, dimension: dim, status });
    });
  }

  const answeredCount = items.filter((i) =>
    i.status === "answered" || i.status === "accepted" || i.status === "rejected" || i.status === "skipped",
  ).length;
  const uiPendingCount = items.filter((i) => i.status === "pending").length;

  return {
    slug,
    total_count: totalCount,
    ui_pending_count: uiPendingCount,
    answered_count: answeredCount,
    next_action: gaps.next_action ?? null,
    top: gaps.top ?? [],
    ai_suggested_rfs: gaps.ai_suggested_rfs ?? [],
    items,
  };
}

async function processDecision(slug, payload, opts = {}) {
  const { dryRun = false, skipAudit = false } = opts;
  const itemId = String(payload.item_id ?? "");
  const decision = String(payload.decision ?? "");
  const note = typeof payload.note === "string" ? payload.note.slice(0, 4000).trim() : "";
  const answerSource = payload.answer_source === "ai_suggested" ? "ai_suggested" : "user_text";
  const label = typeof payload.label === "string" ? payload.label.slice(0, 300).trim() : "";
  const dimension = typeof payload.dimension === "string" ? payload.dimension.slice(0, 40).trim() : "";

  if (!SLUG_RE.test(slug)) throw new Error("slug inválido");
  if (!ITEM_ID_RE.test(itemId)) throw new Error("item_id inválido");
  if (!DECISIONS.has(decision)) throw new Error("decision inválida");
  if (decision === "answer" && !note) throw new Error("answer requer note");

  const sessionDir = path.join(SESSIONS_DIR, slug);
  if (!fs.existsSync(sessionDir)) throw new Error(`sessão não encontrada: ${slug}`);

  const isRf = RF_ID_RE.test(itemId);
  const changes = { functional_requirements: false, exported_package: false, decisions_inbox: false };

  if (isRf && (decision === "confirm" || decision === "reject")) {
    const value = decision === "confirm" ? "true" : "false";
    const sessionRfPath = path.join(sessionDir, "functional-requirements.yaml");
    if (!fs.existsSync(sessionRfPath)) throw new Error("functional-requirements.yaml não encontrado");
    const original = fs.readFileSync(sessionRfPath, "utf8");
    const updated = setUserConfirmed(original, itemId, value);
    if (updated == null) throw new Error(`${itemId} não encontrado na sessão`);
    if (!dryRun && updated !== original) {
      fs.writeFileSync(sessionRfPath, updated, "utf8");
      changes.functional_requirements = true;
    }
    if (dryRun) changes.functional_requirements = updated !== original;

    const packageRfPath = path.join(getOutputsDir(), slug, "functional-requirements.yaml");
    if (fs.existsSync(packageRfPath)) {
      const pkgOriginal = fs.readFileSync(packageRfPath, "utf8");
      const pkgUpdated = setUserConfirmed(pkgOriginal, itemId, value);
      if (pkgUpdated != null && pkgUpdated !== pkgOriginal) {
        if (!dryRun) fs.writeFileSync(packageRfPath, pkgUpdated, "utf8");
        changes.exported_package = true;
      }
    }
  }

  if (!dryRun) {
    appendToDecisionsInbox(sessionDir, slug, {
      at: new Date().toISOString(),
      item_id: itemId,
      kind: isRf ? "rf_suggestion" : "gap_answer",
      decision,
      dimension,
      label,
      note,
      answer_source: decision === "answer" ? answerSource : "",
    });
    changes.decisions_inbox = true;
  }

  const auditExtra = decision === "answer" ? ` (${answerSource})` : "";
  const audited = !skipAudit && !dryRun && (await recordAudit(slug, itemId, decision, dryRun, auditExtra));

  return { item_id: itemId, decision, changes, audited };
}

async function handleDecide(req, res, preParsed) {
  let payload = preParsed;
  if (!payload) {
    try {
      payload = JSON.parse((await readBody(req)) || "{}");
    } catch {
      return sendJson(res, 400, { ok: false, error: "JSON inválido" });
    }
  }

  if (Array.isArray(payload.decisions)) {
    return handleDecideBatch(req, res, payload);
  }

  const slug = String(payload.slug ?? "");
  const dryRun = payload.dry_run === true;

  try {
    const result = await processDecision(slug, payload, { dryRun });
    let previewRefreshed = false;
    let state = null;
    if (!dryRun) {
      previewRefreshed = await syncShowcase(slug);
      state = buildGapsState(slug);
    }
    return sendJson(res, 200, { ok: true, dry_run: dryRun, slug, ...result, preview_refreshed: previewRefreshed, showcase_synced: previewRefreshed, state });
  } catch (err) {
    return sendJson(res, 400, { ok: false, error: String(err?.message ?? err) });
  }
}

async function handleProjectRefresh(req, res) {
  let payload;
  try {
    payload = JSON.parse((await readBody(req)) || "{}");
  } catch {
    return sendJson(res, 400, { ok: false, error: "JSON inválido" });
  }
  const slug = String(payload.slug ?? "");
  if (!SLUG_RE.test(slug)) return sendJson(res, 400, { ok: false, error: "slug inválido" });
  const sessionDir = path.join(SESSIONS_DIR, slug);
  if (!fs.existsSync(sessionDir)) return sendJson(res, 404, { ok: false, error: "sessão não encontrada" });

  const refreshed = await syncShowcase(slug);
  const state = buildGapsState(slug);
  return sendJson(res, 200, {
    ok: true,
    slug,
    preview_refreshed: refreshed,
    showcase_synced: refreshed,
    state,
    message: "Export, preview, ZIP e registry atualizados a partir da sessão.",
  });
}

async function handleDecideBatch(req, res, preParsed) {
  let payload = preParsed;
  if (!payload) {
    try {
      payload = JSON.parse((await readBody(req)) || "{}");
    } catch {
      return sendJson(res, 400, { ok: false, error: "JSON inválido" });
    }
  }

  const slug = String(payload.slug ?? "");
  const dryRun = payload.dry_run === true;
  const decisions = Array.isArray(payload.decisions) ? payload.decisions : [];

  if (!SLUG_RE.test(slug)) return sendJson(res, 400, { ok: false, error: "slug inválido" });
  if (decisions.length === 0) return sendJson(res, 400, { ok: false, error: "decisions vazio" });
  if (decisions.length > 20) return sendJson(res, 400, { ok: false, error: "máximo 20 decisões por lote" });

  const results = [];
  const errors = [];

  for (const d of decisions) {
    try {
      const result = await processDecision(slug, d, { dryRun, skipAudit: true });
      results.push(result);
    } catch (err) {
      errors.push({ item_id: d.item_id, error: String(err?.message ?? err) });
    }
  }

  if (!dryRun && results.length > 0) {
    await syncShowcase(slug);
    for (const r of results) {
      await recordAudit(slug, r.item_id, r.decision, false, r.decision === "answer" ? "" : "");
    }
  }

  const state = dryRun ? null : buildGapsState(slug);
  return sendJson(res, 200, {
    ok: errors.length === 0,
    dry_run: dryRun,
    slug,
    results,
    errors,
    preview_refreshed: !dryRun && results.length > 0,
    state,
  });
}

export default function skyLocalApi() {
  let base = "/";
  return {
    name: "sky-local-api",
    hooks: {
      "astro:config:done": ({ config }) => {
        base = config.base ?? "/";
      },
      "astro:server:setup": ({ server }) => {
        server.middlewares.use((req, res, next) => {
          const fullUrl = req.url ?? "";
          const url = normalizeApiPath(fullUrl, base);

          if (url === "/api/health") {
            if (req.method !== "GET") return sendJson(res, 405, { ok: false });
            return sendJson(res, 200, {
              ok: true,
              service: "sky-local-api",
              writable: true,
              version: "1.8",
              capabilities: ["health", "gaps-state", "gaps-decide", "gaps-decide-batch", "project-refresh", "showcase-sync"],
            });
          }
          if (url === "/api/gaps/state") {
            if (req.method !== "GET") return sendJson(res, 405, { ok: false, error: "use GET" });
            const qIdx = fullUrl.indexOf("?");
            const params = new URLSearchParams(qIdx >= 0 ? fullUrl.slice(qIdx) : "");
            const stateSlug = params.get("slug") ?? "";
            if (!SLUG_RE.test(stateSlug)) return sendJson(res, 400, { ok: false, error: "slug inválido" });
            const sessionDir = path.join(SESSIONS_DIR, stateSlug);
            if (!fs.existsSync(sessionDir)) return sendJson(res, 404, { ok: false, error: "sessão não encontrada" });
            return sendJson(res, 200, { ok: true, ...buildGapsState(stateSlug) });
          }
          if (url === "/api/gaps/decide") {
            if (req.method !== "POST") return sendJson(res, 405, { ok: false, error: "use POST" });
            handleDecide(req, res).catch((err) =>
              sendJson(res, 500, { ok: false, error: String(err?.message ?? err) }),
            );
            return;
          }
          if (url === "/api/gaps/decide-batch") {
            if (req.method !== "POST") return sendJson(res, 405, { ok: false, error: "use POST" });
            handleDecideBatch(req, res).catch((err) =>
              sendJson(res, 500, { ok: false, error: String(err?.message ?? err) }),
            );
            return;
          }
          if (url === "/api/project/refresh") {
            if (req.method !== "POST") return sendJson(res, 405, { ok: false, error: "use POST" });
            handleProjectRefresh(req, res).catch((err) =>
              sendJson(res, 500, { ok: false, error: String(err?.message ?? err) }),
            );
            return;
          }
          next();
        });
      },
    },
  };
}
