export function initThemeToggle() {
  const root = document.documentElement;
  const stored = typeof localStorage !== "undefined" ? localStorage.getItem("sf-theme") : null;
  const theme = stored === "dark" ? "dark" : "light";

  if (theme === "dark") root.setAttribute("data-theme", "dark");
  else root.removeAttribute("data-theme");

  updateThemeMeta(theme);
  updateLabel(theme);

  const btn = document.getElementById("theme-toggle");
  if (!btn || btn.dataset.bound === "true") return;
  btn.dataset.bound = "true";

  btn.addEventListener("click", () => {
    const isDark = root.getAttribute("data-theme") === "dark";
    const next = isDark ? "light" : "dark";
    if (next === "dark") root.setAttribute("data-theme", "dark");
    else root.removeAttribute("data-theme");
    localStorage.setItem("sf-theme", next);
    updateThemeMeta(next);
    updateLabel(next);
  });
}

function updateLabel(theme: string) {
  const label = document.getElementById("theme-toggle-label");
  if (label) label.textContent = theme === "dark" ? "Escuro" : "Claro";
}

function updateThemeMeta(theme: string) {
  const meta = document.querySelector('meta[name="theme-color"]');
  if (meta) meta.setAttribute("content", theme === "dark" ? "#060913" : "#f7f9fc");
}
