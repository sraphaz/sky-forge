export function initThemeToggle() {
  const root = document.documentElement;
  const stored = typeof localStorage !== "undefined" ? localStorage.getItem("sf-theme") : null;
  const theme = stored === "light" ? "light" : "dark";

  if (theme === "light") root.setAttribute("data-theme", "light");
  else root.removeAttribute("data-theme");

  updateThemeMeta(theme);
  updateLabel(theme);

  const btn = document.getElementById("theme-toggle");
  if (!btn || btn.dataset.bound === "true") return;
  btn.dataset.bound = "true";

  btn.addEventListener("click", () => {
    const isLight = root.getAttribute("data-theme") === "light";
    const next = isLight ? "dark" : "light";
    if (next === "light") root.setAttribute("data-theme", "light");
    else root.removeAttribute("data-theme");
    localStorage.setItem("sf-theme", next);
    updateThemeMeta(next);
    updateLabel(next);
  });
}

function updateLabel(theme: string) {
  const label = document.getElementById("theme-toggle-label");
  if (label) label.textContent = theme === "light" ? "Claro" : "Escuro";
}

function updateThemeMeta(theme: string) {
  const meta = document.querySelector('meta[name="theme-color"]');
  if (meta) meta.setAttribute("content", theme === "light" ? "#F4F7FD" : "#060913");
}
