/**
 * sky-local-api — modo interativo local do showcase.
 *
 * Integração Astro que registra endpoints de escrita SOMENTE no dev server
 * (`astro dev` / `sky.ps1 showcase`). O build estático (GitHub Pages) não é
 * afetado: nenhum adapter, nenhuma rota server-side no output.
 *
 * Endpoints (sob o `base` do site, ex.: /sky-forge/api/...):
 *   GET  /api/health       → { ok: true } — sonda de capacidade usada pela UI
 *   POST /api/gaps/decide  → { slug, item_id, decision, note?, dry_run? }
 *
 * Decisões:
 *   confirm | reject  → RFs ai_suggested: user_confirmed: true|false em
 *                       .sky/sessions/{slug}/functional-requirements.yaml
 *   skip              → registra em decisions-inbox.yaml, sem alterar RFs
 *   answer            → resposta livre a uma lacuna aberta (note obrigatória),
 *                       registrada em decisions-inbox.yaml para o intake
 *
 * Toda decisão: auditoria via record-agent-event.ps1 e regeneração do preview
 * via publish-preview.ps1 (a UI recarrega e reflete o novo estado).
 */
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const execFileAsync = promisify(execFile);

const REPO_ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..", "..", "..");
const SESSIONS_DIR = path.join(REPO_ROOT, ".sky", "sessions");
const SCRIPTS_DIR = path.join(REPO_ROOT, "scripts", "sky");

/**
 * publish-preview.ps1 prefere o pacote exportado (outputs/{slug}) à sessão;
 * decisões precisam ser espelhadas nos dois para o preview refletir o estado.
 */
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
    /* config ausente — usa default */
  }
  return path.isAbsolute(dir) ? dir : path.join(REPO_ROOT, dir);
}

const SLUG_RE = /^[a-z0-9][a-z0-9-]{0,63}$/;
const ITEM_ID_RE = /^[A-Za-z0-9._-]{1,64}$/;
const RF_ID_RE = /^RF-\d{3}$/;
const DECISIONS = new Set(["confirm", "reject", "skip", "answer"]);

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
      if (size > 64 * 1024) {
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

/**
 * Define user_confirmed dentro do bloco do RF preservando comentários,
 * ordem e line endings do YAML (edição textual dirigida, sem re-serializar).
 */
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
  lines.push(`    source: showcase-local`);

  if (!fs.existsSync(inboxPath)) {
    const header = [
      "# Decisões tomadas no showcase local — consumir no próximo intake",
      "# (intake-conductor aplica em maturity/brief e remove entradas processadas).",
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

async function runPowerShell(scriptPath, args) {
  await execFileAsync(
    "powershell.exe",
    ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", scriptPath, ...args],
    { cwd: REPO_ROOT, timeout: 120_000, windowsHide: true },
  );
}

async function recordAudit(slug, itemId, decision, dryRun) {
  const script = path.join(SCRIPTS_DIR, "record-agent-event.ps1");
  if (!fs.existsSync(script)) return false;
  try {
    await runPowerShell(script, [
      "-Slug", slug,
      "-AgentId", "sky-host",
      "-Action", "gap.decide",
      "-Outcome", "ok",
      "-AutonomyLevel", "activate",
      "-Details", `${itemId} ${decision} via showcase local${dryRun ? " (dry_run)" : ""}`,
    ]);
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

async function handleDecide(req, res) {
  let payload;
  try {
    payload = JSON.parse((await readBody(req)) || "{}");
  } catch {
    return sendJson(res, 400, { ok: false, error: "JSON inválido" });
  }

  const slug = String(payload.slug ?? "");
  const itemId = String(payload.item_id ?? "");
  const decision = String(payload.decision ?? "");
  const note = typeof payload.note === "string" ? payload.note.slice(0, 4000).trim() : "";
  const label = typeof payload.label === "string" ? payload.label.slice(0, 300).trim() : "";
  const dimension = typeof payload.dimension === "string" ? payload.dimension.slice(0, 40).trim() : "";
  const dryRun = payload.dry_run === true;

  if (!SLUG_RE.test(slug)) return sendJson(res, 400, { ok: false, error: "slug inválido" });
  if (!ITEM_ID_RE.test(itemId)) return sendJson(res, 400, { ok: false, error: "item_id inválido" });
  if (!DECISIONS.has(decision)) {
    return sendJson(res, 400, { ok: false, error: "decision deve ser confirm|reject|skip|answer" });
  }
  if (decision === "answer" && !note) {
    return sendJson(res, 400, { ok: false, error: "answer requer note com a resposta" });
  }

  const sessionDir = path.join(SESSIONS_DIR, slug);
  if (!fs.existsSync(sessionDir)) {
    return sendJson(res, 404, { ok: false, error: `sessão não encontrada: ${slug}` });
  }

  const isRf = RF_ID_RE.test(itemId);
  const changes = { functional_requirements: false, exported_package: false, decisions_inbox: false };

  // confirm/reject de RF sugerido → user_confirmed no YAML da sessão
  // e no pacote exportado (se existir), que é o que o preview publica
  if (isRf && (decision === "confirm" || decision === "reject")) {
    const value = decision === "confirm" ? "true" : "false";
    const sessionRfPath = path.join(sessionDir, "functional-requirements.yaml");
    if (!fs.existsSync(sessionRfPath)) {
      return sendJson(res, 404, { ok: false, error: "functional-requirements.yaml não encontrado" });
    }
    const original = fs.readFileSync(sessionRfPath, "utf8");
    const updated = setUserConfirmed(original, itemId, value);
    if (updated == null) {
      return sendJson(res, 404, { ok: false, error: `${itemId} não encontrado na sessão` });
    }
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

  // Toda decisão vai para o inbox — trilha p/ intake-conductor
  if (!dryRun) {
    appendToDecisionsInbox(sessionDir, slug, {
      at: new Date().toISOString(),
      item_id: itemId,
      kind: isRf ? "rf_suggestion" : "gap_answer",
      decision,
      dimension,
      label,
      note,
    });
    changes.decisions_inbox = true;
  }

  const audited = dryRun ? false : await recordAudit(slug, itemId, decision, dryRun);
  const previewRefreshed = dryRun ? false : await refreshPreview(slug);

  return sendJson(res, 200, {
    ok: true,
    dry_run: dryRun,
    slug,
    item_id: itemId,
    decision,
    changes,
    audited,
    preview_refreshed: previewRefreshed,
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
          let url = (req.url ?? "").split("?")[0];
          const prefix = base.replace(/\/$/, "");
          if (prefix && url.startsWith(prefix)) url = url.slice(prefix.length);

          if (url === "/api/health") {
            if (req.method !== "GET") return sendJson(res, 405, { ok: false });
            return sendJson(res, 200, { ok: true, service: "sky-local-api", writable: true });
          }
          if (url === "/api/gaps/decide") {
            if (req.method !== "POST") return sendJson(res, 405, { ok: false, error: "use POST" });
            handleDecide(req, res).catch((err) =>
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
